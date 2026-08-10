-- ----------------------------
-- (OPCIONAL) Índices espaciales
-- ----------------------------

-- Solo si agregas columna geom
-- ALTER TABLE catalogo.localidad ADD COLUMN geom GEOMETRY(Point, 4326);

-- CREATE INDEX IF NOT EXISTS idx_localidad_geom
-- ON catalogo.localidad USING GIST (geom);


-- =========================
-- INDICES: SOCIAL
-- =========================







-- ============================================================
-- 9. GEOLOCALIZACIÓN DE PRODUCTORES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_geo_productor ON social.geolocalizacion_productor(productor_id);

-- Índice espacial simple para consultas por zona
-- Índice GIST espacial si se usa PostGIS
CREATE INDEX idx_geo_location
    ON social.geolocalizacion_productor
    USING GIST (
        ST_SetSRID(
            ST_MakePoint(longitud, latitud),
            4326
        )
    );




-- =========================
-- INDICES: AMBIENTAL
-- =========================



-- ============================================================
-- 2. MEDICIÓN AMBIENTAL
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_medicion_fecha ON ambiental.medicion_ambiental(fecha_medicion);

CREATE INDEX IF NOT EXISTS idx_medicion_ubicacion ON ambiental.medicion_ambiental(ubicacion_id);

CREATE INDEX IF NOT EXISTS idx_medicion_estacion ON ambiental.medicion_ambiental(estacion_id);

CREATE INDEX IF NOT EXISTS idx_medicion_ubicacion_fecha ON ambiental.medicion_ambiental(ubicacion_id, fecha_medicion);
-- ============================================================
-- 3. INDICE VEGETACIÓN
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_indice_parcela ON ambiental.indice_vegetacion(parcela_id);

CREATE INDEX IF NOT EXISTS idx_indice_fecha ON ambiental.indice_vegetacion(fecha_calculo);

CREATE INDEX IF NOT EXISTS idx_indice_parcela_fecha ON ambiental.indice_vegetacion(parcela_id, fecha_calculo);
-- ============================================================
-- 4. SERIE NDVI
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_serie_ndvi_parcela ON ambiental.serie_ndvi(parcela_id);
-- ============================================================
-- 5. CONDICION EDAFICA
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_suelo_parcela ON ambiental.condicion_edafica(parcela_id);

-- ============================================================
-- 6. AMENAZA
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_amenaza_geom ON ambiental.amenaza USING GIST (poligono);

CREATE INDEX IF NOT EXISTS idx_amenaza_municipio ON ambiental.amenaza(municipio_id);

-- =========================
-- INDICES PARA CONSULTAS TEMPORALES (si tienes fechas)
-- =========================

CREATE INDEX IF NOT EXISTS idx_amenaza_fecha ON ambiental.amenaza(fecha_deteccion);

CREATE INDEX ix_ra_variedad ON agronomico.registros_agronomicos(variedad_id);
CREATE INDEX ix_ra_ciclo_anio ON agronomico.registros_agronomicos(ciclo, anio);