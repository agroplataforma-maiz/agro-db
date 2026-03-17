"""
AGROPLATAFORMA DIGITAL - GENERADOR DE SQL TERRITORIAL
PEE-2025-G-369 | TecNM Ciudad Valles

Consulta la API REST de INEGI y genera un archivo SQL listo
para ejecutar directamente en PostgreSQL o incluir en Docker.

Salida:
    ./db/11_localidades_colonias.sql

Una vez generado, agrégalo al docker-compose.yml:
    - ./db/11_localidades_colonias.sql:/docker-entrypoint-initdb.d/11_localidades_colonias.sql

Uso:
    pip install requests
    python generar_sql_territorial.py

    # Solo un municipio para probar:
    python generar_sql_territorial.py --municipio 013
"""

import time
import argparse
import requests
from pathlib import Path
from datetime import datetime

BASE_API = "https://gaia.inegi.org.mx/wscatgeo/v2"
HEADERS  = {"User-Agent": "AgroplataformaBot/1.0 (TecNM; PEE-2025-G-369)"}

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

TIPO_ASENTAMIENTO = {
    "colonia":             "colonia",
    "barrio":              "barrio",
    "fraccionamiento":     "fraccionamiento",
    "ejido":               "ejido",
    "rancho":              "rancheria",
    "ranchería":           "rancheria",
    "sección":             "seccion",
    "ampliación":          "colonia",
    "unidad habitacional": "fraccionamiento",
    "residencial":         "fraccionamiento",
    "condominio":          "fraccionamiento",
}


def esc(val):
    """Escapa comillas simples para SQL."""
    if val is None:
        return "NULL"
    return "'" + str(val).replace("'", "''") + "'"


def num(val):
    """Retorna valor numérico o NULL."""
    if val is None:
        return "NULL"
    try:
        v = float(str(val).strip())
        return "NULL" if v == 0.0 else str(v)
    except (ValueError, TypeError):
        return "NULL"


def entero(val):
    """Retorna entero o NULL."""
    if val is None:
        return "NULL"
    try:
        return str(int(float(str(val).strip())))
    except (ValueError, TypeError):
        return "NULL"


def consultar_api(url: str) -> list:
    try:
        resp = requests.get(url, timeout=30, headers=HEADERS)
        resp.raise_for_status()
        data = resp.json()
        # Localidades retorna {"datos": [...], "metadatos": ..., "numReg": ...}
        # Asentamientos retorna lista directa o {"recordset": [...]}
        if isinstance(data, list):
            return data
        if "datos" in data:
            return data["datos"]
        if "recordset" in data:
            return data["recordset"]
        # Si retorna result=404 no hay datos para ese municipio
        if data.get("result") == "404":
            return []
        return []
    except Exception as e:
        print(f"  [ERROR] {url}: {e}")
        return []


def generar_sql(municipios: dict, salida: Path):
    lineas = []

    lineas.append("-- ============================================================")
    lineas.append("-- CATALOGO TERRITORIAL - LOCALIDADES Y COLONIAS")
    lineas.append("-- Huasteca Potosina — 20 municipios")
    lineas.append("-- PEE-2025-G-369 | TecNM Ciudad Valles")
    lineas.append(f"-- Generado: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lineas.append("-- Fuente: API gaia.inegi.org.mx/wscatgeo/v2")
    lineas.append("-- ============================================================")
    lineas.append("")
    lineas.append("SET search_path TO catalogo, public;")
    lineas.append("")

    total_loc = 0
    total_col = 0

    for i, (cve_mun, nom_mun) in enumerate(municipios.items(), 1):
        print(f"[{i}/{len(municipios)}] {nom_mun} ({cve_mun})")

        lineas.append(f"-- ------------------------------------------------------------")
        lineas.append(f"-- {nom_mun} (clave {cve_mun})")
        lineas.append(f"-- ------------------------------------------------------------")
        lineas.append("")

        # ── Localidades ──────────────────────────────────────────
        lineas.append(f"-- Localidades de {nom_mun}")
        # URL correcta: cvegeoMun = estado+municipio concatenados = 24013
        cvegeo_mun = f"24{cve_mun}"
        registros_loc = consultar_api(f"{BASE_API}/localidades/{cvegeo_mun}")
        n_loc = 0
        for reg in registros_loc:
            # Campos reales confirmados de la API INEGI:
            # cvegeo, cve_ent, cve_mun, cve_loc, nomgeo, ambito,
            # latitud, longitud, altitud, pob_total, total_viviendas_habitadas
            cve_loc     = str(reg.get("cve_loc", "")).strip()
            nom_loc     = str(reg.get("nomgeo",  "")).strip()
            if not nom_loc or not cve_loc:
                continue

            clave_inegi = str(reg.get("cvegeo", f"24{cve_mun}{cve_loc.zfill(4)}")).strip()
            ambito      = str(reg.get("ambito", "")).upper()
            tipo        = "'urbana'" if ambito == "URBANO" else "'rural'"
            lat         = num(reg.get("latitud",   ""))
            lon         = num(reg.get("longitud",  ""))
            alt         = num(reg.get("altitud",   ""))
            pob         = entero(reg.get("pob_total", ""))
            viv         = entero(reg.get("total_viviendas_habitadas", ""))

            lineas.append(
                f"INSERT INTO catalogo.localidad "
                f"(clave_inegi, nombre, tipo, "
                f"poblacion_total, num_viviendas, "
                f"latitud, longitud, altitud_m, "
                f"municipio_id, fuente) "
                f"SELECT {esc(clave_inegi)}, {esc(nom_loc)}, {tipo}, "
                f"{pob}, {viv}, "
                f"{lat}, {lon}, {alt}, "
                f"m.id, 'INEGI API 2024' "
                f"FROM catalogo.municipio m "
                f"WHERE m.clave_inegi = '{cve_mun}' "
                f"ON CONFLICT DO NOTHING;"
            )
            n_loc += 1

        print(f"  Localidades: {n_loc}")
        total_loc += n_loc
        lineas.append("")

        # ── Colonias / Asentamientos ──────────────────────────────
        lineas.append(f"-- Colonias y asentamientos de {nom_mun}")
        time.sleep(0.5)
        # Asentamientos usa cve_ent/cve_mun con diagonal: 24/013
        registros_col = consultar_api(f"{BASE_API}/asentamientos/24/{cve_mun}")
        n_col = 0
        for reg in registros_col:
            nombre   = str(reg.get("nom_asen",  reg.get("NOM_ASEN",  ""))).strip()
            tipo_raw = str(reg.get("tip_asent", reg.get("TIP_ASENT", ""))).strip().lower()
            cp_raw   = str(reg.get("d_codigo",  reg.get("D_CODIGO",  ""))).strip()
            lat      = num(reg.get("latitud",  reg.get("LATITUD",  "")))
            lon      = num(reg.get("longitud", reg.get("LONGITUD", "")))

            if not nombre:
                continue

            # Normalizar tipo
            tipo_norm = "otro"
            for clave, valor in TIPO_ASENTAMIENTO.items():
                if clave in tipo_raw:
                    tipo_norm = valor
                    break

            cp = f"'{cp_raw.zfill(5)}'" if cp_raw and cp_raw.isdigit() else "NULL"

            # Vincula a la localidad cabecera del municipio
            lineas.append(
                f"INSERT INTO catalogo.colonia "
                f"(nombre, tipo, codigo_postal, latitud, longitud, "
                f"localidad_id, municipio_id) "
                f"SELECT {esc(nombre)}, '{tipo_norm}', {cp}, {lat}, {lon}, "
                f"(SELECT id FROM catalogo.localidad "
                f" WHERE municipio_id = m.id "
                f" ORDER BY poblacion_total DESC NULLS LAST LIMIT 1), "
                f"m.id "
                f"FROM catalogo.municipio m "
                f"WHERE m.clave_inegi = '{cve_mun}' "
                f"AND NOT EXISTS ("
                f"  SELECT 1 FROM catalogo.colonia c2 "
                f"  WHERE LOWER(c2.nombre) = LOWER({esc(nombre)}) "
                f"  AND c2.municipio_id = m.id"
                f");"
            )
            n_col += 1

        print(f"  Colonias:    {n_col}")
        total_col += n_col
        lineas.append("")
        time.sleep(0.5)

    lineas.append("-- ============================================================")
    lineas.append(f"-- TOTAL: {total_loc} localidades, {total_col} colonias/asentamientos")
    lineas.append("-- ============================================================")

    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text("\n".join(lineas), encoding="utf-8")
    print(f"\n[OK] SQL generado: {salida}")
    print(f"     Localidades: {total_loc}")
    print(f"     Colonias:    {total_col}")
    print(f"\nAgrega al docker-compose.yml:")
    print(f"  - ./db/11_localidades_colonias.sql:"
          f"/docker-entrypoint-initdb.d/11_localidades_colonias.sql")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generador de SQL territorial desde API INEGI"
    )
    parser.add_argument("--municipio", type=str,
                        help="Solo un municipio (ej. 013 = Ciudad Valles)")
    args = parser.parse_args()

    print("""
+----------------------------------------------------------+
|  GENERADOR SQL TERRITORIAL - HUASTECA POTOSINA           |
|  Fuente: API gaia.inegi.org.mx                           |
|  PEE-2025-G-369 | TecNM Ciudad Valles                    |
+----------------------------------------------------------+
    """)

    municipios = (
        {args.municipio.zfill(3): MUNICIPIOS_HUASTECA[args.municipio.zfill(3)]}
        if args.municipio and args.municipio.zfill(3) in MUNICIPIOS_HUASTECA
        else MUNICIPIOS_HUASTECA
    )

    salida = Path("./db/11_localidades_colonias.sql")
    generar_sql(municipios, salida)