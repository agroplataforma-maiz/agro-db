-- ============================================================
-- ESQUEMA: ambiental
-- Mediciones climáticas, índices de vegetación,
-- amenazas socioambientales, estaciones meteorológicas
-- PostgreSQL/PostGIS
-- ============================================================

SET search_path TO ambiental, public;

-- ============================================================
-- 1. ESTACIÓN METEROLÓGICA
-- Estación meteorológica (física o virtual)
-- ============================================================

CREATE TABLE IF NOT EXISTS ambiental.estacion_meteorologica (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(200) NOT NULL,
    tipo            VARCHAR(30) NOT NULL CHECK (tipo IN ('fisica','virtual','satelital','API')),
    fuente_informacion_id INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    municipio_id    INTEGER REFERENCES catalogo.municipio(id) ON DELETE SET NULL ON UPDATE CASCADE,
    ubicacion_id    UUID REFERENCES core.ubicacion(id) ON DELETE SET NULL ON UPDATE CASCADE,   -- FK a geografico.ubicacion
    activa          BOOLEAN DEFAULT TRUE,
    fecha_instalacion DATE CHECK (fecha_instalacion IS NULL OR fecha_instalacion <= CURRENT_DATE),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_estacion_activa ON ambiental.estacion_meteorologica(activa);

-- ============================================================
-- 2. MEDICIÓN AMBIENTAL
-- Medición ambiental puntual
-- ============================================================
CREATE TABLE IF NOT EXISTS ambiental.medicion_ambiental (
    id                  SERIAL PRIMARY KEY,
    ubicacion_id        UUID REFERENCES core.ubicacion(id) ON DELETE SET NULL ON UPDATE CASCADE,   -- FK a geografico.ubicacion
    estacion_id         INTEGER REFERENCES ambiental.estacion_meteorologica(id) ON DELETE SET NULL ON UPDATE CASCADE,
    temperatura_c       DECIMAL(5,2) CHECK (temperatura_c BETWEEN -80 AND 60),
    humedad_pct         DECIMAL(5,2) CHECK (humedad_pct BETWEEN 0 AND 100),
    precipitacion_mm    DECIMAL(7,2) CHECK (precipitacion_mm >= 0),
    radiacion_solar     DECIMAL(8,2) CHECK (radiacion_solar >= 0),
    velocidad_viento    DECIMAL(6,2) CHECK (velocidad_viento >= 0),
    direccion_viento    DECIMAL(5,2) CHECK (direccion_viento >= 0 AND direccion_viento < 360),
    presion_atm_hpa     DECIMAL(7,2) CHECK (presion_atm_hpa BETWEEN 800 AND 1100),
    fecha_medicion      TIMESTAMP NOT NULL,
    fuente_informacion_id INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW(),
    CHECK (ubicacion_id IS NOT NULL OR estacion_id IS NOT NULL)
);

-- ============================================================
-- 3. INDICE VEGETACIÓN
-- Índice de vegetación por imagen satelital
-- Registra NDVI, NDWI, GNDVI calculados por parcela/punto
-- ============================================================
CREATE TABLE IF NOT EXISTS ambiental.indice_vegetacion (
    id              SERIAL PRIMARY KEY,
    imagen_id       INTEGER REFERENCES geo.imagen_satelital(id) ON DELETE CASCADE ON UPDATE CASCADE,   -- FK a geografico.imagen_satelital
    ubicacion_id    UUID REFERENCES core.ubicacion(id) ON DELETE SET NULL ON UPDATE CASCADE,   -- FK a geografico.ubicacion
    parcela_id      UUID REFERENCES core.parcela(id) ON DELETE SET NULL ON UPDATE CASCADE,   -- FK a geografico.parcela
    fecha_calculo   DATE NOT NULL,
    -- Índices principales
    ndvi            DECIMAL(6,4) CHECK (ndvi BETWEEN -1 AND 1),   -- Normalized Difference Vegetation Index (-1 a 1)
    ndwi            DECIMAL(6,4) CHECK (ndwi BETWEEN -1 AND 1),   -- Normalized Difference Water Index
    gndvi           DECIMAL(6,4) CHECK (gndvi BETWEEN -1 AND 1),   -- Green NDVI
    ndmi            DECIMAL(6,4) CHECK (ndmi BETWEEN -1 AND 1),   -- Normalized Difference Moisture Index
    evi             DECIMAL(6,4) CHECK (evi BETWEEN -1 AND 1),   -- Enhanced Vegetation Index
    lai             DECIMAL(6,4) CHECK (lai >= 0),   -- Leaf Area Index
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
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE geo.producto_dron
ADD CONSTRAINT fk_producto_dron_indice_vegetacion
FOREIGN KEY (indice_vegetacion_id)
REFERENCES ambiental.indice_vegetacion(id)
ON DELETE SET NULL
ON UPDATE CASCADE;

-- ============================================================
-- 4. SERIE NDVI
-- Serie temporal de NDVI por parcela (para análisis fenológico)
-- ============================================================
CREATE TABLE IF NOT EXISTS ambiental.serie_ndvi (
    id              SERIAL PRIMARY KEY,
    parcela_id      UUID NOT NULL REFERENCES core.parcela(id) ON DELETE CASCADE ON UPDATE CASCADE,   -- FK a geografico.parcela
    fecha           DATE NOT NULL,
    ndvi_promedio   DECIMAL(6,4) CHECK (ndvi_promedio BETWEEN -1 AND 1),
    ndvi_max        DECIMAL(6,4) CHECK (ndvi_max BETWEEN -1 AND 1),
    ndvi_min        DECIMAL(6,4) CHECK (ndvi_min BETWEEN -1 AND 1),
    ndvi_std        DECIMAL(6,4) CHECK (ndvi_std >= 0),
    nubosidad_pct   DECIMAL(5,2) CHECK (nubosidad_pct BETWEEN 0 AND 100),
    fuente          VARCHAR(50),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 5. CONDICION EDAFICA
-- Condición edáfica (tipo de suelo por parcela)
-- ============================================================
CREATE TABLE IF NOT EXISTS ambiental.condicion_edafica (
    id                  SERIAL PRIMARY KEY,
    parcela_id          UUID REFERENCES core.parcela(id) ON DELETE CASCADE ON UPDATE CASCADE,   -- FK a geografico.parcela
    -- Variables de suelo
    tipo_suelo          VARCHAR(100),
    textura             VARCHAR(50) CHECK (textura IN ('arcilloso','limoso','arenoso','franco','otro')),
    ph                  DECIMAL(4,2) CHECK (ph BETWEEN 0 AND 14),
    materia_organica_pct DECIMAL(5,2) CHECK (materia_organica_pct >= 0),
    nitrogeno_ppm       DECIMAL(8,2),
    fosforo_ppm         DECIMAL(8,2),
    potasio_ppm         DECIMAL(8,2),
    capacidad_campo_pct DECIMAL(5,2),
    -- Cuerpos de agua cercanos
    disponibilidad_agua VARCHAR(30) CHECK (disponibilidad_agua IN ('temporal','riego','mixto','escasa','no_disponible')),
    hay_fuente_agua_cercana BOOLEAN DEFAULT FALSE,
    distancia_fuente_agua_m DECIMAL(8,2) CHECK (distancia_fuente_agua_m >= 0),
    cobertura_vegetal       VARCHAR(20) CHECK (cobertura_vegetal IN ('menor_25','25_50','50_75','mayor_75')),
    cobertura_arborea       TEXT,
    condicion_humedad_suelo VARCHAR(20) CHECK (condicion_humedad_suelo IN ('seco','moderadamente','humedo','saturado')),
    presencia_erosion       VARCHAR(20) CHECK (presencia_erosion IN (    'ninguna','leve','moderada','severa')),
    pendiente_estimada_pct  DECIMAL(5,2) CHECK (pendiente_estimada_pct BETWEEN 0 AND 100),
    -- Fuente del dato
    fuente_informacion_id  INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha_muestreo      DATE,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 6. AMENAZA
-- Amenaza socioambiental detectada
-- ============================================================
CREATE TABLE IF NOT EXISTS ambiental.amenaza (
    id                  SERIAL PRIMARY KEY,
    tipo_amenaza_id     INTEGER REFERENCES catalogo.tipo_amenaza(id) ON DELETE SET NULL ON UPDATE CASCADE,   -- FK a catalogo.tipo_amenaza
    descripcion         TEXT,
    nivel_riesgo        VARCHAR(20) NOT NULL CHECK (nivel_riesgo IN ('bajo','medio','alto','critico')),
    presencia_transgenicos    BOOLEAN DEFAULT FALSE,
    distancia_transgenicos_m  DECIMAL(8,2) CHECK (distancia_transgenicos_m >= 0),
    riesgo_deforestacion      BOOLEAN DEFAULT FALSE,
    obs_amenazas_campo        TEXT,
    colindancias              TEXT,
    -- Fuente de detección
    fuente_deteccion    VARCHAR(50) CHECK (fuente_deteccion IN (
                            'imagen_satelital','vuelo_dron',
                            'entrevista_campo','reporte_institucional',
                            'modelo_ML','otro')),
    fecha_deteccion     DATE NOT NULL,
    municipio_id        INTEGER REFERENCES catalogo.municipio(id) ON DELETE SET NULL ON UPDATE CASCADE,   -- FK a catalogo.municipio
    ubicacion_id        UUID REFERENCES core.ubicacion(id) ON DELETE SET NULL ON UPDATE CASCADE,   -- FK a geografico.ubicacion
    area_afectada_ha    DECIMAL(12,4) CHECK (area_afectada_ha >= 0),
    poligono            GEOMETRY(MultiPolygon, 4326),
    esta_activa         BOOLEAN DEFAULT TRUE,
    acciones_propuestas TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);