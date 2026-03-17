-- ============================================================
-- ESQUEMA: ambiental
-- Mediciones climáticas, índices de vegetación,
-- amenazas socioambientales, estaciones meteorológicas
-- ============================================================

SET search_path TO ambiental, public;

-- Estación meteorológica (física o virtual)
CREATE TABLE ambiental.estacion_meteorologica (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(200),
    tipo            VARCHAR(30) CHECK (tipo IN ('fisica','virtual','satelital','API')),
    fuente          VARCHAR(100) CHECK (fuente IN (
                        'CONAGUA','NASA_POWER','OpenWeather',
                        'Copernicus','sensor_campo','otra')),
    municipio_id    INTEGER REFERENCES catalogo.municipio(id),
    ubicacion_id    INTEGER REFERENCES geografico.ubicacion(id),   -- FK a geografico.ubicacion
    activa          BOOLEAN DEFAULT TRUE,
    fecha_instalacion DATE,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Medición ambiental puntual
CREATE TABLE ambiental.medicion_ambiental (
    id                  SERIAL PRIMARY KEY,
    ubicacion_id        INTEGER REFERENCES geografico.ubicacion(id),   -- FK a geografico.ubicacion
    estacion_id         INTEGER REFERENCES ambiental.estacion_meteorologica(id),
    temperatura_c       DECIMAL(5,2),
    humedad_pct         DECIMAL(5,2),
    precipitacion_mm    DECIMAL(7,2),
    radiacion_solar     DECIMAL(8,2),
    velocidad_viento    DECIMAL(6,2),
    direccion_viento    DECIMAL(5,2),
    presion_atm_hpa     DECIMAL(7,2),
    fecha_medicion      TIMESTAMP NOT NULL,
    fuente              VARCHAR(50) CHECK (fuente IN (
                            'sensor_campo','estacion_meteorologica',
                            'satelite','API_CONAGUA','API_NASA',
                            'API_OpenWeather','Copernicus')),
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_medicion_fecha ON ambiental.medicion_ambiental(fecha_medicion);

CREATE INDEX idx_medicion_ubicacion ON ambiental.medicion_ambiental(ubicacion_id);

-- Índice de vegetación por imagen satelital
-- Registra NDVI, NDWI, GNDVI calculados por parcela/punto
CREATE TABLE ambiental.indice_vegetacion (
    id              SERIAL PRIMARY KEY,
    imagen_id       INTEGER REFERENCES geografico.imagen_satelital(id),   -- FK a geografico.imagen_satelital
    ubicacion_id    INTEGER REFERENCES geografico.ubicacion(id),   -- FK a geografico.ubicacion
    parcela_id      INTEGER REFERENCES geografico.parcela(id),   -- FK a geografico.parcela
    fecha_calculo   DATE NOT NULL,
    -- Índices principales
    ndvi            DECIMAL(6,4),   -- Normalized Difference Vegetation Index (-1 a 1)
    ndwi            DECIMAL(6,4),   -- Normalized Difference Water Index
    gndvi           DECIMAL(6,4),   -- Green NDVI
    ndmi            DECIMAL(6,4),   -- Normalized Difference Moisture Index
    evi             DECIMAL(6,4),   -- Enhanced Vegetation Index
    lai             DECIMAL(6,4),   -- Leaf Area Index
    -- Clasificación del estado de la vegetación
    estado_vegetacion VARCHAR(30) CHECK (estado_vegetacion IN (
                          'muy_bajo','bajo','moderado','alto','muy_alto')),
    -- Detección de estrés
    estres_hidrico  BOOLEAN DEFAULT FALSE,
    estres_termico  BOOLEAN DEFAULT FALSE,
    -- Metadatos del cálculo
    plataforma      VARCHAR(100),   -- ej. Google Earth Engine
    script_version  VARCHAR(20),
    notas           TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_indice_parcela ON ambiental.indice_vegetacion(parcela_id);

CREATE INDEX idx_indice_fecha ON ambiental.indice_vegetacion(fecha_calculo);

-- Serie temporal de NDVI por parcela (para análisis fenológico)
CREATE TABLE ambiental.serie_ndvi (
    id              SERIAL PRIMARY KEY,
    parcela_id      INTEGER REFERENCES geografico.parcela(id),   -- FK a geografico.parcela
    fecha           DATE NOT NULL,
    ndvi_promedio   DECIMAL(6,4),
    ndvi_max        DECIMAL(6,4),
    ndvi_min        DECIMAL(6,4),
    ndvi_std        DECIMAL(6,4),
    nubosidad_pct   DECIMAL(5,2),
    fuente          VARCHAR(50),
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_serie_ndvi_parcela
ON ambiental.serie_ndvi(parcela_id);

-- Condición edáfica (tipo de suelo por parcela)
CREATE TABLE ambiental.condicion_edafica (
    id                  SERIAL PRIMARY KEY,
    parcela_id          INTEGER REFERENCES geografico.parcela(id),   -- FK a geografico.parcela
    -- Variables de suelo
    tipo_suelo          VARCHAR(100),
    textura             VARCHAR(50) CHECK (textura IN ('arcilloso','limoso','arenoso','franco','otro')),
    ph                  DECIMAL(4,2),
    materia_organica_pct DECIMAL(5,2),
    nitrogeno_ppm       DECIMAL(8,2),
    fosforo_ppm         DECIMAL(8,2),
    potasio_ppm         DECIMAL(8,2),
    capacidad_campo_pct DECIMAL(5,2),
    -- Fuente del dato
    fuente              VARCHAR(50) CHECK (fuente IN ('laboratorio','sensores','interpolacion','INEGI')),
    fecha_muestreo      DATE,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_suelo_parcela ON ambiental.condicion_edafica(parcela_id);

-- Amenaza socioambiental detectada
CREATE TABLE ambiental.amenaza (
    id                  SERIAL PRIMARY KEY,
    tipo                VARCHAR(80) CHECK (tipo IN (
                            'expansion_agricola_industrial',
                            'ganaderia_extensiva',
                            'deforestacion',
                            'presencia_transgenicos',
                            'contaminacion_quimica',
                            'sequia_prolongada',
                            'inundacion',
                            'helada_atipica',
                            'plaga_emergente',
                            'abandono_campo',
                            'migracion_productores',
                            'otra')),
    descripcion         TEXT,
    nivel_riesgo        VARCHAR(20) CHECK (nivel_riesgo IN ('bajo','medio','alto','critico')),
    -- Fuente de detección
    fuente_deteccion    VARCHAR(50) CHECK (fuente_deteccion IN (
                            'imagen_satelital','vuelo_dron',
                            'entrevista_campo','reporte_institucional',
                            'modelo_ML','otro')),
    fecha_deteccion     DATE,
    municipio_id        INTEGER REFERENCES catalogo.municipio(id),   -- FK a catalogo.municipio
    ubicacion_id        INTEGER REFERENCES geografico.ubicacion(id),   -- FK a geografico.ubicacion
    area_afectada_ha    DECIMAL(12,4),
    poligono            GEOMETRY(MultiPolygon, 4326),
    esta_activa         BOOLEAN DEFAULT TRUE,
    acciones_propuestas TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_amenaza_geom ON ambiental.amenaza USING GIST (poligono);

CREATE INDEX idx_amenaza_municipio ON ambiental.amenaza(municipio_id);

-- ============================================================
-- VISTAS AMBIENTALES PARA ANALISIS AGROECOLOGICO
-- ============================================================

-- Vista: clima por ubicación/parcela
CREATE VIEW ambiental.v_clima_ubicacion AS
SELECT
    ma.ubicacion_id,
    u.latitud,
    u.longitud,
    DATE(ma.fecha_medicion) AS fecha,
    AVG(ma.temperatura_c)      AS temperatura_promedio,
    AVG(ma.humedad_pct)        AS humedad_promedio,
    SUM(ma.precipitacion_mm)   AS precipitacion_total,
    AVG(ma.radiacion_solar)    AS radiacion_promedio,
    AVG(ma.velocidad_viento)   AS viento_promedio
FROM ambiental.medicion_ambiental ma
JOIN geografico.ubicacion u
    ON u.id = ma.ubicacion_id
GROUP BY ma.ubicacion_id, u.latitud, u.longitud, DATE(ma.fecha_medicion);


-- Vista: índices de vegetación por parcela
CREATE VIEW ambiental.v_ndvi_parcela AS
SELECT
    iv.parcela_id,
    p.nombre            AS parcela,
    com.nombre          AS comunidad,
    mun.nombre          AS municipio,
    iv.fecha_calculo,
    iv.ndvi,
    iv.ndwi,
    iv.gndvi,
    iv.ndmi,
    iv.evi,
    iv.lai,
    iv.estado_vegetacion,
    iv.estres_hidrico,
    iv.estres_termico
FROM ambiental.indice_vegetacion iv
JOIN geografico.parcela p
    ON p.id = iv.parcela_id
LEFT JOIN catalogo.comunidad com
    ON com.id = p.comunidad_id
LEFT JOIN catalogo.municipio mun
    ON mun.id = com.municipio_id;


-- Vista: condiciones de suelo por parcela
CREATE VIEW ambiental.v_suelo_parcela AS
SELECT
    ce.parcela_id,
    p.nombre            AS parcela,
    com.nombre          AS comunidad,
    mun.nombre          AS municipio,
    ce.tipo_suelo,
    ce.textura,
    ce.ph,
    ce.materia_organica_pct,
    ce.nitrogeno_ppm,
    ce.fosforo_ppm,
    ce.potasio_ppm,
    ce.capacidad_campo_pct,
    ce.fecha_muestreo
FROM ambiental.condicion_edafica ce
JOIN geografico.parcela p
    ON p.id = ce.parcela_id
LEFT JOIN catalogo.comunidad com
    ON com.id = p.comunidad_id
LEFT JOIN catalogo.municipio mun
    ON mun.id = com.municipio_id;


-- Vista: amenazas socioambientales territoriales
CREATE VIEW ambiental.v_riesgo_ambiental AS
SELECT
    a.id,
    a.tipo,
    a.nivel_riesgo,
    a.fecha_deteccion,
    a.area_afectada_ha,
    a.esta_activa,
    com.nombre      AS comunidad,
    mun.nombre      AS municipio,
    a.descripcion
FROM ambiental.amenaza a
LEFT JOIN geografico.ubicacion u
    ON u.id = a.ubicacion_id
LEFT JOIN catalogo.comunidad com
    ON com.id = u.comunidad_id
LEFT JOIN catalogo.municipio mun
    ON mun.id = a.municipio_id;
