-- 10_triggers.sql
-- ============================================================
-- Triggers 
-- ============================================================

-- Este archivo contiene triggers para mantener la integridad de los datos y automatizar tareas comunes, como actualizar timestamps o generar geometrías a partir de latitud/longitud.


-- ============================================================
-- TRIGGER: Derivar municipio desde localidad (evita redundancia)
-- ============================================================

CREATE OR REPLACE FUNCTION geo.fn_validar_municipio_visita()
RETURNS TRIGGER AS $$
DECLARE
    v_municipio_id INTEGER;
BEGIN
    IF NEW.localidad_id IS NOT NULL THEN
        SELECT municipio_id INTO v_municipio_id
        FROM catalogo.localidad
        WHERE id = NEW.localidad_id;

        -- Aquí podrías usar este valor en futuras extensiones
        -- (por ejemplo, logs o auditoría)

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_municipio_visita
BEFORE INSERT OR UPDATE ON geo.visita_campo
FOR EACH ROW
EXECUTE FUNCTION geo.fn_validar_municipio_visita();

-- Función para actualizar el campo geom de la tabla ubicacion a partir de latitud y longitud
CREATE OR REPLACE FUNCTION geo.set_ubicacion_geom()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.geom IS NULL AND NEW.latitud IS NOT NULL AND NEW.longitud IS NOT NULL THEN
        NEW.geom := ST_SetSRID(ST_MakePoint(NEW.longitud, NEW.latitud), 4326);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: recalcular completitud después de cada INSERT/UPDATE en valores_fenotipicos
CREATE OR REPLACE FUNCTION recalcular_completitud() RETURNS TRIGGER AS $$
BEGIN
    UPDATE fenotipico.evaluacion_fenotipica
    SET completitud_pct = (
        SELECT ROUND(
            COUNT(vf.id) * 100.0 /
            -- total descriptores fenotípicos del catálogo (D1-D24 + D26-D63 = 62)
            (SELECT COUNT(*) FROM catalogo.descriptores_catalogo WHERE modulo = 'fenotipico'),
            2
        )
        FROM fenotipico.valores_fenotipicos vf
        WHERE vf.evaluacion_id = NEW.evaluacion_id
          AND (vf.valor_texto IS NOT NULL AND vf.valor_texto != ''
               OR vf.valor_numerico IS NOT NULL)
    )
    WHERE id = NEW.evaluacion_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_completitud
AFTER INSERT OR UPDATE ON fenotipico.valores_fenotipicos
FOR EACH ROW EXECUTE FUNCTION recalcular_completitud();

-- UBICACION
CREATE TRIGGER trg_ubicacion_geom
BEFORE INSERT OR UPDATE ON core.ubicacion
FOR EACH ROW EXECUTE FUNCTION geo.set_ubicacion_geom();

-- Esta función se puede reutilizar para cualquier tabla que tenga un campo updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- LOCALIDAD
CREATE TRIGGER trg_localidad_updated_at
BEFORE UPDATE ON catalogo.localidad
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- COMUNIDAD
CREATE TRIGGER trg_comunidad_updated_at
BEFORE UPDATE ON core.comunidad
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- COLONIA
CREATE TRIGGER trg_colonia_updated_at
BEFORE UPDATE ON catalogo.colonia
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- UBICACION
CREATE TRIGGER trg_ubicacion_updated_at
BEFORE UPDATE ON core.ubicacion
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- PARCELA
CREATE TRIGGER trg_parcela_updated_at
BEFORE UPDATE ON core.parcela
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- HISTORIAL_PARCELA
CREATE TRIGGER trg_historial_parcela_updated_at
BEFORE UPDATE ON geo.historial_parcela
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- IMAGEN_SATELITAL
CREATE TRIGGER trg_imagen_satelital_updated_at
BEFORE UPDATE ON geo.imagen_satelital
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- VUELO_DRON
CREATE TRIGGER trg_vuelo_dron_updated_at
BEFORE UPDATE ON geo.vuelo_dron
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- PRODUCTO_DRON
CREATE TRIGGER trg_producto_dron_updated_at
BEFORE UPDATE ON geo.producto_dron
FOR EACH ROW        
EXECUTE FUNCTION public.set_updated_at();

-- ZONA_PRIORITARIA
CREATE TRIGGER trg_zona_prioritaria_updated_at
BEFORE UPDATE ON geo.zona_prioritaria
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- CAMBIO_USO_SUELO
CREATE TRIGGER trg_cambio_uso_suelo_updated_at
BEFORE UPDATE ON geo.cambio_uso_suelo
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- CAPA_SIG
CREATE TRIGGER trg_capa_sig_updated_at
BEFORE UPDATE ON geo.capa_sig
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- VISITA_CAMPO
CREATE TRIGGER trg_visita_campo_updated_at
BEFORE UPDATE ON geo.visita_campo
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- OBSERVACION_CAMPO
CREATE TRIGGER trg_observacion_campo_updated_at
BEFORE UPDATE ON geo.observacion_campo
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


-- CICLO_AGRICOLA
CREATE TRIGGER trg_ciclo_agricola_updated_at
BEFORE UPDATE ON catalogo.ciclo_agricola
FOR EACH ROW    
EXECUTE FUNCTION public.set_updated_at();

-- GERMOPLASMA
CREATE TRIGGER trg_germoplasma_updated_at
BEFORE UPDATE ON core.germoplasma
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- CULTIVO
CREATE TRIGGER trg_cultivo_updated_at
BEFORE UPDATE ON core.cultivo
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- SISTEMA DE SEMILLA
CREATE TRIGGER trg_sistema_semilla_updated_at
BEFORE UPDATE ON social.sistema_semilla
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- USO DEL MAIZ COSECHADO
CREATE TRIGGER trg_uso_maiz_updated_at
BEFORE UPDATE ON cultural.uso_maiz
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- ECONOMIA DEL CULTIVO
CREATE TRIGGER trg_economia_cultivo_updated_at
BEFORE UPDATE ON social.economia_cultivo
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_variedades_updated_at
BEFORE UPDATE ON agro.variedad
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- FUNCIÓN AUXILIAR: parsear geopoint de KoboToolbox
-- KoboToolbox exporta el campo geopoint como texto:
--   "21.9923456 -99.0134567 1023.5 4.2"
-- Esta función lo descompone en sus partes.
-- ============================================================

CREATE OR REPLACE FUNCTION social.parse_kobo_geopoint(
    geopoint_text TEXT,
    OUT lat        DECIMAL(10,7),
    OUT lon        DECIMAL(10,7),
    OUT alt        DECIMAL(8,2),
    OUT precision_m  DECIMAL(6,2)
)
LANGUAGE plpgsql AS $$
DECLARE
    parts TEXT[];
BEGIN
    IF geopoint_text IS NULL OR trim(geopoint_text) = '' THEN
        RETURN;
    END IF;
    parts := string_to_array(trim(geopoint_text), ' ');
    lat       := parts[1]::DECIMAL;
    lon       := parts[2]::DECIMAL;
    alt       := CASE WHEN array_length(parts,1) >= 3 THEN parts[3]::DECIMAL ELSE NULL END;
    precision_m := CASE WHEN array_length(parts,1) >= 4 THEN parts[4]::DECIMAL ELSE NULL END;
END;
$$;


-- ============================================================
-- FUNCIÓN: parsear geopoint de KoboToolbox (reutilizable)
-- (misma lógica que social.parse_kobo_geopoint en 03_social.sql,
--  redeclarada aquí en el esquema cultural para independencia)
-- ============================================================

CREATE OR REPLACE FUNCTION cultural.parse_kobo_geopoint(
    geopoint_text TEXT,
    OUT lat        DECIMAL(10,7),
    OUT lon        DECIMAL(10,7),
    OUT alt        DECIMAL(8,2),
    OUT precision_m  DECIMAL(6,2)
)
LANGUAGE plpgsql AS $$
DECLARE
    parts TEXT[];
BEGIN
    IF geopoint_text IS NULL OR trim(geopoint_text) = '' THEN
        RETURN;
    END IF;
    parts := string_to_array(trim(geopoint_text), ' ');
    lat       := parts[1]::DECIMAL;
    lon       := parts[2]::DECIMAL;
    alt       := CASE WHEN array_length(parts,1) >= 3 THEN parts[3]::DECIMAL ELSE NULL END;
    precision_m := CASE WHEN array_length(parts,1) >= 4 THEN parts[4]::DECIMAL ELSE NULL END;
END;
$$;

-- ============================================================
-- TRIGGERS INTELIGENTES Y AUDITORÍA
-- ============================================================

-- 1. AUDITORÍA DE CAMBIOS EN PARCELA
CREATE TABLE IF NOT EXISTS auditoria.parcela_historial (
    id SERIAL PRIMARY KEY,
    parcela_id UUID,
    operacion TEXT,
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    fecha TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION auditoria.fn_parcela_auditoria()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria.parcela_historial(parcela_id, operacion, datos_anteriores, datos_nuevos)
        VALUES (OLD.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria.parcela_historial(parcela_id, operacion, datos_nuevos)
        VALUES (NEW.id, 'INSERT', to_jsonb(NEW));
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria.parcela_historial(parcela_id, operacion, datos_anteriores)
        VALUES (OLD.id, 'DELETE', to_jsonb(OLD));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_parcela_auditoria
AFTER INSERT OR UPDATE OR DELETE ON core.parcela
FOR EACH ROW EXECUTE FUNCTION auditoria.fn_parcela_auditoria();


-- 2. ALERTA NDVI BAJO
CREATE TABLE IF NOT EXISTS ambiental.alerta_ndvi (
    id SERIAL PRIMARY KEY,
    parcela_id UUID,
    ndvi DECIMAL(6,4),
    nivel TEXT,
    fecha TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION ambiental.fn_alerta_ndvi()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ndvi < 0.3 THEN
        INSERT INTO ambiental.alerta_ndvi(parcela_id, ndvi, nivel)
        VALUES (NEW.parcela_id, NEW.ndvi, 'CRITICO');
    ELSIF NEW.ndvi < 0.5 THEN
        INSERT INTO ambiental.alerta_ndvi(parcela_id, ndvi, nivel)
        VALUES (NEW.parcela_id, NEW.ndvi, 'MEDIO');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_alerta_ndvi
AFTER INSERT ON ambiental.indice_vegetacion
FOR EACH ROW EXECUTE FUNCTION ambiental.fn_alerta_ndvi();


-- 3. ALERTA DE HUMEDAD CRÍTICA
CREATE TABLE IF NOT EXISTS ambiental.alerta_humedad (
    id SERIAL PRIMARY KEY,
    ubicacion_id INTEGER,
    humedad DECIMAL(5,2),
    fecha TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION ambiental.fn_alerta_humedad()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.humedad_relativa < 30 THEN
        INSERT INTO ambiental.alerta_humedad(ubicacion_id, humedad)
        VALUES (NEW.ubicacion_id, NEW.humedad_relativa);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_alerta_humedad
AFTER INSERT ON ambiental.medicion_ambiental
FOR EACH ROW EXECUTE FUNCTION ambiental.fn_alerta_humedad();


-- 4. VALIDACIÓN DE TEMPERATURA
CREATE OR REPLACE FUNCTION ambiental.fn_validar_temperatura()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.temperatura < -10 OR NEW.temperatura > 60 THEN
        RAISE EXCEPTION 'Temperatura fuera de rango: %', NEW.temperatura;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_temperatura
BEFORE INSERT OR UPDATE ON ambiental.medicion_ambiental
FOR EACH ROW EXECUTE FUNCTION ambiental.fn_validar_temperatura();


-- 5. VALIDACIÓN ESPACIAL (GEOMETRÍA VACÍA)
CREATE OR REPLACE FUNCTION geo.fn_validar_geom()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.geom IS NULL THEN
        RAISE EXCEPTION 'La geometría no puede ser NULL';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_geom
BEFORE INSERT OR UPDATE ON core.ubicacion
FOR EACH ROW EXECUTE FUNCTION geo.fn_validar_geom();

-- Variedades evaluadas en radio de X km desde un punto dado
CREATE OR REPLACE FUNCTION geo.variedades_en_radio(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radio_km DOUBLE PRECISION DEFAULT 10
)
RETURNS TABLE (
    parcela_id UUID,
    nombre_parcela TEXT,
    germoplasma_id UUID,
    nombre_germoplasma TEXT,
    distancia_km NUMERIC,
    municipio TEXT,
    altitud_msnm SMALLINT,
    ciclo_agricola TEXT,
    fecha_siembra DATE
) AS $$
SELECT DISTINCT ON (p.id, g.id)
    p.id,
    p.nombre::TEXT,
    g.id,
    g.nombre_local::TEXT,
    ROUND(
        (
            ST_Distance(
                p.poligono::geography,
                ST_SetSRID(
                    ST_MakePoint(lng, lat),
                    4326
                )::geography
            ) / 1000.0
        )::NUMERIC,
        2
    ) AS distancia_km,
    m.nombre::TEXT,
    u.altitud_m,
    s.ciclo_agricola::TEXT,
    s.fecha_siembra
FROM core.parcela p
LEFT JOIN core.productor pr
    ON pr.id = p.productor_id
LEFT JOIN catalogo.municipio m
    ON m.id = pr.municipio_id
LEFT JOIN core.ubicacion u
    ON u.id = p.ubicacion_id
LEFT JOIN core.siembra s
    ON s.parcela_id = p.id
LEFT JOIN core.germoplasma g
    ON g.id = s.germoplasma_id
WHERE
    p.poligono IS NOT NULL
    AND ST_DWithin(
        p.poligono::geography,
        ST_SetSRID(
            ST_MakePoint(lng, lat),
            4326
        )::geography,
        radio_km * 1000
    )
    AND g.id IS NOT NULL
ORDER BY p.id, g.id, distancia_km;
$$ LANGUAGE SQL STABLE;

-- GeoJSON de todas las parcelas con datos de variedad (para el mapa)
CREATE OR REPLACE FUNCTION core.parcelas_geojson(
    ciclo_filtro TEXT DEFAULT NULL,
    anio_filtro  INTEGER DEFAULT NULL
)
RETURNS JSON AS $$
SELECT json_build_object(
    'type', 'FeatureCollection',
    'features',
    COALESCE(
        json_agg(
            json_build_object(
                'type', 'Feature',
                'geometry',
                ST_AsGeoJSON(p.poligono)::json,
                'properties',
                json_build_object(
                    'parcela_id',        p.id,
                    'nombre',            p.nombre,
                    'productor',         pr.nombres,
                    'municipio',         m.nombre,
                    'altitud_msnm',      u.altitud_m,
                    'superficie_ha',     p.superficie_ha,
                    'fecha_siembra',     s.fecha_siembra,
                    'fecha_cosecha',     s.fecha_cosecha,
                    'ciclo_agricola',    s.ciclo_agricola,
                    'germoplasma_id',    g.id,
                    'germoplasma',       g.nombre_local,
                    'codigo_accesion',   g.codigo_accesion
                )
            )
        ),
        '[]'::json
    )
)
FROM core.parcela p
LEFT JOIN core.productor pr
    ON pr.id = p.productor_id
LEFT JOIN catalogo.municipio m
    ON m.id = pr.municipio_id
LEFT JOIN core.ubicacion u
    ON u.id = p.ubicacion_id
LEFT JOIN core.siembra s
    ON s.parcela_id = p.id
LEFT JOIN core.germoplasma g
    ON g.id = s.germoplasma_id
WHERE
    (
        ciclo_filtro IS NULL
        OR s.ciclo_agricola = ciclo_filtro
    )
    AND (
        anio_filtro IS NULL
        OR EXTRACT(YEAR FROM s.fecha_siembra)::INTEGER = anio_filtro
    );
$$ LANGUAGE SQL STABLE;