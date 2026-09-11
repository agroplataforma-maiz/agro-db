-- ============================================================
-- ESQUEMA: catalogo
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Versión: 1.0
--PostgreSQL
--
-- EJECUTAR ANTES de todos los demás esquemas
-- ya que social.*, geografico.* y agronomico.*
-- referencian este catálogo.
--
-- Fuentes:
--   - Marco Geoestadístico Nacional INEGI 2024
--   - Catálogo de Localidades INEGI 2020
--   - INPI Atlas de Pueblos Indígenas 2020
--
-- ORGANIZACIÓN CONCEPTUAL POR EJES DEL SISTEMA
--
-- EJE 1: Germoplasma
-- EJE 2: Agronómico
-- EJE 3: Territorial: Jerarquía: Municipio -> Comunidad -> Localidad -> Colonia
-- EJE 4: Ambiental
-- EJE 5: Social
-- EJE 6: Trazabilidad
--
-- Este esquema soporta análisis multivariado agroecológico
-- y sistemas IoT / Edge–Fog–Cloud
-- ============================================================

SET search_path TO catalogo, public;

-- ============================================================
-- EJE CENTRAL: GERMOPLASMA DE MAÍZ NATIVO
-- ============================================================

-- ============================================================
-- 1. CATALOGO: razas de maíz
-- Catálogo de razas de maíz presentes en la Huasteca Potosina
-- Basado en clasificaciones académicas y etnobotánicas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.raza_maiz (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL, -- código corto para referencia (ej. TUX, OLO, CON)
    nombre          VARCHAR(100) NOT NULL UNIQUE,  -- ej. Tuxpeño, Olotillo, Cónico
    descripcion     TEXT,
    region_origen   VARCHAR(150),
    tipo_ciclo      VARCHAR(50),
    es_nativa       BOOLEAN DEFAULT TRUE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z0-9_]{3,20}$'),
    CHECK (tipo_ciclo IN ('precoz','intermedio','tardio'))
);

CREATE INDEX idx_raza_maiz_nombre ON catalogo.raza_maiz(nombre);

-- ============================================================
-- 2. CATALOGO: colores de grano
-- Catálogo de colores de grano presentes en las razas de maíz de la Huasteca Potosina
-- Basado en clasificaciones académicas y etnobotánicas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.color_grano (
    id          SERIAL PRIMARY KEY,
    codigo      VARCHAR(20) UNIQUE NOT NULL,
    nombre      VARCHAR(50) NOT NULL UNIQUE,  -- blanco, amarillo, azul, rojo, negro
    descripcion TEXT,
    es_nativo   BOOLEAN DEFAULT TRUE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_color_grano_nombre ON catalogo.color_grano(nombre);

-- ============================================================
-- 3. CATALOGO: estado de conservación
-- Catálogo para clasificar el estado de conservación de las razas de maíz
-- Basado en criterios de riesgo de extinción local
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.estado_conservacion (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(50) UNIQUE NOT NULL,  -- activo, en_riesgo, extinto_local
    descripcion     TEXT,
    nivel_riesgo    SMALLINT,               -- 1–5
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (nivel_riesgo BETWEEN 1 AND 5)
);

CREATE INDEX idx_estado_conservacion_riesgo ON catalogo.estado_conservacion(nivel_riesgo);

-- ============================================================
-- 4. CATALOGO: clases de uso de maíz
-- Catálogo para clasificar los usos tradicionales y contemporáneos del maíz en la Huasteca Potosina
-- Basado en categorías comunes de uso del maíz
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.uso_maiz (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(100) UNIQUE NOT NULL, -- tortilla, elote, forraje
    descripcion     TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_uso_maiz_nombre ON catalogo.uso_maiz(nombre);

-- ============================================================
-- 5. CATALOGO: origen de la semilla
-- Catálogo para identificar el origen de la semilla de maíz
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.origen_semilla (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(30) UNIQUE NOT NULL,
    nombre          VARCHAR(100) UNIQUE NOT NULL,
    descripcion     TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z0-9_]+$')
);

CREATE INDEX idx_origen_semilla_nombre
    ON catalogo.origen_semilla(nombre);

INSERT INTO catalogo.origen_semilla
    (codigo, nombre, descripcion)
VALUES
    ('PROPIA', 'Semilla propia',
        'Semilla conservada y seleccionada por el propio productor.'),
    ('INTERCAMBIO', 'Intercambio comunitario',
        'Semilla obtenida mediante intercambio con otro productor o miembro de la comunidad.'),
    ('COMPRA', 'Compra',
        'Semilla adquirida mediante compra.'),
    ('FAMILIAR', 'Herencia familiar',
        'Semilla recibida o heredada de familiares.'),
    ('COMUNIDAD', 'Origen comunitario',
        'Semilla obtenida dentro de la comunidad.'),
    ('BANCO', 'Banco de germoplasma',
        'Semilla procedente de un banco o colección de germoplasma.'),
    ('OTRO', 'Otro',
        'Otro origen no especificado.')
ON CONFLICT (codigo) DO NOTHING;

-- ============================================================
-- EJE AGRONÓMICO (MANEJO Y PRODUCCIÓN)
-- ============================================================

-- ============================================================
-- 5. CATALOGO: tipos de práctica agrícola
-- Catálogo para clasificar las prácticas agrícolas asociadas a los productores y muestras de germoplasma
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_practica (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(50) UNIQUE NOT NULL, -- tradicional, agroecologica, etc.
    descripcion     TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_tipo_practica_nombre ON catalogo.tipo_practica(nombre);

-- =============================================================
-- 6. Catalogo: prácticas agrícolas
-- Catálogo para clasificar las prácticas agrícolas asociadas a los productores y muestras de germoplasma
-- Basado en categorías comunes de manejo agrícola
-- =============================================================
CREATE TABLE IF NOT EXISTS catalogo.practica_agricola (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(150) NOT NULL,
    descripcion     TEXT,
    tipo_id         INTEGER REFERENCES catalogo.tipo_practica(id) 
                    ON DELETE SET NULL 
                    ON UPDATE CASCADE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_practica_agricola_tipo ON catalogo.practica_agricola(tipo_id);

-- ============================================================
-- 7. CATALOGO: sistema de manejo
-- Catálogo para clasificar el sistema de manejo agrícola asociado a las muestras de germoplasma
-- Basado en categorías comunes de prácticas agrícolas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.sistema_manejo (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(100) UNIQUE NOT NULL,  -- tradicional, mecanizado, agroecologico
    descripcion     TEXT,
    es_tradicional  BOOLEAN NULL DEFAULT FALSE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_sistema_manejo_tradicional ON catalogo.sistema_manejo(es_tradicional);

-- ============================================================
-- 8. CATALOGO: sistema de cultivo
-- Catálogo para clasificar el sistema de cultivo asociado a las muestras de germoplasma
-- Basado en categorías comunes de sistemas de cultivo
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.sistema_cultivo (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(50) UNIQUE NOT NULL,
    descripcion     TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_sistema_cultivo_nombre ON catalogo.sistema_cultivo(nombre);

-- ============================================================
-- 9. CATALOGO: método de almacenamiento
-- Catálogo para clasificar los métodos de almacenamiento de semillas asociados a las muestras de germoplasma
-- Basado en categorías comunes de conservación de semillas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.metodo_almacenamiento (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(50) UNIQUE NOT NULL,
    descripcion     TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_metodo_almacenamiento_nombre ON catalogo.metodo_almacenamiento(nombre);

-- ============================================================
-- 10. CATALOGO: etapa fenológica del maíz
-- Catálogo para clasificar las etapas fenológicas del maíz
-- Basado en el sistema de clasificación de etapas fenológicas comúnmente utilizado en la agronomía
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.etapa_fenologica (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(30) UNIQUE NOT NULL,
    descripcion     TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_etapa_fenologica_nombre ON catalogo.etapa_fenologica(nombre);

-- ============================================================
-- EJE TERRITORIAL (ESPACIAL)
-- ============================================================

-- ============================================================
-- 11. ESTADO
-- Catálogo de estados de la República Mexicana
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.estado (
    id              SERIAL PRIMARY KEY,
    clave_inegi     CHAR(2) NOT NULL UNIQUE,   -- ej. 24
    nombre          VARCHAR(100) NOT NULL,
    abreviatura     VARCHAR(10),
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_estado_nombre ON catalogo.estado USING gin(to_tsvector('spanish', nombre));

-- ============================================================
-- 12. MUNICIPIO
-- Catálogo de municipios de la Huasteca Potosina
-- Basado en el Marco Geoestadístico Nacional del INEGI
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.municipio (
    id              SERIAL PRIMARY KEY,
    clave_inegi     CHAR(3) NOT NULL UNIQUE,           -- ej. 013
    clave_completa  CHAR(5) NOT NULL UNIQUE,    -- estado+municipio ej. 24013
    nombre          VARCHAR(150) NOT NULL,
    nombre_corto    VARCHAR(100),
    cabecera        VARCHAR(150),               -- nombre de la cabecera municipal
    region          VARCHAR(100) DEFAULT 'Huasteca Potosina',
    estado_id       INTEGER NOT NULL REFERENCES catalogo.estado(id) 
                    ON DELETE RESTRICT 
                    ON UPDATE CASCADE,
    -- Coordenadas aproximadas del centroide del municipio
    latitud_centroide  DECIMAL(10,7),
    longitud_centroide DECIMAL(10,7),
    superficie_km2     DECIMAL(10,2),
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_municipio_clave ON catalogo.municipio(clave_completa);
CREATE INDEX IF NOT EXISTS idx_municipio_nombre ON catalogo.municipio USING gin(to_tsvector('spanish', nombre));
CREATE INDEX IF NOT EXISTS idx_municipio_estado ON catalogo.municipio(estado_id);

-- ============================================================
-- 13. LOCALIDAD
--    Unidad mínima del Marco Geoestadístico INEGI
--    Equivale a un poblado, rancho o colonia con nombre propio
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.localidad (
    id              SERIAL PRIMARY KEY,
    clave_inegi     CHAR(9) NOT NULL UNIQUE,                -- clave INEGI de 9 dígitos
    nombre          VARCHAR(200) NOT NULL,
    nombre_lengua_orig VARCHAR(200),
    tipo            VARCHAR(50),
    categoria       VARCHAR(100),               -- ej: ciudad, pueblo, rancho, ejido
    -- Población (Censo 2020 vía API INEGI)
    poblacion_total INTEGER,
    num_viviendas   INTEGER,
    -- Indicadores socioeconómicos
    grado_marginacion VARCHAR(30),
    indigena        BOOLEAN DEFAULT FALSE,       -- localidad con mayoria indigena
    -- Georreferenciación
    latitud         DECIMAL(10,7),
    longitud        DECIMAL(10,7),
    altitud_m       DECIMAL(8,2),
    -- Relaciones jerárquicas
    municipio_id    INTEGER NOT NULL REFERENCES catalogo.municipio(id) 
                    ON DELETE RESTRICT 
                    ON UPDATE CASCADE,
    -- Fuente
    fuente          VARCHAR(100) DEFAULT 'INEGI 2020',
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    UNIQUE (nombre, municipio_id),
    CHECK (tipo IN ('urbana','rural','mixta')),
    CHECK (grado_marginacion IN ('muy_alto', 'alto', 'medio', 'bajo', 'muy_bajo','sin_datos'))
);

CREATE INDEX IF NOT EXISTS idx_localidad_municipio ON catalogo.localidad(municipio_id);
CREATE INDEX IF NOT EXISTS idx_localidad_clave ON catalogo.localidad(clave_inegi);
CREATE INDEX IF NOT EXISTS idx_localidad_nombre ON catalogo.localidad
    USING gin(to_tsvector('spanish', nombre));
CREATE INDEX IF NOT EXISTS idx_localidad_tipo ON catalogo.localidad(tipo);
CREATE INDEX IF NOT EXISTS idx_localidad_coordenadas ON catalogo.localidad(latitud, longitud);
CREATE INDEX IF NOT EXISTS idx_localidad_marginacion ON catalogo.localidad(grado_marginacion);
CREATE INDEX IF NOT EXISTS idx_localidad_indigena ON catalogo.localidad(indigena);

-- ============================================================
-- 14. COLONIA / BARRIO / SECCION
--    Subdivisión interna de una localidad urbana o semiurbana
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.colonia (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(200) NOT NULL,
    tipo            VARCHAR(50),
    codigo_postal   CHAR(5),
    latitud         DECIMAL(10,7),
    longitud        DECIMAL(10,7),
    localidad_id    INTEGER NOT NULL REFERENCES catalogo.localidad(id) 
                    ON DELETE RESTRICT 
                    ON UPDATE CASCADE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (tipo IN (
                'colonia',
                'barrio',
                'seccion',
                'fraccionamiento',
                'ejido',
                'rancheria',
                'otro'
            )),
    CHECK (codigo_postal ~ '^[0-9]{5}$')
);

CREATE INDEX idx_colonia_nombre ON catalogo.colonia(nombre);

CREATE INDEX IF NOT EXISTS idx_colonia_localidad ON catalogo.colonia(localidad_id);
CREATE INDEX IF NOT EXISTS idx_colonia_cp ON catalogo.colonia(codigo_postal);

-- ============================================================
-- 15. CATALOGO: clases de uso de suelo
-- Basado en clasificaciones comunes (INEGI / FAO / CONABIO)
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.clase_uso_suelo (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(100) NOT NULL,
    categoria_general   VARCHAR(100),   -- agrícola, forestal, urbano, agua, etc.
    descripcion         TEXT,
    relevante_maiz      BOOLEAN DEFAULT FALSE,
    activo              BOOLEAN DEFAULT TRUE,
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================
-- EJE AMBIENTAL (CLIMA Y ECOSISTEMA)
-- ============================================================


-- ============================================================
-- 16. CATALOGO: tipos de eventos climáticos
-- Catálogo para clasificar los tipos de eventos climáticos extremos que afectan a las comunidades y cultivos
-- Basado en categorías comunes de desastres naturales
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_evento_climatico (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(100) UNIQUE NOT NULL, -- sequia, helada, inundacion
    severidad_base      SMALLINT,
    descripcion         TEXT,
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (severidad_base BETWEEN 1 AND 5)
);

CREATE INDEX idx_tipo_evento_climatico_severidad ON catalogo.tipo_evento_climatico(severidad_base);

-- ============================================================
-- 17. CATALOGO: variables ambientales
-- Catálogo para clasificar las variables ambientales medidas en campo o por sensores remotos
-- Basado en categorías comunes de monitoreo ambiental
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.variable_ambiental (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(30) UNIQUE NOT NULL,
    nombre              VARCHAR(100) UNIQUE NOT NULL, -- temperatura, humedad, NDVI
    tipo                VARCHAR(50), -- climatica, suelo, vegetacion, satelital
    descripcion         TEXT,
    unidad              VARCHAR(50),                  -- °C, %, índice
    valor_min           DECIMAL,
    valor_max           DECIMAL,
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (valor_min IS NULL OR valor_max IS NULL OR valor_min <= valor_max)
);

CREATE INDEX idx_variable_ambiental_tipo ON catalogo.variable_ambiental(tipo);
CREATE INDEX idx_variable_ambiental_nombre ON catalogo.variable_ambiental(nombre);

-- ============================================================
-- 18. CATALOGO: tipo de amenaza
-- Catálogo para clasificar los tipos de amenazas que enfrentan las comunidades y cultivos
-- Basado en categorías comunes de riesgos y vulnerabilidades
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_amenaza (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(80) UNIQUE NOT NULL,
    descripcion         TEXT,
    categoria           VARCHAR(50),
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (categoria IN ('agricola','climatica','ganadero','economica', 'social','forestal','sanitaria', 'tecnologica','otra'))
);

CREATE INDEX idx_tipo_amenaza_categoria ON catalogo.tipo_amenaza(categoria);

CREATE INDEX idx_tipo_amenaza_nombre ON catalogo.tipo_amenaza(nombre);

-- ============================================================
-- EJE SOCIOCULTURAL (PRODUCTOR Y CULTURA)
-- ============================================================

-- ============================================================
-- 19. CATALOGO: tipos de productor
-- Catálogo para clasificar los tipos de productores agrícolas en la Huasteca Potosina
-- Basado en categorías comunes de clasificación socioeconómica 
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_productor (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(100) UNIQUE NOT NULL, -- pequeño, mediano, subsistencia
    descripcion         TEXT,
    nivel_productivo    SMALLINT,               -- 1–5
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (nivel_productivo BETWEEN 1 AND 5)
);

CREATE INDEX idx_tipo_productor_nivel ON catalogo.tipo_productor(nivel_productivo);
CREATE INDEX idx_tipo_productor_nombre ON catalogo.tipo_productor(nombre);

-- ============================================================
-- 20. LENGUA ORIGINARIA
--    Catálogo de lenguas presentes en la Huasteca Potosina
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.lengua (
    id                  SERIAL PRIMARY KEY,
    nombre              VARCHAR(100) NOT NULL UNIQUE,
    nombre_original     VARCHAR(100),           -- nombre en la propia lengua
    familia_linguistica VARCHAR(100),
    variante            VARCHAR(100),           -- variante dialectal si aplica
    clave_inali         VARCHAR(20),            -- clave del INALI
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 21. PUEBLO ORIGINARIO
--    Pueblos indígenas presentes en la Huasteca Potosina
--    Fuente: INPI Atlas de Pueblos Indígenas 2020
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.pueblo_originario (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(150) NOT NULL,
    nombre_propio   VARCHAR(150),               -- cómo se llaman a sí mismos
    lengua_id       INTEGER REFERENCES catalogo.lengua(id) 
                    ON DELETE SET NULL 
                    ON UPDATE CASCADE,
    region_historica VARCHAR(200),
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX IF NOT EXISTS idx_pueblo_lengua ON catalogo.pueblo_originario(lengua_id);

CREATE TABLE IF NOT EXISTS catalogo.pueblo_municipio (
    pueblo_id           INTEGER NOT NULL REFERENCES catalogo.pueblo_originario(id)                ON DELETE CASCADE,
    municipio_id        INTEGER NOT NULL REFERENCES catalogo.municipio(id) 
                        ON DELETE CASCADE,
    PRIMARY KEY (pueblo_id, municipio_id)
);

CREATE INDEX idx_pueblo_municipio_municipio ON catalogo.pueblo_municipio(municipio_id);
CREATE INDEX idx_pueblo_municipio_pueblo ON catalogo.pueblo_municipio(pueblo_id);

-- ============================================================
-- 22. CATALOGO: tipo de ritual agrícola
-- Catálogo para clasificar los tipos de rituales agrícolas asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de rituales agrícolas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_ritual_agricola (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(60) UNIQUE NOT NULL,
    descripcion         TEXT,
    categoria           VARCHAR(50), -- ej. siembra, cosecha, protección, agradecimiento
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (categoria IN ('siembra', 'crecimiento', 'cosecha', 'almacenamiento', 'intercambio_semillas', 'peticion_lluvia', 'agradecimiento', 'otro'))
);

CREATE INDEX idx_tipo_ritual_agricola_categoria ON catalogo.tipo_ritual_agricola(categoria);
CREATE INDEX idx_tipo_ritual_agricola_nombre ON catalogo.tipo_ritual_agricola(nombre);

-- ============================================================
-- 23. CATALOGO: tipo de narrativa oral
-- Catálogo para clasificar los tipos de narrativas orales asociadas a las prácticas y saberes tradicionales
-- Basado en categorías comunes de narrativas orales
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_narrativa_oral (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(50) UNIQUE NOT NULL,
    descripcion         TEXT,
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_tipo_narrativa_oral_nombre ON catalogo.tipo_narrativa_oral(nombre);

-- ============================================================
-- 24. CATALOGO: categoría de saber agrícola
-- Catálogo para clasificar las categorías de saberes agrícolas asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de saberes agrícolas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.categoria_saber_agricola (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(80) UNIQUE NOT NULL,
    descripcion         TEXT,
    categoria_padre_id  INTEGER REFERENCES catalogo.categoria_saber_agricola(id),
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_categoria_saber_agricola_padre ON catalogo.categoria_saber_agricola(categoria_padre_id);

CREATE INDEX idx_categoria_saber_agricola_nombre ON catalogo.categoria_saber_agricola(nombre);

-- ============================================================
-- 25. CATALOGO: contexto de evento o consumo
-- Catálogo para clasificar los contextos de eventos o consumo asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de contextos de eventos o consumo
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.evento_contexto (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(80) UNIQUE NOT NULL,
    descripcion         TEXT,
    categoria           VARCHAR(50), -- ej. festivo, cotidiano, ceremonial, medicinal, otro
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (categoria IN ('festivo', 'cotidiano', 'ceremonial', 'medicinal','intercambio','agricola','ritual','cultural', 'social', 'climatica', 'administrativa', 'otro'))
);

CREATE INDEX idx_evento_contexto_categoria ON catalogo.evento_contexto(categoria);
CREATE INDEX idx_evento_contexto_nombre ON catalogo.evento_contexto(nombre);    

-- ============================================================
-- 26. CATALOGO: mecanismo de transmisión de saberes
-- Catálogo para clasificar los mecanismos de transmisión de saberes asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de mecanismos de transmisión de saberes
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.mecanismo_transmision (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(50) UNIQUE NOT NULL,
    descripcion         TEXT,
    categoria           VARCHAR(50), -- ej. oral, práctica directa, ritual, narrativa, otro
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (categoria IN ('oral','milpa_familiar','practica_directa', 'ritual', 'narrativa', 'visual', 'escrita', 'tradicional', 'formal', 'digital', 'comunitaria','escuela_comunitaria', 'otro'))
);

CREATE INDEX idx_mecanismo_transmision_categoria ON catalogo.mecanismo_transmision(categoria);
CREATE INDEX idx_mecanismo_transmision_nombre ON catalogo.mecanismo_transmision(nombre);

-- ============================================================
-- 27. CATALOGO: vínculo con el maíz
-- Catálogo para clasificar los vínculos con el maíz asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de vínculos con el maíz
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.vinculo_maiz (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(50) UNIQUE NOT NULL,
    descripcion         TEXT,
    categoria           VARCHAR(50), -- ej. espiritual, simbólico, económico, alimentario, medicinal, cultural, otro
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (categoria IN ('espiritual', 'simbólico', 'económico', 'alimentario', 'medicinal', 'cultural', 'social', 'ceremonial', 'climático', 'administrativo', 'identitario', 'ecologico', 'ritual', 'otro'))
);


-- ============================================================
-- DATOS BASE INICIALES
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Version: 1
-- ============================================================

-- ============================================================
-- CATALOGO: razas de maíz
-- ============================================================

INSERT INTO catalogo.raza_maiz
    (codigo, nombre, es_nativa)
VALUES 
    ('ANCHO', 'Ancho', TRUE),
    ('ARROCILLO_AMARILLO', 'Arrocillo Amarillo', TRUE),
    ('BOLITA', 'Bolita', TRUE),
    ('CACAHUACINTLE', 'Cacahuacintle', TRUE),
    ('CELAYA', 'Celaya', TRUE),
    ('CHALQUENO', 'Chalqueño', TRUE),
    ('CONEJO', 'Conejo', TRUE),
    ('COSCOMATEPEC', 'Coscomatepec', TRUE),
    ('CONICO', 'Cónico', TRUE),
    ('CONICO_NORTENO', 'Cónico Norteño', TRUE),
    ('DZIT_BACAL', 'Dzit Bacal', TRUE),
    ('ELOTES_CONICOS', 'Elotes Cónicos', TRUE),
    ('ELOTES_OCCIDENTALES', 'Elotes Occidentales', TRUE),
    ('MUSHITO', 'Mushito', TRUE),
    ('NAL_TEL', 'Nal-tel', TRUE),
    ('NAL_TEL_ALTURA', 'Nal-tel de Altura', TRUE),
    ('NEGRITO', 'Negrito', TRUE),
    ('OLOTILLO', 'Olotillo', TRUE),
    ('OLOTON', 'Olotón', TRUE),
    ('ONAVENO', 'Onaveño', TRUE),
    ('PALOMERO_TOLUQUENO', 'Palomero Toluqueño', TRUE),
    ('PEPITILLA', 'Pepitilla', TRUE),
    ('RATON', 'Ratón', TRUE),
    ('TABLONCILLO', 'Tabloncillo', TRUE),
    ('TEPECINTLE', 'Tepecintle', TRUE),
    ('TUXPENO', 'Tuxpeño', TRUE),
    ('TUXPENO_NORTENO', 'Tuxpeño Norteño', TRUE),
    ('VANDENO', 'Vandeño', TRUE),
    ('ZAPALOTE_GRANDE', 'Zapalote Grande', TRUE);

-- ============================================================
-- CATALOGO: colores de grano
-- ============================================================
INSERT INTO catalogo.color_grano 
    (codigo, nombre, es_nativo) 
VALUES 
    ('AMARILLO_B', 'Amarillo B', TRUE),
    ('AMARILLO_CLARO', 'Amarillo Claro', TRUE),
    ('AMARILLO_MEDIO', 'Amarillo Medio', TRUE),
    ('AMARILLO_NARANJA_F', 'Amarillo Naranja F', TRUE),
    ('AZUL_K', 'Azul K', TRUE),
    ('AZUL_OSCURO_L', 'Azul Oscuro L', TRUE),
    ('BLANCO', 'Blanco', TRUE),
    ('BLANCO_CREMOSO', 'Blanco Cremoso', TRUE),
    ('BLANCO_PURO', 'Blanco Puro', TRUE),
    ('CAFE_E', 'Café E', TRUE),
    ('CREMA', 'Crema', TRUE),
    ('JASPEADO_D', 'Jaspeado D', TRUE),
    ('MORADO_C', 'Morado C', TRUE),
    ('NARANJA', 'Naranja', TRUE),
    ('NEGRO', 'Negro', TRUE),
    ('ROJO_I', 'Rojo I', TRUE),
    ('ROJO_NARANJA_J', 'Rojo Naranja J', TRUE),
    ('ROJO_OSCURO', 'Rojo Oscuro', TRUE);

-- ============================================================
-- CATALOGO: estado de conservación
-- ============================================================
INSERT INTO catalogo.estado_conservacion 
    (codigo, nombre, descripcion, nivel_riesgo) 
VALUES
    ('ACTIVO', 'Activo', 'Presente y en uso localmente', 1),
    ('EN_RIESGO', 'En riesgo', 'Presente pero con riesgo de desaparecer', 3),
    ('SEMILLA_GUARDADA', 'Semilla guardada', 'No cultivado, pero semilla conservada', 2),
    ('EXTINTO_LOCAL', 'Extinto local', 'Ya no existe en la región', 5),
    ('DESCONOCIDO', 'Desconocido', 'No se tiene información suficiente', NULL),
    ('REINTRODUCIDO', 'Reintroducido', 'Reincorporado tras haber desaparecido', 2),
    ('EN_RESCATE', 'En rescate', 'En proceso de rescate o multiplicación', 4);

-- ============================================================
-- CATALOGO: clases de uso de maíz
-- ============================================================
INSERT INTO catalogo.uso_maiz 
    (codigo, nombre, descripcion) 
VALUES 
    ('ATOLE', 'Atole', 'Bebida tradicional mexicana a base de maíz cocido y molido, endulzada y servida caliente.'),
    ('NIXTAMAL', 'Nixtamal', 'Masa obtenida al cocer el grano de maíz en agua con cal, base para tortillas y otros alimentos.'),
    ('PINOLE', 'Pinole', 'Harina de maíz tostado y molido, utilizada para preparar bebidas y alimentos energéticos.'),
    ('TAMAL', 'Tamal', 'Alimento tradicional preparado con masa de maíz rellena y cocida en hojas.'),
    ('TORTILLA', 'Tortilla', 'Disco delgado hecho de masa de maíz nixtamalizado, base de la alimentación mexicana.'),
    ('ELOTE', 'Elote', 'Mazorca de maíz tierna, consumida hervida, asada o en platillos.'),
    ('POZOLE', 'Pozole', 'Platillo tradicional a base de maíz nixtamalizado y carne, servido en caldo.'),
    ('TOTPOPO', 'Totopo', 'Tortilla de maíz deshidratada y horneada o frita, utilizada como botana o acompañamiento.'),
    ('FORRAJE', 'Forraje', 'Material vegetal, como hojas y tallos de maíz, utilizado para alimentar ganado.'),
    ('GRANO', 'Grano', 'Semilla de maíz seca, base para la elaboración de diversos alimentos y productos.'),
    ('HOJA', 'Hoja', 'Hojas de la planta de maíz, empleadas para envolver alimentos como tamales.'),
    ('ABONO', 'Abono', 'Uso del residuo vegetal del maíz para enriquecer la tierra agrícola.'),
    ('COMBUSTIBLE', 'Combustible', 'Uso de residuos de maíz (olote, hojas) como fuente de energía para cocinar o calentar.'),
    ('HARINA', 'Harina', 'Producto obtenido de la molienda del grano de maíz, base para atole, tortillas y otros.'),
    ('HUACHOLES', 'Huacholes', 'Alimento tradicional preparado con maíz reventado o tostado.'),
    ('GERMOCONSERVACION', 'Germoplasma en conservación', 'Material genético de maíz almacenado para preservar la diversidad biológica.'),
    ('OTRO', 'Otro', 'Cualquier otro uso no especificado en este catálogo.'),
    ('SEMILLA', 'Semilla', 'Grano de maíz destinado a la siembra para la producción de nuevas plantas.');

-- ============================================================
-- CATALOGO: tipos de práctica agrícola
-- ============================================================
INSERT INTO catalogo.tipo_practica 
    (codigo, nombre, descripcion) 
VALUES
    ('TRADICIONAL', 'Tradicional', 'Prácticas agrícolas ancestrales, sin uso de insumos químicos ni maquinaria.'),
    ('AGROECOLOGICA', 'Agroecológica', 'Prácticas sostenibles, con enfoque en biodiversidad y manejo integrado.'),
    ('CONVENCIONAL', 'Convencional', 'Uso intensivo de insumos químicos y maquinaria.'),
    ('MIXTA', 'Mixta', 'Combinación de prácticas tradicionales y modernas.');

-- =============================================================
-- CATALOGO: prácticas agrícolas
-- =============================================================
INSERT INTO catalogo.practica_agricola 
    (codigo, nombre, descripcion, tipo_id) 
VALUES
    ('MILPA', 'Milpa', 'Sistema tradicional de policultivo de maíz, frijol y calabaza.', 1),
    ('ROZA_TUMBA', 'Roza-tumba-quema', 'Preparación del terreno mediante corte y quema de vegetación.', 1),
    ('ASOC_MAIZ_FRIJOL', 'Asociación maíz-frijol', 'Cultivo conjunto de maíz y frijol para aprovechar sinergias.', 2),
    ('USO_SEMILLA_PROPIA', 'Uso de semilla propia', 'Selección y resiembra de semilla de la cosecha anterior.', 1),
    ('CALENDARIO_AGRICOLA', 'Calendario agrícola tradicional', 'Siembra y cosecha siguiendo ciclos lunares y costumbres locales.', 1),
    ('ABONO_ORGANICO', 'Abono orgánico', 'Aplicación de composta, estiércol u otros abonos naturales.', 2),
    ('COMPOSTA', 'Composta', 'Producción y uso de composta para mejorar el suelo.', 2),
    ('CONTROL_BIOLOGICO', 'Control biológico de plagas', 'Uso de organismos benéficos para controlar plagas.', 2),
    ('FERTILIZANTE_QUIMICO', 'Fertilizante químico', 'Aplicación de fertilizantes sintéticos para aumentar la producción.', 3),
    ('RIEGO_GRAVEDAD', 'Riego por gravedad', 'Distribución de agua por canales abiertos.', 1),
    ('LABRANZA_MINIMA', 'Labranza mínima', 'Reducción de la remoción del suelo para conservar humedad.', 2),
    ('ROTACION_CULTIVOS', 'Rotación de cultivos', 'Alternancia de diferentes cultivos para mejorar el suelo.', 2),
    ('RIEGO_ASPERSION', 'Riego por aspersión', 'Aplicación de agua en forma de lluvia artificial.', 3),
    ('RIEGO_GOTEO', 'Riego por goteo', 'Aplicación localizada de agua directamente a la raíz.', 2),
    ('MONOCULTIVO', 'Monocultivo', 'Cultivo de una sola especie en grandes extensiones.', 3),
    ('QUEMA_RASTROJO', 'Quema de rastrojo', 'Eliminación de residuos de cosecha mediante quema.', 1),
    ('COBERTURA_VEGETAL', 'Cobertura vegetal', 'Mantenimiento de plantas vivas o residuos sobre el suelo.', 2),
    ('APLICACION_AGROQUI', 'Aplicación de agroquímicos', 'Uso de herbicidas, insecticidas o fungicidas sintéticos.', 3),
    ('MANEJO_INTEGRADO', 'Manejo integrado de plagas', 'Uso combinado de métodos biológicos, culturales y químicos para el control de plagas.', 4);

-- ============================================================
-- CATALOGO: sistema de manejo
-- ============================================================
INSERT INTO catalogo.sistema_manejo 
    (codigo, nombre, descripcion, es_tradicional) 
VALUES
    ('TRADICIONAL', 'Tradicional', 'Prácticas agrícolas tradicionales, bajo uso de insumos externos', TRUE),
    ('MECANIZADO', 'Mecanizado', 'Uso de maquinaria agrícola y técnicas modernas', FALSE),
    ('AGROECOLOGICO', 'Agroecológico', 'Enfoque sustentable, integración de prácticas ecológicas', TRUE),
    ('MIXTO', 'Mixto', 'Combinación de prácticas tradicionales y modernas', NULL),
    ('ORGANICO', 'Orgánico', 'Producción sin agroquímicos, certificada o en transición', FALSE),  
    ('INTENSIVO', 'Intensivo', 'Alta densidad de siembra y uso intensivo de insumos', FALSE),
    ('DESCONOCIDO', 'Desconocido', 'No especificado o no aplica', NULL);

-- ============================================================
-- 8. CATALOGO: sistema de cultivo
-- ============================================================
INSERT INTO catalogo.sistema_cultivo 
    (codigo, nombre, descripcion) 
VALUES
    ('TEMPORAL', 'Temporal', 'Cultivo de temporal, depende de lluvias'),
    ('RIEGO', 'Riego', 'Cultivo bajo riego'),
    ('MIXTO', 'Mixto', 'Combinación de temporal y riego'),
    ('SECANO', 'Secano', 'Cultivo en zonas áridas, sin riego'),
    ('HUMEDAL', 'Humedal', 'Cultivo en zonas húmedas o inundables'),
    ('DESCONOCIDO', 'Desconocido', 'No especificado o no aplica');

-- ============================================================
-- CATALOGO: método de almacenamiento
-- ============================================================

INSERT INTO catalogo.metodo_almacenamiento 
    (codigo, nombre, descripcion) 
VALUES
    ('COSTAL_YUTE', 'Costal de yute tradicional', 'Costal de yute tradicional'),
    ('BOTE_METALICO', 'Bote o tambor metálico', 'Bote o tambor metálico'),
    ('TROJE', 'Troje de madera o adobe', 'Troje de madera o adobe'),
    ('SILO_HERMETICO', 'Silo hermético, metálico o plástico', 'Silo hermético, metálico o plástico'),
    ('TINACO', 'Tinaco o recipiente grande de plástico', 'Tinaco o recipiente grande de plástico'),
    ('OLLA_BARRO', 'Olla o cántaro de barro', 'Olla o cántaro de barro'),
    ('HORNILLA', 'Almacenado en la hornilla o cocina', 'Almacenado en la hornilla o cocina'),
    ('OTRO', 'Otro método de almacenamiento', 'Otro método de almacenamiento'),
    ('DESCONOCIDO', 'No especificado o no aplica', 'No especificado o no aplica');

-- ============================================================
-- CATALOGO: etapa fenológica del maíz
-- ============================================================

INSERT INTO catalogo.etapa_fenologica (codigo, nombre, descripcion) VALUES
    ('PLANTULA', 'Plántula', 'Primera etapa: emergencia y desarrollo inicial de la plántula'),
    ('ANTESIS', 'Antesís', 'Floración masculina: inicio de antesis'),
    ('LECHOSO', 'Lechoso', 'Grano en formación, contenido lechoso'),
    ('MASOSO', 'Masoso', 'Grano en maduración, textura masosa'),
    ('MADUREZ', 'Madurez', 'Grano completamente maduro, listo para cosecha'),
    ('GENERAL', 'General', 'No aplica a una etapa fenológica específica');


-- ============================================================
-- DATOS INICIALES
-- Estado de San Luis Potosí
-- ============================================================
-- ============================================================
-- CATALOGO: estado
-- ============================================================

INSERT INTO catalogo.estado 
    (clave_inegi, nombre, abreviatura)
VALUES 
    ('24', 'San Luis Potosí', 'SLP');

-- ============================================================
-- CATALOGO: municipio
-- ============================================================

-- ============================================================
-- 20 Municipios oficiales de la Huasteca Potosina
-- Fuente: Marco Geoestadístico INEGI 2024
-- Coordenadas de centroides aproximadas
-- ============================================================

INSERT INTO catalogo.municipio
    (clave_inegi, clave_completa, nombre, cabecera,
     latitud_centroide, longitud_centroide, estado_id)
VALUES
    ('003','24003','Aquismón',               'Aquismón',               21.6333, -99.0000, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('004','24004','Axtla de Terrazas',      'Axtla de Terrazas',      21.7333, -98.8667, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('013','24013','Ciudad Valles',          'Ciudad Valles',          21.9983, -99.0178, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('017','24017','Coxcatlán',              'Coxcatlán',              21.5167, -99.0000, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('019','24019','Ébano',                  'Ébano',                  22.1833, -98.3833, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('021','24021','El Naranjo',             'El Naranjo',             22.5167, -99.4833, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('025','24025','Huehuetlán',             'Huehuetlán',             21.6833, -98.8500, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('030','24030','Matlapa',                'Matlapa',                21.4667, -98.7667, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('039','24039','San Antonio',            'San Antonio',            21.9500, -98.8167, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('043','24043','San Martín Chalchicuautla','San Martín Chalchicuautla',21.5333,-98.6500,(SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('045','24045','San Vicente Tancuayalab','San Vicente Tancuayalab',22.0000, -98.6333, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('049','24049','Tamasopo',               'Tamasopo',               21.9500, -99.4000, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('050','24050','Tamazunchale',           'Tamazunchale',           21.2667, -98.7833, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('051','24051','Tampacán',               'Tampacán',               21.7000, -98.8000, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('052','24052','Tampamolón Corona',      'Tampamolón Corona',      21.6167, -98.7000, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('054','24054','Tamuín',                 'Tamuín',                 22.0000, -98.7833, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('055','24055','Tancanhuitz de Santos',  'Tancanhuitz de Santos',  21.6000, -98.9667, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('056','24056','Tanlajás',               'Tanlajás',               21.8333, -99.1167, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('057','24057','Tanquián de Escobedo',   'Tanquián de Escobedo',   21.9333, -98.6667, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí')),
    ('058','24058','Xilitla',                'Xilitla',                21.3833, -98.9833, (SELECT id FROM catalogo.estado WHERE nombre = 'San Luis Potosí'));

-- ============================================================
-- CATALOGO: clases de uso de suelo
-- Clases de uso de suelo más comunes en la región
-- Fuentes: INEGI, FAO, CONABIO
-- ============================================================ 
INSERT INTO catalogo.clase_uso_suelo 
    (codigo, nombre, categoria_general, relevante_maiz) 
VALUES
    ('MILPA', 'Milpa tradicional', 'agricola', TRUE),
    ('MAIZ', 'Cultivo de maíz', 'agricola', TRUE),
    ('AGRICOLA_TEMPORAL', 'Agricultura de temporal', 'agricola', TRUE),
    ('AGRICOLA_RIEGO', 'Agricultura de riego', 'agricola', TRUE),
    ('PASTIZAL', 'Pastizal', 'ganadero', FALSE),
    ('BOSQUE', 'Bosque', 'forestal', FALSE),
    ('SELVA', 'Selva', 'forestal', FALSE),
    ('MATORRAL', 'Matorral', 'forestal', FALSE),
    ('ACUICOLA', 'Cuerpos de agua', 'agua', FALSE),
    ('URBANO', 'Zona urbana', 'urbano', FALSE),
    ('SIN_VEGETACION', 'Suelo desnudo', 'otros', FALSE);

-- ============================================================
-- CATALOGO: tipos de eventos climáticos
-- ============================================================
INSERT INTO catalogo.tipo_evento_climatico 
    (codigo, nombre, descripcion, severidad_base)
VALUES
    ('SEQUIA', 'Sequía', 'Periodo prolongado de escasez de lluvias', 3),
    ('INUNDACION', 'Inundación', 'Exceso de agua por lluvias intensas o desbordamiento de ríos', 4),
    ('HELADA', 'Helada', 'Descenso de temperatura por debajo de 0°C que afecta cultivos', 2),
    ('GRANIZADA', 'Granizada', 'Precipitación de granizo que puede dañar cultivos', 3),
    ('VIENTO_FUERTE', 'Viento fuerte', 'Rachas de viento que pueden causar daños físicos a las plantas', 2),
    ('OLA_CALOR', 'Ola de calor', 'Periodo de temperaturas extremadamente altas que afecta el desarrollo del cultivo', 3),
    ('OTRO', 'Otro', 'Otro tipo de evento climático no especificado', 1);

-- ============================================================
-- CATALOGO: variables ambientales
-- ============================================================
INSERT INTO catalogo.variable_ambiental 
    (codigo, nombre, tipo, descripcion, unidad)
VALUES
    ('TEMPERATURA', 'Temperatura ambiente durante el ciclo de cultivo', 'climatica', 'Temperatura ambiente durante el ciclo de cultivo', '°C'),
    ('PRECIPITACION', 'Cantidad de lluvia durante el ciclo de cultivo', 'climatica', 'Cantidad de lluvia durante el ciclo de cultivo', 'mm'),
    ('HUMEDAD_RELATIVA', 'Porcentaje de humedad en el aire durante el ciclo de cultivo', 'climatica', 'Porcentaje de humedad en el aire durante el ciclo de cultivo', '%'),
    ('VELOCIDAD_VIENTO', 'Velocidad del viento durante el ciclo de cultivo', 'climatica', 'Velocidad del viento durante el ciclo de cultivo', 'km/h'),
    ('RADIACION_SOLAR', 'Cantidad de radiación solar recibida durante el ciclo de cultivo', 'climatica', 'Cantidad de radiación solar recibida durante el ciclo de cultivo', 'MJ/m²/día'),
    ('OTRO', 'Otra variable ambiental no especificada', NULL, 'Otra variable ambiental no especificada', NULL);

-- ============================================================
-- CATALOGO: tipo de amenaza
-- ============================================================
INSERT INTO catalogo.tipo_amenaza 
    (codigo, nombre, descripcion, categoria) 
VALUES
    ('EXP_AGR', 'Expansión agrícola industrial', 'Conversión de tierras a agricultura industrial', 'agricola'),
    ('GAN_EXT', 'Ganadería extensiva', 'Prácticas ganaderas que afectan la cobertura vegetal', 'ganadero'),
    ('DEF', 'Deforestación', 'Pérdida de cobertura forestal por actividades humanas', 'forestal'),
    ('TRANSGEN', 'Presencia de transgénicos', 'Introducción de semillas transgénicas en la región', 'agricola'),
    ('CONT_Q', 'Contaminación química', 'Uso excesivo de agroquímicos o contaminantes', 'agricola'),
    ('SEQUIA', 'Sequía prolongada', 'Periodos largos sin lluvias', 'climatica'),
    ('INUND', 'Inundación', 'Afectaciones por exceso de agua o lluvias intensas', 'climatica'),
    ('HELADA', 'Helada atípica', 'Eventos de helada fuera de temporada', 'climatica'),
    ('PLAGA_EM', 'Plaga emergente', 'Aparición de nuevas plagas o enfermedades', 'agricola'),
    ('ABANDONO', 'Abandono del campo', 'Reducción de la actividad agrícola por abandono', 'agricola'),
    ('MIGRAC', 'Migración de productores', 'Salida de productores hacia otras regiones', 'agricola'),
    ('OTRA', 'Otra amenaza no especificada', 'Otra amenaza no especificada', 'otra');

-- ============================================================
-- CATALOGO: tipos de productor
-- ============================================================
INSERT INTO catalogo.tipo_productor 
    (codigo, nombre, descripcion, nivel_productivo) 
VALUES
    ('PEQUENO', 'Pequeño', 'Productor con pequeña escala de producción, generalmente para autoconsumo o venta local', 1),
    ('MEDIANO', 'Mediano', 'Productor con mediana escala, puede comercializar parte de su producción', 2),
    ('SUBSISTENCIA', 'Subsistencia', 'Productor cuya producción es principalmente para el consumo familiar, con recursos limitados', 1),
    ('GRANDE', 'Grande', 'Productor con gran escala de producción, orientado principalmente a la comercialización', 5),
    ('EJIDAL', 'Ejidal', 'Productor que trabaja tierras de propiedad ejidal', 3),
    ('COMUNAL', 'Comunal', 'Productor que trabaja tierras de propiedad comunal', 3),
    ('FAMILIAR', 'Familiar', 'Producción gestionada principalmente por la familia', 2),
    ('EMPRESARIAL', 'Empresarial', 'Productor con organización empresarial o figura legal formal', 5),
    ('ORGANICO', 'Orgánico', 'Productor certificado o en transición a producción orgánica', 4),
    ('TRADICIONAL', 'Tradicional', 'Productor que utiliza prácticas tradicionales o ancestrales', 2);

-- ============================================================
-- CATALOGO: lengua originaria
-- Fuente: INALI 2020
-- ============================================================
INSERT INTO catalogo.lengua
    (nombre, nombre_original, familia_linguistica, clave_inali)
VALUES
    ('Teenek',   'Tének',    'Maya',       'tee'),
    ('Náhuatl',  'Nāhuatl',  'Uto-azteca', 'nah'),
    ('Pame',     'Xi iuy',   'Otopame',    'pam'),
    ('Español',  'Español',  'Romance',    NULL);

-- ============================================================
-- CATALOGO: pueblo originario
-- Fuente: INPI Atlas de Pueblos Indígenas 2020
-- ============================================================
INSERT INTO catalogo.pueblo_originario
    (codigo, nombre, nombre_propio, lengua_id)
VALUES
    ('TEENEK', 'Teenek (Huasteco)', 'Tének', (SELECT id FROM catalogo.lengua WHERE nombre = 'Teenek')),
    ('NAHUA_HUASTECA', 'Nahua de la Huasteca', 'Maseualmej', (SELECT id FROM catalogo.lengua WHERE nombre = 'Náhuatl')),
    ('PAME_SUR', 'Pame del Sur', 'Xi iuy', (SELECT id FROM catalogo.lengua WHERE nombre = 'Pame'));

-- ============================================================
-- RELACIÓN: PUEBLO ORIGINARIO - MUNICIPIO
-- Normalización de la presencia de pueblos originarios en municipios
-- ============================================================
INSERT INTO catalogo.pueblo_municipio (pueblo_id, municipio_id) VALUES
    -- Teenek (Huasteco)
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Aquismón')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Coxcatlán')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Huehuetlán')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Matlapa')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'San Antonio')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'San Martín Chalchicuautla')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tampacán')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tampamolón Corona')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tancanhuitz de Santos')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tanlajás')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'TEENEK'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tanquián de Escobedo')),

    -- Nahua de la Huasteca
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Axtla de Terrazas')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Coxcatlán')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Huehuetlán')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Matlapa')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'San Martín Chalchicuautla')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tamazunchale')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tampacán')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tampamolón Corona')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'NAHUA_HUASTECA'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Xilitla')),

    -- Pame del Sur
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'PAME_SUR'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Tamasopo')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'PAME_SUR'), (SELECT id FROM catalogo.municipio WHERE nombre = 'El Naranjo')),
    ((SELECT id FROM catalogo.pueblo_originario WHERE codigo = 'PAME_SUR'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Ciudad Valles'));

-- ============================================================
-- CATALOGO: tipo de ritual agrícola
-- ============================================================
INSERT INTO catalogo.tipo_ritual_agricola 
    (codigo, nombre, descripcion, categoria) 
VALUES
    ('SIEMBRA', 'Siembra', 'Ritual relacionado con el inicio de la siembra', 'siembra'),
    ('CRECIMIENTO', 'Crecimiento', 'Ritual para favorecer el crecimiento del cultivo', 'crecimiento'),
    ('COSECHA', 'Cosecha', 'Ritual de agradecimiento o petición durante la cosecha', 'cosecha'),
    ('ALMACENAMIENTO', 'Almacenamiento', 'Ritual para la protección del grano almacenado', 'almacenamiento'),
    ('INTERCAMBIO_SEMILLAS', 'Intercambio de semillas', 'Ritual asociado al intercambio de semillas', 'intercambio_semillas'),
    ('PETICION_LLUVIA', 'Petición de lluvia', 'Ritual para pedir lluvias favorables', 'peticion_lluvia'),
    ('AGRADECIMIENTO', 'Agradecimiento', 'Ritual de agradecimiento por la cosecha o el ciclo agrícola', 'agradecimiento'),
    ('OTRO', 'Otro', 'Otro tipo de ritual agrícola no especificado', 'otro');

-- ============================================================
-- CATALOGO: tipo de narrativa oral
-- ============================================================
INSERT INTO catalogo.tipo_narrativa_oral 
    (codigo, nombre, descripcion) 
VALUES
    ('MITO_ORIGEN', 'Mito de origen', 'Narración mítica sobre el origen de algo o alguien'),
    ('LEYENDA', 'Leyenda', 'Relato tradicional con base histórica o fantástica'),
    ('CUENTO', 'Cuento', 'Narración breve de hechos ficticios o reales'),
    ('REFRAN', 'Refrán', 'Expresión popular de sabiduría o consejo'),
    ('CANCION', 'Canción', 'Composición musical tradicional o popular'),
    ('ORACION_AGRICOLA', 'Oración agrícola', 'Oración o plegaria relacionada con la agricultura'),
    ('TESTIMONIO', 'Testimonio', 'Relato de experiencia personal o colectiva'),
    ('OTRO', 'Otro', 'Otro tipo de narrativa oral no especificada');


-- ============================================================
-- 26. CATALOGO: categoría de saber agrícola
-- ============================================================
INSERT INTO catalogo.categoria_saber_agricola 
    (codigo, nombre, descripcion) 
VALUES
    ('PREPARACION_SUELO', 'Preparación de suelo', 'Prácticas para preparar el suelo antes de la siembra'),
    ('SELECCION_SEMILLA', 'Selección de semilla', 'Selección y tratamiento de semillas'),
    ('SIEMBRA', 'Siembra', 'Prácticas relacionadas con la siembra'),
    ('MANEJO_CULTIVO', 'Manejo de cultivo', 'Manejo y cuidado del cultivo durante su desarrollo'),
    ('CONTROL_PLAGAS', 'Control de plagas tradicional', 'Control de plagas y enfermedades con métodos tradicionales'),
    ('COSECHA', 'Cosecha', 'Prácticas de cosecha y recolección'),
    ('ALMACENAMIENTO', 'Almacenamiento', 'Métodos de almacenamiento de la cosecha'),
    ('PREDICCION_CLIMA', 'Predicción del clima', 'Predicción y observación del clima'),
    ('ASOCIACION_PLANTAS', 'Asociación de plantas', 'Asociación de cultivos y plantas'),
    ('USO_MEDICINAL', 'Uso medicinal', 'Uso medicinal de plantas asociadas al cultivo'),
    ('CALENDARIO_AGRICOLO', 'Calendario agrícola', 'Uso de calendarios agrícolas tradicionales'),
    ('OTRO', 'Otro', 'Otra categoría no especificada');

-- ============================================================
-- CATALOGO: ocasión de uso o consumo
-- ============================================================
INSERT INTO catalogo.evento_contexto 
    (codigo, nombre, descripcion, categoria) 
VALUES
    ('COTIDIANA', 'Uso o consumo en la vida diaria', 'Uso o consumo en la vida diaria', 'cotidiano'),
    ('FESTIVA', 'Uso o consumo en fiestas o celebraciones', 'Uso o consumo en fiestas o celebraciones', 'festivo'),
    ('RITUAL', 'Uso o consumo en rituales o ceremonias', 'Uso o consumo en rituales o ceremonias', 'ritual'),
    ('MEDICINAL', 'Uso con fines medicinales o curativos', 'Uso con fines medicinales o curativos', 'medicinal'),
    ('INTERCAMBIO', 'Uso en contextos de trueque o intercambio', 'Uso en contextos de trueque o intercambio', 'intercambio'),
    ('OTRO', 'Otra ocasión no especificada', 'Otra ocasión no especificada', 'otro');

-- ============================================================
-- CATALOGO: mecanismo de transmisión de saberes
-- ============================================================
INSERT INTO catalogo.mecanismo_transmision 
    (codigo, nombre, descripcion, categoria) 
VALUES
    ('PRACTICA_DIRECTA', 'Práctica directa', 'Aprendizaje mediante la práctica directa en el campo', 'practica_directa'),
    ('NARRACION_ORAL', 'Narración oral', 'Transmisión de saberes a través de relatos orales', 'oral'),
    ('PARTICIPACION_RITUAL', 'Participación ritual', 'Aprendizaje mediante la participación en rituales agrícolas', 'ritual'),
    ('ESCUELA_COMUNITARIA', 'Escuela comunitaria', 'Transmisión formal en espacios educativos comunitarios', 'escuela_comunitaria'),
    ('MILPA_FAMILIAR', 'Milpa familiar', 'Aprendizaje y transmisión en el contexto de la milpa familiar', 'milpa_familiar'),
    ('OTRO', 'Otro', 'Otro mecanismo de transmisión no especificado', 'otro');

-- ============================================================
-- CATALOGO: vínculo con el maíz
-- ============================================================
INSERT INTO catalogo.vinculo_maiz 
(codigo, nombre, descripcion, categoria) 
VALUES
    ('ORIGEN_MAIZ', 'Origen del maíz', 'Relato o conocimiento sobre el origen del maíz', 'cultural'),
    ('MANEJO_CULTIVO', 'Manejo del cultivo', 'Prácticas y saberes sobre el manejo del cultivo de maíz', 'social'),
    ('SELECCION_SEMILLA', 'Selección de semilla', 'Conocimientos y criterios para la selección de semilla', 'ecologico'),
    ('COSMOVISION_AGRICOLA', 'Cosmovisión agrícola', 'Relación simbólica, espiritual o ritual con el maíz', 'espiritual'),
    ('IDENTIDAD_CULTURAL', 'Identidad cultural', 'El maíz como elemento de identidad cultural', 'identitario'),
    ('OTRO', 'Otro', 'Otro tipo de vínculo con el maíz no especificado', 'otro');



