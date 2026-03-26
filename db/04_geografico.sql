-- ============================================================
-- ESQUEMA: geografico
-- Ubicaciones, parcelas, capas SIG, imágenes satelitales,
-- vuelos de dron, productos de dron, zonas prioritarias

-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Versión: 1.0
-- ============================================================

SET search_path TO geografico, public;

-- ============================================================
-- 1. UBICACIÓN
--    Latitud, longitud, altitud y metadatos geoespaciales
--    Ubicación geoespacial con PostGIS
-- ============================================================

CREATE TABLE IF NOT EXISTS geografico.ubicacion (
    id                  SERIAL PRIMARY KEY,
    latitud             DECIMAL(10,7) NOT NULL CHECK (latitud BETWEEN -90 AND 90),
    longitud            DECIMAL(10,7) NOT NULL CHECK (longitud BETWEEN -180 AND 180),
    altitud_m           DECIMAL(8,2),
    comunidad_id        INTEGER REFERENCES catalogo.comunidad(id) ON DELETE SET NULL ON UPDATE CASCADE,
    tipo_suelo          VARCHAR(100),
    zona_agroecologica  VARCHAR(100),
    sistema_referencia  VARCHAR(20) DEFAULT 'WGS84',
    fuente_captura_id   INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    geom                GEOMETRY(Point, 4326) NOT NULL,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. PARCELA
--    Información geoespacial de las parcelas agrícolas
--    Polígono de la parcela, sistema de manejo, tenencia, topografía
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.parcela (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(150),
    superficie_ha   DECIMAL(8,4) CHECK (superficie_ha > 0),
    sistema_manejo_id  INTEGER REFERENCES catalogo.sistema_manejo(id) ON DELETE SET NULL ON UPDATE CASCADE,
    tenencia        VARCHAR(50) CHECK (tenencia IN ('ejidal','privada','comunal','rentada','prestada','desconocida')),
    topografia      VARCHAR(30) CHECK (topografia IN ('plana','ondulada','ladera','terraza','barranco')),
    productor_id    INTEGER NOT NULL REFERENCES social.productor(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    ubicacion_id    INTEGER REFERENCES geografico.ubicacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    poligono        GEOMETRY(Polygon, 4326) NOT NULL,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);


-- ============================================================
--    3. HISTORIAL DE USO DE LA PARCELA
--    Cultivos anteriores, uso de fertilizantes, continuidad de maíz nativo
-- ============================================================

CREATE TABLE IF NOT EXISTS geografico.historial_parcela (
    id                      SERIAL PRIMARY KEY,
    parcela_id              INTEGER REFERENCES geografico.parcela(id) ON DELETE CASCADE,

    -- Tiempo de uso
    anios_cultivando         SMALLINT CHECK (anios_cultivando BETWEEN 0 AND 100),

    -- Continuidad de maíz nativo
    siempre_maiz_nativo     BOOLEAN DEFAULT FALSE,
    cultivos_anteriores     TEXT,   -- texto libre del productor

    -- Historial de fertilizantes
    uso_fertilizantes_hist   BOOLEAN DEFAULT FALSE,
    detalle_fertilizantes    TEXT,   -- qué productos, con qué frecuencia

    -- Metadatos
    fecha_registro          DATE DEFAULT CURRENT_DATE,
    registrado_por          VARCHAR(150),
    fuente_informacion_id   INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 4. IMAGEN SATELITAL
--    Registro de imágenes satelitales descargadas para la región
--    Fuente, fecha, resolución, cobertura, estadísticas básicas
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.imagen_satelital (
    id                  SERIAL PRIMARY KEY,
    fuente_informacion_id   INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha_captura       DATE NOT NULL,
    fecha_descarga      DATE DEFAULT CURRENT_DATE,
    resolucion_m        DECIMAL(6,2),
    bandas              VARCHAR(200),
    nubosidad_pct       DECIMAL(5,2),
    ruta_archivo        VARCHAR(500),
    extent_geom         GEOMETRY(Polygon, 4326),
    plataforma          VARCHAR(100),
    notas               TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);


-- ============================================================
-- 5. VUELO DE DRON (evento operativo)
--    Registro de vuelos de dron realizados para monitoreo de parcelas
--    Fecha, piloto, modelo de dron, tipo de sensor, área cubierta, resolución
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.vuelo_dron (
    id                  SERIAL PRIMARY KEY,
    fecha_vuelo         DATE NOT NULL,
    piloto              VARCHAR(150),
    modelo_dron         VARCHAR(100),        -- ej. DJI Mavic 3 Multispectral
    tipo_sensor         VARCHAR(50) CHECK (tipo_sensor IN ('RGB','multiespectral','termal','LiDAR')) NOT NULL,
    altitud_vuelo_m     DECIMAL(7,2),
    solapamiento_pct    DECIMAL(5,2),
    area_cubierta_ha    DECIMAL(10,4),
    resolucion_cm_px    DECIMAL(6,2),
    num_imagenes        INTEGER CHECK (num_imagenes > 0),             -- total de fotos capturadas en el vuelo
    software_vuelo      VARCHAR(100),        -- ej. DJI Pilot 2, Pix4Dcapture
    condiciones_clima   TEXT,
    parcela_id          INTEGER REFERENCES geografico.parcela(id) ON DELETE SET NULL ON UPDATE CASCADE,
    area_vuelo          GEOMETRY(Polygon, 4326) NOT NULL,
    notas               TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);


-- ============================================================
-- 6. PRODUCTO PROCESADO DEL VUELO DE DRON
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
--                           geografico.zona_prioritaria
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.producto_dron (
    id                      SERIAL PRIMARY KEY,
    vuelo_id                INTEGER NOT NULL REFERENCES geografico.vuelo_dron(id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Tipo de producto
    tipo_producto_dron_id   INTEGER REFERENCES catalogo.tipo_producto_dron(id) ON DELETE SET NULL ON UPDATE CASCADE NOT NULL,

    -- Archivo generado
    ruta_archivo            VARCHAR(500) NOT NULL,
    formato_archivo_id      INTEGER REFERENCES catalogo.formato_archivo(id) ON DELETE SET NULL ON UPDATE CASCADE NOT NULL,
    tamanio_mb              DECIMAL(10,2) CHECK (tamanio_mb > 0),
    resolucion_cm_px        DECIMAL(6,2) CHECK (resolucion_cm_px > 0),
    sistema_referencia      VARCHAR(30) DEFAULT 'WGS84 / UTM Zone 14N',

    -- Estadísticas del producto (especialmente útil para índices)
    valor_promedio          DECIMAL(8,4),
    valor_maximo            DECIMAL(8,4),
    valor_minimo            DECIMAL(8,4),
    desviacion_std          DECIMAL(8,4),

    -- Cobertura geográfica del producto
    extent_geom             GEOMETRY(Polygon, 4326),

    -- Procesamiento
    software_procesamiento  VARCHAR(100),   -- ej. Pix4D Fields, Agisoft, OpenDroneMap
    version_software        VARCHAR(30),
    fecha_procesamiento     DATE DEFAULT CURRENT_DATE,
    parametros_procesamiento TEXT,
    validado                BOOLEAN DEFAULT FALSE,
    validado_por            VARCHAR(150),

    -- Vínculo con ambiental.indice_vegetacion
    -- Se llena cuando este producto alimenta el análisis ambiental
    indice_vegetacion_id    INTEGER, -- FK a ambiental.indice_vegetacion


    notas                   TEXT,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW(),
    UNIQUE (vuelo_id, tipo_producto_dron_id, ruta_archivo)
);

-- ============================================================
-- 7. CAPAS SIG TEMÁTICAS
--    Capas de uso de suelo, cobertura vegetal, zonas prioritarias,
--    hidrología, edafología, etc. para análisis espacial y superposición
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.capa_sig (
    id                  SERIAL PRIMARY KEY,
    nombre              VARCHAR(200) NOT NULL,
    tipo_capa_sig_id    INTEGER REFERENCES catalogo.tipo_capa_sig(id) ON DELETE SET NULL ON UPDATE CASCADE,
    fuente_informacion_id   INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha_fuente        DATE,
    formato_archivo_id   INTEGER REFERENCES catalogo.formato_archivo(id) ON DELETE SET NULL ON UPDATE CASCADE,
    ruta_archivo        VARCHAR(500),
    url_descarga        TEXT,
    descripcion         TEXT,
    anio_referencia      SMALLINT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 8. ZONA PRIORITARIA DE CONSERVACIÓN
--    Polígonos de zonas prioritarias para conservación de maíz nativo
--    Criterios: riqueza genética, presión humana, riesgo de desaparición,
--              valor cultural, valor nutricional
-- Zona prioritaria de conservación (se llena en Etapa 2)
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.zona_prioritaria (
    id                          SERIAL PRIMARY KEY,
    nombre                      VARCHAR(200),
    nivel_prioridad             VARCHAR(20) CHECK (nivel_prioridad IN ('muy_alta','alta','media','baja')),
    criterio_riqueza_genetica   DECIMAL(5,2) CHECK (criterio_riqueza_genetica BETWEEN 0 AND 100), 
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
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 9. CAMBIO DE USO DE SUELO (multitemporal)
--    Polígonos de cambio de uso de suelo entre dos años
--    Clases de uso de suelo inicial y final, superficie afectada
--    Fuente de datos (imágenes satelitales, estudios previos, etc.)
--    Vínculo con municipio para análisis espacial
--    Este análisis se puede realizar a nivel regional o por parcela
--    dependiendo de la disponibilidad de datos y la escala de análisis
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.cambio_uso_suelo (
    id              SERIAL PRIMARY KEY,
    anio_inicial     SMALLINT NOT NULL,
    anio_final       SMALLINT NOT NULL CHECK (anio_final - anio_inicial <= 50),
    clase_inicial   INTEGER REFERENCES catalogo.clase_uso_suelo(id) ON DELETE SET NULL ON UPDATE CASCADE,
    clase_final     INTEGER REFERENCES catalogo.clase_uso_suelo(id) ON DELETE SET NULL ON UPDATE CASCADE,
    superficie_ha   DECIMAL(12,4),
    fuente_informacion_id   INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    municipio_id    INTEGER REFERENCES catalogo.municipio(id) ON DELETE SET NULL ON UPDATE CASCADE,
    poligono        GEOMETRY(MultiPolygon, 4326),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 10. VISITA DE CAMPO
--     Registro de visitas de campo para validación de datos geoespaciales
--     Fecha, responsable, equipo, número de productores y muestras,
--     condiciones del campo, observaciones generales
--     Vínculo con localidad y municipio para análisis espacial
--     Este registro se puede vincular con observaciones ambientales y medios de parcela para enriquecer el análisis de campo
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.visita_campo (
    id                  SERIAL PRIMARY KEY,
    fecha_visita        DATE NOT NULL,
    localidad_id        INTEGER REFERENCES catalogo.localidad(id) ON DELETE SET NULL ON UPDATE CASCADE,
    responsable_visita  VARCHAR(150),
    equipo              TEXT,
    num_productores     SMALLINT,
    num_muestras        SMALLINT,
    punto_inicio        GEOMETRY(Point, 4326),
    condiciones_campo   TEXT,
    observaciones       TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
--  11. OBSERVACIÓN AMBIENTAL EN CAMPO
--    Mediciones directas del encuestador durante la visita F2:
--    textura de suelo, humedad, erosión, cobertura, pendiente.
--    Complementa ambiental.condicion_edafica (que recibe datos
--    de laboratorio/sensores) con observaciones cualitativas.
-- ============================================================

CREATE TABLE IF NOT EXISTS geografico.observacion_campo (
    id                      SERIAL PRIMARY KEY,
    parcela_id              INTEGER REFERENCES geografico.parcela(id) NOT NULL,
    ubicacion_id            INTEGER REFERENCES geografico.ubicacion(id),

    -- Observaciones de suelo (táctiles/visuales)
    textura_suelo           VARCHAR(20) CHECK (textura_suelo IN (
                                'arcilloso','limoso','arenoso','franco','no_evaluado'
                            )),
    condicion_humedad       VARCHAR(20) CHECK (condicion_humedad IN (
                                'seco','medio','humedo','saturado'
                            )),
    presencia_erosion       VARCHAR(20) CHECK (presencia_erosion IN (
                                'ninguna','leve','moderada','severa'
                            )),
    pendiente_estimada_pct  DECIMAL(5,2) CHECK (pendiente_estimada_pct BETWEEN 0 AND 100),

    -- Cobertura
    cobertura_vegetal_pct   DECIMAL(5,2) CHECK (cobertura_vegetal_pct BETWEEN 0 AND 100),
    cobertura_arborea       TEXT,   -- valores múltiples desde select_multiple

    -- Agua
    hay_fuente_agua_cercana BOOLEAN DEFAULT FALSE,
    distancia_fuente_agua_m DECIMAL(8,2),

    -- Notas libres del encuestador
    notas_campo             TEXT,

    -- Metadatos
    fecha_visita            DATE DEFAULT CURRENT_DATE,
    registrado_por          VARCHAR(150),
    fuente_captura_id       INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    uuid_envio              VARCHAR(100) UNIQUE,   -- _uuid del envío Kobo
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);


-- ============================================================
-- 12. MEDIO PARCELA
--    Fotos de parcela, entorno y suelo capturadas en F2.
--    Diseño análogo a cultural.medio_cultural.
-- ============================================================
CREATE TABLE IF NOT EXISTS geografico.medio_parcela (
    id                  SERIAL PRIMARY KEY,
    parcela_id          INTEGER REFERENCES geografico.parcela(id) NOT NULL,
    ubicacion_id        INTEGER REFERENCES geografico.ubicacion(id),

    -- Tipo de foto
    tipo_medio          VARCHAR(20) NOT NULL CHECK (tipo_medio IN (
                            'foto','video'
                        )),
    subtipo             VARCHAR(40) CHECK (subtipo IN (
                            'parcela_general',
                            'entorno_colindancias',
                            'suelo',
                            'cultivo',
                            'amenaza',
                            'otro'
                        )),

    -- Archivo
    nombre_archivo      VARCHAR(300) NOT NULL,
    -- Ruta: <base>/<form_id>/<uuid_envio>/<nombre_archivo>
    campo_origen        VARCHAR(100),   -- ej. foto_parcela_general, foto_suelo
    descripcion         TEXT,

    -- Metadatos técnicos
    peso_kb             INTEGER,
    resolucion          VARCHAR(30),
    formato             VARCHAR(10),    -- jpg, png, mp4

    -- Trazabilidad
    uuid_envio          VARCHAR(100),
    fuente_informacion_id   INTEGER REFERENCES catalogo.fuente_informacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha_captura       DATE DEFAULT CURRENT_DATE,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);
