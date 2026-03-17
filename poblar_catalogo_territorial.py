"""
AGROPLATAFORMA DIGITAL - POBLADOR DEL CATALOGO TERRITORIAL
PEE-2025-G-369 | TecNM Ciudad Valles

Puebla las tablas del esquema catalogo.* con datos oficiales de INEGI:
    - catalogo.localidad  <- ITER Censo 2020 + shapefile localidades
    - catalogo.colonia    <- API asentamientos gaia.inegi.org.mx

Fuentes:
    - ITER 2020: iter_24_cpv2020_csv.zip (San Luis Potosi)
      URL: https://www.inegi.org.mx/contenidos/programas/ccpv/2020/
           datosabiertos/iter/iter_24_cpv2020_csv.zip
    - Shapefile localidades: capas_sig/localidades_huasteca/
      (generado por descargar_inegi.py)
    - API asentamientos: gaia.inegi.org.mx/wscatgeo/v2/asentamientos/{ent}/{mun}

Uso:
    pip install requests pandas geopandas psycopg2-binary
    python poblar_catalogo_territorial.py

    # Solo localidades (sin colonias):
    python poblar_catalogo_territorial.py --solo-localidades

    # Solo colonias de un municipio:
    python poblar_catalogo_territorial.py --solo-colonias --municipio 013
"""

import os
import time
import logging
import argparse
import requests
import pandas as pd
import geopandas as gpd
from pathlib import Path
from zipfile import ZipFile
from io import BytesIO

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("catalogo_territorial.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# API REST INEGI
BASE_API   = "https://gaia.inegi.org.mx/wscatgeo/v2"
HEADERS    = {"User-Agent": "AgroplataformaBot/1.0 (TecNM; PEE-2025-G-369)"}

# ITER 2020 San Luis Potosi (clave 24)
ITER_URL   = ("https://www.inegi.org.mx/contenidos/programas/ccpv/2020/"
              "datosabiertos/iter/iter_24_cpv2020_csv.zip")
ITER_LOCAL = Path("./iter_24_cpv2020_csv.zip")

# Shapefile de localidades ya descargado por descargar_inegi.py
SHP_LOCALIDADES = Path("./capas_sig/localidades_huasteca/localidades_huasteca.shp")

# Claves INEGI de los 20 municipios de la Huasteca Potosina
MUNICIPIOS_HUASTECA = {
    "003": "Aquismón",
    "004": "Axtla de Terrazas",
    "013": "Ciudad Valles",
    "017": "Coxcatlán",
    "019": "Ébano",
    "021": "El Naranjo",
    "025": "Huehuetlán",
    "030": "Matlapa",
    "039": "San Antonio",
    "043": "San Martín Chalchicuautla",
    "045": "San Vicente Tancuayalab",
    "049": "Tamasopo",
    "050": "Tamazunchale",
    "051": "Tampacán",
    "052": "Tampamolón Corona",
    "054": "Tamuín",
    "055": "Tancanhuitz de Santos",
    "056": "Tanlajás",
    "057": "Tanquián de Escobedo",
    "058": "Xilitla",
}


# ============================================================
# CONEXION A BD
# ============================================================

def get_conn():
    import psycopg2
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "agroplataforma"),
        user=os.getenv("DB_USER", "agro_admin"),
        password=os.getenv("DB_PASSWORD", "huasteca2025"),
    )


# ============================================================
# PASO 1: DESCARGAR ITER 2020 SI NO EXISTE
# ============================================================

def descargar_iter():
    if ITER_LOCAL.exists():
        logger.info(f"ITER ya descargado: {ITER_LOCAL}")
        return True
    logger.info(f"Descargando ITER 2020 SLP: {ITER_URL}")
    try:
        resp = requests.get(ITER_URL, stream=True, timeout=120, headers=HEADERS)
        resp.raise_for_status()
        total = int(resp.headers.get("content-length", 0))
        descargado = 0
        with open(ITER_LOCAL, "wb") as f:
            for chunk in resp.iter_content(chunk_size=8192):
                f.write(chunk)
                descargado += len(chunk)
                if total:
                    print(f"\r  {descargado/1024/1024:.1f} MB / {total/1024/1024:.1f} MB", end="")
        print()
        logger.info(f"[OK] ITER descargado: {ITER_LOCAL}")
        return True
    except Exception as e:
        logger.error(f"[ERROR] No se pudo descargar ITER: {e}")
        return False


def leer_iter() -> pd.DataFrame | None:
    """Lee el CSV del ITER filtrado a los 20 municipios de la Huasteca."""
    try:
        with ZipFile(ITER_LOCAL) as z:
            csvs = [f for f in z.namelist() if f.endswith(".csv")
                    and "conjunto_de_datos" in f]
            if not csvs:
                logger.error("[ERROR] CSV no encontrado en el ZIP del ITER")
                return None
            with z.open(csvs[0]) as f:
                df = pd.read_csv(f, dtype=str, encoding="utf-8",
                                 low_memory=False)

        # Normalizar nombres de columnas a mayusculas
        df.columns = df.columns.str.upper().str.strip()

        # Filtrar solo San Luis Potosi (24) y los 20 municipios
        df = df[df["ENTIDAD"] == "24"].copy()
        df = df[df["MUN"].isin(MUNICIPIOS_HUASTECA.keys())].copy()

        # Excluir filas de totales (NOM_LOC contiene "Total de")
        df = df[~df["NOM_LOC"].str.contains("Total de", na=False)].copy()

        logger.info(f"[OK] ITER leido: {len(df)} localidades en la Huasteca")
        return df

    except Exception as e:
        logger.error(f"[ERROR] Error leyendo ITER: {e}")
        return None


# ============================================================
# PASO 2: POBLAR catalogo.localidad
# ============================================================

def poblar_localidades(df_iter: pd.DataFrame,
                        gdf_shp: gpd.GeoDataFrame | None) -> int:
    """
    Inserta localidades en catalogo.localidad.
    Cruza ITER (datos poblacionales) con shapefile (coordenadas).
    """
    conn = get_conn()
    cur  = conn.cursor()
    insertados = 0
    omitidos   = 0

    # Obtener IDs de municipios desde la BD
    cur.execute("SELECT clave_inegi, id FROM catalogo.municipio")
    mun_ids = {row[0]: row[1] for row in cur.fetchall()}

    # Preparar GDF como dict para lookup rapido por clave
    shp_coords = {}
    if gdf_shp is not None:
        # El shapefile tiene CVE_LOC o similar
        col_cve = next((c for c in gdf_shp.columns
                        if "cve" in c.lower() and "loc" in c.lower()), None)
        col_mun = next((c for c in gdf_shp.columns
                        if "cve" in c.lower() and "mun" in c.lower()), None)
        if col_cve and col_mun:
            for _, row in gdf_shp.iterrows():
                key = f"{str(row[col_mun]).zfill(3)}{str(row[col_cve]).zfill(4)}"
                if row.geometry:
                    shp_coords[key] = (row.geometry.y, row.geometry.x)

    for _, fila in df_iter.iterrows():
        cve_mun = str(fila.get("MUN", "")).zfill(3)
        cve_loc = str(fila.get("LOC", "")).zfill(4)
        nom_loc = str(fila.get("NOM_LOC", "")).strip()

        if not nom_loc or cve_mun not in mun_ids:
            omitidos += 1
            continue

        municipio_id = mun_ids[cve_mun]
        clave_inegi  = f"24{cve_mun}{cve_loc}"

        # Verificar duplicado
        cur.execute("SELECT 1 FROM catalogo.localidad WHERE clave_inegi = %s",
                    (clave_inegi,))
        if cur.fetchone():
            omitidos += 1
            continue

        # Coordenadas: primero del shapefile, luego del ITER
        coords_key = f"{cve_mun}{cve_loc}"
        lat = lon = None
        if coords_key in shp_coords:
            lat, lon = shp_coords[coords_key]
        else:
            # ITER tiene latitud/longitud en formato texto con punto decimal
            try:
                lat_str = str(fila.get("LATITUD",  "")).replace(" ", "")
                lon_str = str(fila.get("LONGITUD", "")).replace(" ", "")
                if lat_str and lat_str != "nan":
                    lat = float(lat_str)
                if lon_str and lon_str != "nan":
                    lon = float(lon_str)
            except ValueError:
                pass

        # Datos poblacionales del ITER
        def to_int(val):
            try:
                v = int(float(str(val).replace("*", "").strip()))
                return v if v >= 0 else None
            except (ValueError, TypeError):
                return None

        pob_total  = to_int(fila.get("POBTOT"))
        pob_masc   = to_int(fila.get("POBMAS"))
        pob_fem    = to_int(fila.get("POBFEM"))
        num_viv    = to_int(fila.get("VIVTOT"))

        # Tipo de localidad por poblacion
        tipo = "urbana" if (pob_total or 0) >= 2500 else "rural"

        cur.execute("""
            INSERT INTO catalogo.localidad
                (clave_inegi, nombre, tipo,
                 poblacion_total, poblacion_masculina, poblacion_femenina,
                 num_viviendas, latitud, longitud,
                 municipio_id, fuente)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,'INEGI ITER 2020')
        """, (
            clave_inegi, nom_loc, tipo,
            pob_total, pob_masc, pob_fem,
            num_viv, lat, lon,
            municipio_id,
        ))
        insertados += 1

    conn.commit()
    cur.close()
    conn.close()
    logger.info(f"[OK] Localidades: {insertados} insertadas, {omitidos} omitidas")
    return insertados


# ============================================================
# PASO 3: POBLAR catalogo.colonia
# Fuente: API asentamientos de INEGI
# Campos: nom_asen, tip_asent, d_codigo (codigo postal)
# ============================================================

def poblar_colonias_municipio(cve_mun: str, municipio_id: int,
                               cur) -> int:
    """Descarga y carga los asentamientos de un municipio."""
    url = f"{BASE_API}/asentamientos/24/{cve_mun}"
    try:
        resp = requests.get(url, timeout=30, headers=HEADERS)
        resp.raise_for_status()
        data = resp.json()

        # La API retorna lista o dict con lista
        registros = data if isinstance(data, list) else data.get("recordset", [])
        if not registros:
            logger.warning(f"[WARN] Sin asentamientos para municipio {cve_mun}")
            return 0

        # Buscar localidad cabecera para vincular
        cur.execute("""
            SELECT id FROM catalogo.localidad
            WHERE municipio_id = %s
            ORDER BY poblacion_total DESC NULLS LAST
            LIMIT 1
        """, (municipio_id,))
        row_loc = cur.fetchone()
        localidad_id = row_loc[0] if row_loc else None

        insertados = 0
        for reg in registros:
            # Campos de la API de asentamientos INEGI
            nombre = str(reg.get("nom_asen", reg.get("NOM_ASEN", ""))).strip()
            tipo   = str(reg.get("tip_asent", reg.get("TIP_ASENT", "otro"))).strip().lower()
            cp     = str(reg.get("d_codigo",  reg.get("D_CODIGO",  ""))).strip().zfill(5)

            if not nombre:
                continue

            # Normalizar tipo
            tipo_norm = "colonia"
            if "barrio"         in tipo: tipo_norm = "barrio"
            elif "fraccion"     in tipo: tipo_norm = "fraccionamiento"
            elif "ejido"        in tipo: tipo_norm = "ejido"
            elif "rancho"       in tipo: tipo_norm = "rancheria"
            elif "seccion"      in tipo: tipo_norm = "seccion"

            # Verificar duplicado
            cur.execute("""
                SELECT 1 FROM catalogo.colonia
                WHERE nombre = %s AND municipio_id = %s
                LIMIT 1
            """, (nombre, municipio_id))
            if cur.fetchone():
                continue

            cur.execute("""
                INSERT INTO catalogo.colonia
                    (nombre, tipo, codigo_postal,
                     localidad_id, municipio_id)
                VALUES (%s, %s, %s, %s, %s)
            """, (nombre, tipo_norm,
                  cp if cp != "00000" else None,
                  localidad_id, municipio_id))
            insertados += 1

        return insertados

    except Exception as e:
        logger.error(f"[ERROR] Colonias municipio {cve_mun}: {e}")
        return 0


def poblar_colonias() -> int:
    """Puebla catalogo.colonia para todos los municipios de la Huasteca."""
    conn = get_conn()
    cur  = conn.cursor()

    cur.execute("SELECT clave_inegi, id FROM catalogo.municipio")
    municipios = {row[0]: row[1] for row in cur.fetchall()}

    total = 0
    for i, (cve_mun, nombre) in enumerate(MUNICIPIOS_HUASTECA.items(), 1):
        if cve_mun not in municipios:
            logger.warning(f"[WARN] Municipio {cve_mun} no en BD, omitido")
            continue

        logger.info(f"[{i}/{len(MUNICIPIOS_HUASTECA)}] Colonias: {nombre}")
        n = poblar_colonias_municipio(cve_mun, municipios[cve_mun], cur)
        conn.commit()
        total += n
        logger.info(f"  {n} asentamientos insertados")

        # Respetar limite de la API
        if i < len(MUNICIPIOS_HUASTECA):
            time.sleep(1)

    cur.close()
    conn.close()
    logger.info(f"[OK] Colonias total: {total} insertadas")
    return total


# ============================================================
# RESUMEN FINAL
# ============================================================

def mostrar_resumen():
    conn = get_conn()
    cur  = conn.cursor()
    print("\nResumen del catalogo territorial:")
    print("-" * 50)
    for tabla, label in [
        ("catalogo.estado",    "Estados"),
        ("catalogo.municipio", "Municipios"),
        ("catalogo.localidad", "Localidades"),
        ("catalogo.colonia",   "Colonias/Asentamientos"),
        ("catalogo.lengua",    "Lenguas originarias"),
    ]:
        cur.execute(f"SELECT COUNT(*) FROM {tabla}")
        n = cur.fetchone()[0]
        print(f"  {label:<25} {n:>6} registros")
    cur.close()
    conn.close()
    print()


# ============================================================
# PUNTO DE ENTRADA
# ============================================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Poblador del catalogo territorial INEGI — Huasteca Potosina"
    )
    parser.add_argument("--solo-localidades", action="store_true",
                        help="Solo poblar localidades, omitir colonias")
    parser.add_argument("--solo-colonias",    action="store_true",
                        help="Solo poblar colonias, omitir localidades")
    parser.add_argument("--municipio",        type=str,
                        help="Clave INEGI de un municipio especifico (ej. 013)")
    args = parser.parse_args()

    print("""
+----------------------------------------------------------+
|  POBLADOR CATALOGO TERRITORIAL - HUASTECA POTOSINA       |
|  PEE-2025-G-369 | TecNM Ciudad Valles                    |
+----------------------------------------------------------+
    """)

    if not args.solo_colonias:
        # Paso 1: descargar ITER si no existe
        if not descargar_iter():
            print("[ERROR] No se pudo obtener el ITER 2020. Verifica conexion a internet.")
            exit(1)

        # Paso 2: leer ITER
        df_iter = leer_iter()
        if df_iter is None:
            exit(1)

        # Paso 3: cargar shapefile de localidades si existe
        gdf_shp = None
        if SHP_LOCALIDADES.exists():
            gdf_shp = gpd.read_file(SHP_LOCALIDADES)
            logger.info(f"Shapefile localidades cargado: {len(gdf_shp)} features")
        else:
            logger.warning("[WARN] Shapefile no encontrado, usando solo coordenadas del ITER")

        # Filtrar municipio si se especifico
        if args.municipio:
            df_iter = df_iter[df_iter["MUN"] == args.municipio.zfill(3)]
            logger.info(f"Filtrado a municipio {args.municipio}: {len(df_iter)} localidades")

        # Paso 4: insertar localidades
        n_loc = poblar_localidades(df_iter, gdf_shp)
        print(f"  Localidades insertadas: {n_loc}")

    if not args.solo_localidades:
        # Paso 5: insertar colonias/asentamientos via API
        print("\nDescargando colonias y asentamientos desde API INEGI...")
        if args.municipio:
            conn = get_conn()
            cur  = conn.cursor()
            cur.execute("SELECT id FROM catalogo.municipio WHERE clave_inegi = %s",
                        (args.municipio.zfill(3),))
            row = cur.fetchone()
            cur.close(); conn.close()
            if row:
                n_col = poblar_colonias_municipio(
                    args.municipio.zfill(3), row[0], get_conn().cursor())
            else:
                print(f"[ERROR] Municipio {args.municipio} no encontrado en BD")
                n_col = 0
        else:
            n_col = poblar_colonias()
        print(f"  Colonias/asentamientos insertados: {n_col}")

    mostrar_resumen()
    print("[OK] Catalogo territorial poblado correctamente.")