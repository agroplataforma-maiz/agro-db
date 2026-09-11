-- ============================================================
-- ESQUEMA: geo
-- Ubicaciones, parcelas, capas SIG, imágenes satelitales,
-- vuelos de dron, productos de dron, zonas prioritarias
-- PostgreSQL/PostGIS

-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Versión: 1.0
-- ============================================================

SET search_path TO geo, public;


-- ============================================================
--  1. HISTORIAL DE USO DE LA PARCELA
--  Cultivos anteriores, uso de fertilizantes, continuidad de maíz nativo
-- ============================================================

CREATE TABLE IF NOT EXISTS geo.historial_parcela (
    id                      SERIAL PRIMARY KEY,
    parcela_id              UUID REFERENCES core.parcela(id) 
                            ON DELETE CASCADE,
    -- Tiempo de uso
    anios_cultivando        SMALLINT,
    -- Continuidad de maíz nativo
    siempre_maiz_nativo     BOOLEAN DEFAULT FALSE,
    cultivos_anteriores     TEXT,   -- texto libre del productor
    -- Historial de fertilizantes
    uso_fertilizantes_hist  BOOLEAN DEFAULT FALSE,
    detalle_fertilizantes   TEXT,   -- qué productos, con qué frecuencia
    -- Metadatos
    registrado_por          UUID REFERENCES sistema.usuario(id) 
                            ON DELETE SET NULL 
                            ON UPDATE CASCADE,
    fuente_id               INTEGER REFERENCES trazabilidad.fuente(id) 
                            ON DELETE SET NULL 
                            ON UPDATE CASCADE,
    fecha_registro          DATE DEFAULT CURRENT_DATE,
    creado_en               TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (anios_cultivando BETWEEN 0 AND 100)
);

CREATE INDEX IF NOT EXISTS idx_historial_parcela ON geo.historial_parcela(parcela_id);

-- ============================================================
-- 2. IMAGEN SATELITAL
--    Registro de imágenes satelitales descargadas para la región
--    Fuente, fecha, resolución, cobertura, estadísticas básicas
-- ============================================================
CREATE TABLE IF NOT EXISTS geo.imagen_satelital (
    id                  SERIAL PRIMARY KEY,
    fuente_id           INTEGER REFERENCES trazabilidad.fuente(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    fecha_captura       DATE NOT NULL,
    fecha_descarga      DATE DEFAULT CURRENT_DATE,
    resolucion_m        DECIMAL(6,2),
    bandas              VARCHAR(200),
    nubosidad_pct       DECIMAL(5,2),
    ruta_archivo        VARCHAR(500),
    ruta_almacenamiento VARCHAR(500), -- ruta física o lógica en almacenamiento
    extent_geom         GEOMETRY(Polygon, 4326),
    plataforma          VARCHAR(100),
    sensor              VARCHAR(100), -- tipo de sensor (ej. Sentinel-2 MSI)
    proveedor           VARCHAR(100), -- proveedor de la imagen (ej. Copernicus, Planet)
    epsg                INTEGER,      -- código EPSG del sistema de referencia
    uuid_externo        VARCHAR(100), -- identificador externo si aplica
    registrado_por      UUID REFERENCES sistema.usuario(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    notas               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_imagen_satelital_geom ON geo.imagen_satelital USING GIST (extent_geom);

-- ============================================================
-- 3. VUELO DE DRON (evento operativo)
--    Registro de vuelos de dron realizados para monitoreo de parcelas
--    Fecha, piloto, modelo de dron, tipo de sensor, área cubierta, resolución
-- ============================================================
CREATE TABLE IF NOT EXISTS geo.vuelo_dron (
    id                  SERIAL PRIMARY KEY,
    fecha_vuelo         DATE NOT NULL,
    piloto              VARCHAR(150),
    modelo_dron         VARCHAR(100),        -- ej. DJI Mavic 3 Multispectral
    tipo_sensor         VARCHAR(50) NOT NULL,
    altitud_vuelo_m     DECIMAL(7,2),
    solapamiento_pct    DECIMAL(5,2),
    area_cubierta_ha    DECIMAL(10,4),
    resolucion_cm_px    DECIMAL(6,2),
    num_imagenes        INTEGER,             -- total de fotos capturadas en el vuelo
    software_vuelo      VARCHAR(100),        -- ej. DJI Pilot 2, Pix4Dcapture
    condiciones_clima   TEXT,
    parcela_id          UUID REFERENCES core.parcela(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    area_vuelo          GEOMETRY(Polygon, 4326) NOT NULL,
    notas               TEXT,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now(),

    CHECK (tipo_sensor IN ('RGB','multiespectral','termal','LiDAR')),
    CHECK (num_imagenes > 0)
);

CREATE INDEX IF NOT EXISTS idx_vuelo_dron_geom ON geo.vuelo_dron USING GIST (area_vuelo);

-- ============================================================
-- 4. PRODUCTO PROCESADO DEL VUELO DE DRON
--    Ortomosaicos, DEM, bandas individuales, índices de vegetación
--    Vínculo con ambiental.indice_vegetacion para análisis posteriores
--    Cada vuelo genera múltiples productos: 
--                      ortomosaicos, DEM, bandas individuales e índices
--
-- Flujo completo:
-- vuelo_dron → producto_dron → ambiental.indice_vegetacion
--                                      ↓
--                              ambiental.serie_ndvi
--                                      ↓
--                           geo.zona_prioritaria
-- ============================================================
CREATE TABLE IF NOT EXISTS geo.producto_dron (
    id                  SERIAL PRIMARY KEY,
    vuelo_id            INTEGER NOT NULL REFERENCES 
                        geo.vuelo_dron(id)                
                        ON DELETE CASCADE 
                        ON UPDATE CASCADE,
    -- Tipo de producto
    tipo_producto_id    INTEGER REFERENCES trazabilidad.tipo_producto_dron(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE NOT NULL,
    -- Archivo generado
    ruta_almacenamiento VARCHAR(500) NOT NULL,
    formato_archivo_id  INTEGER REFERENCES trazabilidad.formato_archivo(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE NOT NULL,
    tamanio_mb          DECIMAL(10,2),
    resolucion_cm_px    DECIMAL(6,2),
    sistema_referencia  VARCHAR(30) DEFAULT 'WGS84 / UTM Zone 14N',
    -- Estadísticas del producto (especialmente útil para índices)
    valor_promedio      DECIMAL(8,4),
    valor_maximo        DECIMAL(8,4),
    valor_minimo        DECIMAL(8,4),
    desviacion_std      DECIMAL(8,4),
    -- Cobertura geográfica del producto
    extent_geom         GEOMETRY(Polygon, 4326),
    -- Procesamiento
    software_procesamiento VARCHAR(100),   -- ej. Pix4D Fields, Agisoft, OpenDroneMap
    version_software     VARCHAR(30),
    fecha_procesamiento  DATE DEFAULT CURRENT_DATE,
    parametros_procesamiento TEXT,
    validado             BOOLEAN DEFAULT FALSE,
    validado_por         VARCHAR(150),
    -- Vínculo con ambiental.indice_vegetacion
    -- Se llena cuando este producto alimenta el análisis ambiental
    indice_vegetacion_id INTEGER, -- FK a ambiental.indice_vegetacion
    notas                TEXT,
    creado_en            TIMESTAMPTZ DEFAULT now(),
    actualizado_en       TIMESTAMPTZ DEFAULT now(),

    CHECK (tamanio_mb > 0),
    CHECK (resolucion_cm_px > 0),
    UNIQUE (vuelo_id, tipo_producto_id, ruta_almacenamiento)
);

CREATE INDEX IF NOT EXISTS idx_producto_dron_extent ON geo.producto_dron USING GIST (extent_geom);

-- ============================================================
-- 7. CAPAS SIG TEMÁTICAS
--    Capas de uso de suelo, cobertura vegetal, zonas prioritarias,
--    hidrología, edafología, etc. para análisis espacial y superposición
-- ============================================================
CREATE TABLE IF NOT EXISTS geo.capa_sig (
    id                   SERIAL PRIMARY KEY,
    nombre               VARCHAR(200) NOT NULL,
    tipo_capa_sig_id     INTEGER REFERENCES trazabilidad.tipo_capa_sig(id) 
                         ON DELETE SET NULL 
                         ON UPDATE CASCADE,
    fuente_id            INTEGER REFERENCES trazabilidad.fuente(id) 
                         ON DELETE SET NULL 
                         ON UPDATE CASCADE,
    fecha_fuente         DATE,
    formato_archivo_id   INTEGER REFERENCES trazabilidad.formato_archivo(id) 
                         ON DELETE SET NULL 
                         ON UPDATE CASCADE,
    ruta_almacenamiento  VARCHAR(500),
    url_descarga         TEXT,
    descripcion          TEXT,
    anio_referencia      SMALLINT,
    creado_en            TIMESTAMPTZ DEFAULT now(),
    actualizado_en       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_capa_sig_nombre ON geo.capa_sig(nombre);

-- ============================================================
-- 8. ZONA PRIORITARIA DE CONSERVACIÓN
--    Polígonos de zonas prioritarias para conservación de maíz nativo
--    Criterios: riqueza genética, presión humana, riesgo de desaparición,
--              valor cultural, valor nutricional
-- Zona prioritaria de conservación (se llena en Etapa 2)
-- ============================================================
CREATE TABLE IF NOT EXISTS geo.zona_prioritaria (
    id                          SERIAL PRIMARY KEY,
    nombre                      VARCHAR(200),
    nivel_prioridad             VARCHAR(20),
    criterio_riqueza_genetica   DECIMAL(5,2), 
    criterio_presion_humana     DECIMAL(5,2),
    criterio_riesgo_desaparicion DECIMAL(5,2),
    criterio_valor_cultural     DECIMAL(5,2),
    criterio_valor_nutricional  DECIMAL(5,2),
    score_total                 DECIMAL(5,2) GENERATED ALWAYS AS (
                                    (COALESCE(criterio_riqueza_genetica,0) +
                                     COALESCE(criterio_presion_humana,0) +
                                     COALESCE(criterio_riesgo_desaparicion,0) +
                                     COALESCE(criterio_valor_cultural,0) +
                                     COALESCE(criterio_valor_nutricional,0)) / 5
                                ) STORED,
    municipios_incluidos        TEXT,
    num_productores             SMALLINT,
    num_germoplasmas            SMALLINT,
    poligono                    GEOMETRY(MultiPolygon, 4326),
    metodologia                 TEXT,
    fecha_calculo               DATE,
    version                     VARCHAR(20) DEFAULT '1.0',
    creado_en                   TIMESTAMPTZ DEFAULT now(),
    actualizado_en              TIMESTAMPTZ DEFAULT now(),

    CHECK (nivel_prioridad IN ('muy_alta','alta','media','baja')),
    CHECK (criterio_riqueza_genetica BETWEEN 0 AND 100)
);

CREATE INDEX IF NOT EXISTS idx_zona_prioritaria_geom ON geo.zona_prioritaria USING GIST (poligono);

-- ============================================================
-- 9. CAMBIO DE USO DE SUELO (multitemporal)
--    Polígonos de cambio de uso de suelo entre dos años
--    Clases de uso de suelo inicial y final, superficie afectada
--    Fuente de datos (imágenes satelitales, estudios previos, etc.)
--    Vínculo con municipio para análisis espacial
--    Este análisis se puede realizar a nivel regional o por parcela
--    dependiendo de la disponibilidad de datos y la escala de análisis
-- ============================================================
CREATE TABLE IF NOT EXISTS geo.cambio_uso_suelo (
    id              SERIAL PRIMARY KEY,
    anio_inicial    SMALLINT NOT NULL,
    anio_final      SMALLINT NOT NULL,
    clase_inicial   INTEGER REFERENCES catalogo.clase_uso_suelo(id) 
                    ON DELETE SET NULL 
                    ON UPDATE CASCADE,
    clase_final     INTEGER REFERENCES 
                    catalogo.clase_uso_suelo(id)                       
                    ON DELETE SET NULL 
                    ON UPDATE CASCADE,
    superficie_ha   DECIMAL(12,4),
    fuente_id       INTEGER REFERENCES trazabilidad.fuente(id) 
                    ON DELETE SET NULL 
                    ON UPDATE CASCADE,
    municipio_id    INTEGER REFERENCES catalogo.municipio(id) 
                    ON DELETE SET NULL 
                    ON UPDATE CASCADE,
    poligono        GEOMETRY(MultiPolygon, 4326),
    creado_en       TIMESTAMPTZ DEFAULT now(),
    actualizado_en  TIMESTAMPTZ DEFAULT now(),

    CHECK (anio_final - anio_inicial <= 50),
    CHECK (superficie_ha >= 0)
);

CREATE INDEX IF NOT EXISTS idx_cambio_uso_suelo_geom ON geo.cambio_uso_suelo USING GIST (poligono);
CREATE INDEX IF NOT EXISTS idx_cambio_uso_suelo_municipio ON geo.cambio_uso_suelo(municipio_id);
CREATE INDEX IF NOT EXISTS idx_cambio_uso_suelo_clase_inicial ON geo.cambio_uso_suelo(clase_inicial);
CREATE INDEX IF NOT EXISTS idx_cambio_uso_suelo_clase_final ON geo.cambio_uso_suelo(clase_final);

-- ============================================================
-- 10. VISITA DE CAMPO
--     Registro de visitas de campo para validación de datos geoespaciales
--     Fecha, responsable, equipo, número de productores y muestras,
--     condiciones del campo, observaciones generales
--     Vínculo con localidad y municipio para análisis espacial
--     Este registro se puede vincular con observaciones ambientales y medios de parcela para enriquecer el análisis de campo
-- ============================================================
CREATE TABLE IF NOT EXISTS geo.visita_campo (
    id                  SERIAL PRIMARY KEY,
    fecha_visita        DATE NOT NULL,
    comunidad_id        UUID REFERENCES core.comunidad(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    responsable_visita  UUID REFERENCES sistema.usuario(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    equipo              TEXT,
    num_productores     SMALLINT,
    num_muestras        SMALLINT,
    punto_inicio        GEOMETRY(Point, 4326),
    condiciones_campo   TEXT,
    observaciones       TEXT,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_visita_campo_punto ON geo.visita_campo USING GIST (punto_inicio);
CREATE INDEX IF NOT EXISTS idx_visita_campo_comunidad ON geo.visita_campo(comunidad_id);

-- ============================================================
--  11. OBSERVACIÓN AMBIENTAL EN CAMPO
--    Mediciones directas del encuestador durante la visita F2:
--    textura de suelo, humedad, erosión, cobertura, pendiente.
--    Complementa ambiental.condicion_edafica (que recibe datos
--    de laboratorio/sensores) con observaciones cualitativas.
-- ============================================================

CREATE TABLE IF NOT EXISTS geo.observacion_campo (
    id                  SERIAL PRIMARY KEY,
    parcela_id          UUID REFERENCES core.parcela(id) ON DELETE CASCADE ON UPDATE CASCADE,
    ubicacion_id        UUID REFERENCES core.ubicacion(id)ON DELETE SET NULL ON UPDATE CASCADE,
    -- Observaciones de suelo (táctiles/visuales)
    textura_suelo       VARCHAR(20),
    condicion_humedad   VARCHAR(20),
    presencia_erosion   VARCHAR(20),
    pendiente_estimada_pct  DECIMAL(5,2),
    -- Cobertura
    cobertura_vegetal_pct   DECIMAL(5,2),
    cobertura_arborea       TEXT,   -- valores múltiples desde select_multiple
    -- Agua
    hay_fuente_agua_cercana BOOLEAN DEFAULT FALSE,
    distancia_fuente_agua_m DECIMAL(8,2),
    -- Notas libres del encuestador
    notas_campo             TEXT,
    -- Metadatos
    fecha_visita            DATE DEFAULT CURRENT_DATE,
    registrado_por          UUID REFERENCES sistema.usuario(id) 
                            ON DELETE SET NULL 
                            ON UPDATE CASCADE,
    fuente_id               INTEGER REFERENCES trazabilidad.fuente(id) 
                            ON DELETE SET NULL 
                            ON UPDATE CASCADE,
    creado_en               TIMESTAMPTZ DEFAULT now(),
    actualizado_en          TIMESTAMPTZ DEFAULT now(),

    CHECK (textura_suelo IN (
        'arcilloso','limoso','arenoso','franco','no_evaluado'
    )),
    CHECK (condicion_humedad IN (
        'seco','medio','humedo','saturado'
    )),
    CHECK (presencia_erosion IN (
        'ninguna','leve','moderada','severa'
    )),
    CHECK (pendiente_estimada_pct BETWEEN 0 AND 100),
    CHECK (cobertura_vegetal_pct BETWEEN 0 AND 100)
);

CREATE INDEX IF NOT EXISTS idx_obs_campo_parcela   ON geo.observacion_campo(parcela_id);
CREATE INDEX IF NOT EXISTS idx_obs_campo_ubicacion ON geo.observacion_campo(ubicacion_id);