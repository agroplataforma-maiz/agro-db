-- ============================================================
-- ESQUEMA: catalogo
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Versión: 1.0
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
    nombre          VARCHAR(100) NOT NULL UNIQUE,  -- ej. Tuxpeño, Olotillo, Cónico
    descripcion     TEXT,
    region_origen   VARCHAR(150),
    tipo_ciclo      VARCHAR(50) CHECK (tipo_ciclo IN ('precoz','intermedio','tardio')),
    es_nativa       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. CATALOGO: colores de grano
-- Catálogo de colores de grano presentes en las razas de maíz de la Huasteca Potosina
-- Basado en clasificaciones académicas y etnobotánicas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.color_grano (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,  -- blanco, amarillo, azul, rojo, negro
    descripcion TEXT,
    es_nativo   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 3. CATALOGO: estado de conservación
-- Catálogo para clasificar el estado de conservación de las razas de maíz
-- Basado en criterios de riesgo de extinción local
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.estado_conservacion (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,  -- activo, en_riesgo, extinto_local
    descripcion TEXT,
    nivel_riesgo SMALLINT,               -- 1–5
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 4. CATALOGO: clases de uso de maíz
-- Catálogo para clasificar los usos tradicionales y contemporáneos del maíz en la Huasteca Potosina
-- Basado en categorías comunes de uso del maíz
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.uso_maiz (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL, -- tortilla, elote, forraje
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- EJE AGRONÓMICO (MANEJO Y PRODUCCIÓN)
-- ============================================================

-- ============================================================
-- 5. CATALOGO: tipos de práctica agrícola
-- Catálogo para clasificar las prácticas agrícolas asociadas a los productores y muestras de germoplasma
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_practica (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL, -- tradicional, agroecologica, etc.
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================
-- 6. Catalogo: prácticas agrícolas
-- Catálogo para clasificar las prácticas agrícolas asociadas a los productores y muestras de germoplasma
-- Basado en categorías comunes de manejo agrícola
-- =============================================================
CREATE TABLE IF NOT EXISTS catalogo.practica_agricola (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL,
    descripcion TEXT,
    tipo_id     INTEGER REFERENCES catalogo.tipo_practica(id) ON DELETE SET NULL ON UPDATE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 7. CATALOGO: sistema de manejo
-- Catálogo para clasificar el sistema de manejo agrícola asociado a las muestras de germoplasma
-- Basado en categorías comunes de prácticas agrícolas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.sistema_manejo (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,  -- tradicional, mecanizado, agroecologico
    descripcion TEXT,
    es_tradicional BOOLEAN,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 8. CATALOGO: sistema de cultivo
-- Catálogo para clasificar el sistema de cultivo asociado a las muestras de germoplasma
-- Basado en categorías comunes de sistemas de cultivo
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.sistema_cultivo (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 9. CATALOGO: método de almacenamiento
-- Catálogo para clasificar los métodos de almacenamiento de semillas asociados a las muestras de germoplasma
-- Basado en categorías comunes de conservación de semillas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.metodo_almacenamiento (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 10. CATALOGO: tipos de fenotipo
-- Catálogo para clasificar los tipos de fenotipo medidos en las evaluaciones agronómicas
-- Basado en categorías comunes de caracterización fenotípica
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_fenotipo (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL, -- altura_planta, longitud_mazorca
    unidad VARCHAR(50),
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 11. CATALOGO: etapa fenológica del maíz
-- Catálogo para clasificar las etapas fenológicas del maíz
-- Basado en el sistema de clasificación de etapas fenológicas comúnmente utilizado en la agronomía
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.etapa_fenologica (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(30) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);


-- ============================================================
-- EJE TERRITORIAL (ESPACIAL)
-- ============================================================

-- ============================================================
-- 12. ESTADO
-- Catálogo de estados de la República Mexicana
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.estado (
    id              SERIAL PRIMARY KEY,
    clave_inegi     CHAR(2) NOT NULL UNIQUE,   -- ej. 24
    nombre          VARCHAR(100) NOT NULL,
    abreviatura     VARCHAR(10),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 13. MUNICIPIO
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
    estado_id       INTEGER NOT NULL REFERENCES catalogo.estado(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- Coordenadas aproximadas del centroide del municipio
    latitud_centroide  DECIMAL(10,7),
    longitud_centroide DECIMAL(10,7),
    superficie_km2     DECIMAL(10,2),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 14. COMUNIDAD
--    Agrupación sociocultural o administrativa de localidades
--    Ej: ejidos, rancherías, zonas indígenas
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.comunidad (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(200) NOT NULL,
    nombre_lengua_orig VARCHAR(200),            -- nombre en lengua originaria
    tipo            VARCHAR(50) CHECK (tipo IN (
                        'indigena',
                        'campesina',
                        'ejidal',
                        'mestiza',
                        'mixta',
                        'urbana',
                        'rancheria',
                        'otro'
                    )),
    municipio_id    INTEGER NOT NULL REFERENCES catalogo.municipio(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- Estadísticas básicas
    poblacion_total INTEGER,
    num_localidades SMALLINT,
    -- Fuente del dato
    fuente          VARCHAR(100) DEFAULT 'INEGI 2020',
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE (nombre, municipio_id)
);

-- ============================================================
-- 15. LOCALIDAD
--    Unidad mínima del Marco Geoestadístico INEGI
--    Equivale a un poblado, rancho o colonia con nombre propio
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.localidad (
    id              SERIAL PRIMARY KEY,
    clave_inegi     CHAR(9) NOT NULL UNIQUE,                -- clave INEGI de 9 dígitos
    nombre          VARCHAR(200) NOT NULL,
    nombre_lengua_orig VARCHAR(200),
    tipo            VARCHAR(50) CHECK (tipo IN (
                        'urbana',
                        'rural',
                        'mixta'
                    )),
    categoria       VARCHAR(100),               -- ej: ciudad, pueblo, rancho, ejido
    -- Población (Censo 2020 vía API INEGI)
    poblacion_total INTEGER,
    num_viviendas   INTEGER,
    -- Indicadores socioeconómicos
    grado_marginacion VARCHAR(30) CHECK (grado_marginacion IN (
                        'muy_alto', 'alto', 'medio', 'bajo', 'muy_bajo'
                    )),
    indigena        BOOLEAN DEFAULT FALSE,       -- localidad con mayoria indigena
    -- Georreferenciación
    latitud         DECIMAL(10,7),
    longitud        DECIMAL(10,7),
    altitud_m       DECIMAL(8,2),
    -- Relaciones jerárquicas
    municipio_id    INTEGER NOT NULL REFERENCES catalogo.municipio(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    comunidad_id    INTEGER REFERENCES catalogo.comunidad(id) ON DELETE SET NULL ON UPDATE CASCADE,
    -- Fuente
    fuente          VARCHAR(100) DEFAULT 'INEGI 2020',
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE (nombre, municipio_id)
);

-- ============================================================
-- 16. COLONIA / BARRIO / SECCION
--    Subdivisión interna de una localidad urbana o semiurbana
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.colonia (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(200) NOT NULL,
    tipo            VARCHAR(50) CHECK (tipo IN (
                        'colonia',
                        'barrio',
                        'seccion',
                        'fraccionamiento',
                        'ejido',
                        'rancheria',
                        'otro'
                    )),
    codigo_postal   CHAR(5) CHECK (codigo_postal ~ '^[0-9]{5}$'),
    latitud         DECIMAL(10,7),
    longitud        DECIMAL(10,7),
    localidad_id    INTEGER NOT NULL REFERENCES catalogo.localidad(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 17. CATALOGO: clases de uso de suelo
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
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);


-- ============================================================
-- EJE AMBIENTAL (CLIMA Y ECOSISTEMA)
-- ============================================================


-- ============================================================
-- 18. CATALOGO: tipos de eventos climáticos
-- Catálogo para clasificar los tipos de eventos climáticos extremos que afectan a las comunidades y cultivos
-- Basado en categorías comunes de desastres naturales
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_evento_climatico (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL, -- sequia, helada, inundacion
    severidad_base SMALLINT,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 19. CATALOGO: variables ambientales
-- Catálogo para clasificar las variables ambientales medidas en campo o por sensores remotos
-- Basado en categorías comunes de monitoreo ambiental
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.variable_ambiental (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL, -- temperatura, humedad, NDVI
    descripcion TEXT,
    unidad VARCHAR(50),                  -- °C, %, índice
    valor_min DECIMAL,
    valor_max DECIMAL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 20. CATALOGO: tipo de amenaza
-- Catálogo para clasificar los tipos de amenazas que enfrentan las comunidades y cultivos
-- Basado en categorías comunes de riesgos y vulnerabilidades
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_amenaza (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- EJE SOCIOCULTURAL (PRODUCTOR Y CULTURA)
-- ============================================================

-- ============================================================
-- 21. CATALOGO: tipos de productor
-- Catálogo para clasificar los tipos de productores agrícolas en la Huasteca Potosina
-- Basado en categorías comunes de clasificación socioeconómica 
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_productor (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL, -- pequeño, mediano, subsistencia
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 22. LENGUA ORIGINARIA
--    Catálogo de lenguas presentes en la Huasteca Potosina
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.lengua (
    id                  SERIAL PRIMARY KEY,
    nombre              VARCHAR(100) NOT NULL UNIQUE,
    nombre_original     VARCHAR(100),           -- nombre en la propia lengua
    familia_linguistica VARCHAR(100),
    variante            VARCHAR(100),           -- variante dialectal si aplica
    clave_inali         VARCHAR(20),            -- clave del INALI
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 23. PUEBLO ORIGINARIO
--    Pueblos indígenas presentes en la Huasteca Potosina
--    Fuente: INPI Atlas de Pueblos Indígenas 2020
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo.pueblo_originario (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL,
    nombre_propio   VARCHAR(150),               -- cómo se llaman a sí mismos
    lengua_id       INTEGER REFERENCES catalogo.lengua(id) ON DELETE SET NULL ON UPDATE CASCADE,
    region_historica VARCHAR(200),
    municipios_presencia TEXT,                  -- municipios donde hay presencia
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 24. CATALOGO: tipo de ritual agrícola
-- Catálogo para clasificar los tipos de rituales agrícolas asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de rituales agrícolas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_ritual_agricola (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(60) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 25. CATALOGO: tipo de narrativa oral
-- Catálogo para clasificar los tipos de narrativas orales asociadas a las prácticas y saberes tradicionales
-- Basado en categorías comunes de narrativas orales
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_narrativa_oral (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 26. CATALOGO: categoría de saber agrícola
-- Catálogo para clasificar las categorías de saberes agrícolas asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de saberes agrícolas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.categoria_saber_agricola (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 27. CATALOGO: ocasión de uso o consumo
-- Catálogo para clasificar las ocasiones de uso o consumo asociadas a las prácticas y saberes tradicionales
-- Basado en categorías comunes de ocasiones de uso o consumo
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.ocasion (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 28. CATALOGO: mecanismo de transmisión de saberes
-- Catálogo para clasificar los mecanismos de transmisión de saberes asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de mecanismos de transmisión de saberes
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.mecanismo_transmision (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);


-- ============================================================
-- 29. CATALOGO: vínculo con el maíz
-- Catálogo para clasificar los vínculos con el maíz asociados a las prácticas y saberes tradicionales
-- Basado en categorías comunes de vínculos con el maíz
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.vinculo_maiz (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- EJE DE TRAZABILIDAD Y GEODATOS (ORIGEN Y FUENTES)
-- ============================================================

-- ============================================================
-- 30. CATALOGO: tipo producto de dron 
-- Catálogo para clasificar los tipos de productos generados a partir de imágenes de dron
-- Basado en categorías comunes de análisis de imágenes aéreas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_producto_dron (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 31. CATALOGO: formato de archivo 
-- Catálogo para clasificar los formatos de archivo utilizados en el almacenamiento y análisis de datos
-- Basado en categorías comunes de formatos de datos geoespaciales y agronómicos
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.formato_archivo (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 32. CATALOGO: tipo de capa SIG
-- Catálogo para clasificar los tipos de capas SIG utilizadas en el análisis territorial
-- Basado en categorías comunes de análisis espacial
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.tipo_capa_sig (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 33. CATALOGO: fuente de captura
-- Catálogo para clasificar las fuentes de captura de datos geoespaciales y agronómicos
-- Basado en categorías comunes de origen de datos
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.fuente_captura (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 34. CATALOGO: fuente de información
-- Catálogo para clasificar las fuentes de información utilizadas en el análisis territorial y agronómico
-- Basado en categorías comunes de origen de datos
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.fuente_informacion (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    tipo VARCHAR(30), -- Ejemplo: sensor, institucion, estudio, plataforma
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 35. CATALOGO: origen de muestra
-- Catálogo para clasificar el origen de las muestras de germoplasma
-- Basado en categorías comunes de recolección
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.origen_muestra (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,  -- campo, almacen, mercado, intercambio
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 36. CATALOGO: origen de semilla
-- Catálogo para clasificar el origen de las semillas de maíz nativo
-- Basado en categorías comunes de procedencia de semillas
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.origen_semilla (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,  -- autoconsumo, intercambio, compra
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);