-- ============================================================
-- ESQUEMA: catalogo
-- Catálogo territorial de la Huasteca Potosina
-- Jerarquía: Municipio -> Comunidad -> Localidad -> Colonia
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
-- ============================================================

CREATE SCHEMA IF NOT EXISTS catalogo;
SET search_path TO catalogo, public;

-- ============================================================
-- 1. ESTADO
-- ============================================================

CREATE TABLE catalogo.estado (
    id              SERIAL PRIMARY KEY,
    clave_inegi     CHAR(2) NOT NULL UNIQUE,   -- ej. 24
    nombre          VARCHAR(100) NOT NULL,
    abreviatura     VARCHAR(10),
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. MUNICIPIO
-- ============================================================

CREATE TABLE catalogo.municipio (
    id              SERIAL PRIMARY KEY,
    clave_inegi     CHAR(3) NOT NULL,           -- ej. 013
    clave_completa  CHAR(5) NOT NULL UNIQUE,    -- estado+municipio ej. 24013
    nombre          VARCHAR(150) NOT NULL,
    nombre_corto    VARCHAR(100),
    cabecera        VARCHAR(150),               -- nombre de la cabecera municipal
    region          VARCHAR(100) DEFAULT 'Huasteca Potosina',
    estado_id       INTEGER NOT NULL REFERENCES catalogo.estado(id),
    -- Coordenadas aproximadas del centroide del municipio
    latitud_centroide  DECIMAL(10,7),
    longitud_centroide DECIMAL(10,7),
    superficie_km2     DECIMAL(10,2),
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_municipio_clave ON catalogo.municipio(clave_completa);
CREATE INDEX idx_municipio_nombre ON catalogo.municipio USING gin(to_tsvector('spanish', nombre));
CREATE INDEX idx_municipio_estado ON catalogo.municipio(estado_id);

-- ============================================================
-- 3. COMUNIDAD
--    Agrupación sociocultural o administrativa de localidades
--    Ej: ejidos, rancherías, zonas indígenas
-- ============================================================

CREATE TABLE catalogo.comunidad (
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
    pueblo_originario_id INTEGER,
    municipio_id    INTEGER REFERENCES catalogo.municipio(id),
    -- Estadísticas básicas
    poblacion_total INTEGER,
    num_localidades SMALLINT,
    -- Fuente del dato
    fuente          VARCHAR(100) DEFAULT 'INEGI 2020',
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_comunidad_municipio ON catalogo.comunidad(municipio_id);

-- ============================================================
-- 4. LOCALIDAD
--    Unidad mínima del Marco Geoestadístico INEGI
--    Equivale a un poblado, rancho o colonia con nombre propio
-- ============================================================

CREATE TABLE catalogo.localidad (
    id              SERIAL PRIMARY KEY,
    clave_inegi     VARCHAR(10),                -- clave INEGI de 9 dígitos
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
    municipio_id    INTEGER REFERENCES catalogo.municipio(id),
    comunidad_id    INTEGER REFERENCES catalogo.comunidad(id),
    -- Fuente
    fuente          VARCHAR(100) DEFAULT 'INEGI 2020',
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_localidad_municipio  ON catalogo.localidad(municipio_id);

CREATE INDEX idx_localidad_comunidad  ON catalogo.localidad(comunidad_id);

CREATE INDEX idx_localidad_clave      ON catalogo.localidad(clave_inegi);

CREATE INDEX idx_localidad_nombre     ON catalogo.localidad
    USING gin(to_tsvector('spanish', nombre));

CREATE INDEX idx_localidad_tipo ON catalogo.localidad(tipo);

CREATE INDEX idx_localidad_coordenadas ON catalogo.localidad(latitud, longitud);

-- ============================================================
-- 5. COLONIA / BARRIO / SECCION
--    Subdivisión interna de una localidad urbana o semiurbana
-- ============================================================

CREATE TABLE catalogo.colonia (
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
    codigo_postal   CHAR(5),
    latitud         DECIMAL(10,7),
    longitud        DECIMAL(10,7),
    localidad_id    INTEGER REFERENCES catalogo.localidad(id),
    municipio_id    INTEGER REFERENCES catalogo.municipio(id),
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_colonia_localidad ON catalogo.colonia(localidad_id);
CREATE INDEX idx_colonia_cp        ON catalogo.colonia(codigo_postal);
CREATE INDEX idx_colonia_municipio ON catalogo.colonia(municipio_id);


-- ============================================================
-- 6. LENGUA ORIGINARIA
--    Catálogo de lenguas presentes en la Huasteca Potosina
-- ============================================================

CREATE TABLE catalogo.lengua (
    id                  SERIAL PRIMARY KEY,
    nombre              VARCHAR(100) NOT NULL UNIQUE,
    nombre_original     VARCHAR(100),           -- nombre en la propia lengua
    familia_linguistica VARCHAR(100),
    variante            VARCHAR(100),           -- variante dialectal si aplica
    clave_inali         VARCHAR(20),            -- clave del INALI
    created_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 7. PUEBLO ORIGINARIO
--    Pueblos indígenas presentes en la Huasteca Potosina
--    Fuente: INPI Atlas de Pueblos Indígenas 2020
-- ============================================================

CREATE TABLE catalogo.pueblo_originario (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL,
    nombre_propio   VARCHAR(150),               -- cómo se llaman a sí mismos
    lengua_id       INTEGER REFERENCES catalogo.lengua(id),
    region_historica VARCHAR(200),
    municipios_presencia TEXT,                  -- municipios donde hay presencia
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_pueblo_lengua ON catalogo.pueblo_originario(lengua_id);

ALTER TABLE catalogo.comunidad
ADD CONSTRAINT fk_comunidad_pueblo_originario
FOREIGN KEY (pueblo_originario_id)
REFERENCES catalogo.pueblo_originario(id);

-- ============================================================
-- CATALOGO: clases de uso de suelo
-- Basado en clasificaciones comunes (INEGI / FAO / CONABIO)
-- ============================================================

CREATE TABLE catalogo.clase_uso_suelo (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(100) NOT NULL,
    categoria_general   VARCHAR(100),   -- agrícola, forestal, urbano, agua, etc.
    descripcion         TEXT,
    relevante_maiz      BOOLEAN DEFAULT FALSE,
    activo              BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- VISTAS DEL CATÁLOGO
-- ============================================================

-- Vista jerárquica completa: municipio -> comunidad -> localidad
CREATE VIEW catalogo.v_territorial AS
SELECT
    m.clave_completa        AS clave_municipio,
    m.nombre                AS municipio,
    m.region,
    c.nombre                AS comunidad,
    c.tipo                  AS tipo_comunidad,
    c.pueblo_originario_id,
    l.clave_inegi           AS clave_localidad,
    l.nombre                AS localidad,
    l.tipo                  AS tipo_localidad,
    l.categoria,
    l.poblacion_total,
    l.grado_marginacion,
    l.indigena,
    l.latitud,
    l.longitud,
    l.altitud_m
FROM catalogo.municipio m
LEFT JOIN catalogo.comunidad c  ON c.municipio_id = m.id
LEFT JOIN catalogo.localidad l  ON l.municipio_id = m.id
ORDER BY m.nombre, c.nombre, l.nombre;

-- Vista resumen por municipio
CREATE VIEW catalogo.v_resumen_municipio AS
SELECT
    m.nombre                AS municipio,
    m.cabecera,
    COUNT(DISTINCT c.id)    AS total_comunidades,
    COUNT(DISTINCT l.id)    AS total_localidades,
    SUM(l.poblacion_total)  AS poblacion_total,
    SUM(CASE WHEN l.indigena THEN 1 ELSE 0 END) AS localidades_indigenas,
    COUNT(DISTINCT col.id)  AS total_colonias
FROM catalogo.municipio m
LEFT JOIN catalogo.comunidad c  ON c.municipio_id = m.id
LEFT JOIN catalogo.localidad l  ON l.municipio_id = m.id
LEFT JOIN catalogo.colonia col  ON col.municipio_id = m.id
GROUP BY m.id, m.nombre, m.cabecera
ORDER BY m.nombre;

-- ============================================================
-- DATOS INICIALES
-- Estado de San Luis Potosí
-- ============================================================

INSERT INTO catalogo.estado (clave_inegi, nombre, abreviatura)
VALUES ('24', 'San Luis Potosí', 'SLP');

-- ============================================================
-- 20 Municipios oficiales de la Huasteca Potosina
-- Fuente: Marco Geoestadístico INEGI 2024
-- Coordenadas de centroides aproximadas
-- ============================================================

INSERT INTO catalogo.municipio
    (clave_inegi, clave_completa, nombre, cabecera,
     latitud_centroide, longitud_centroide, estado_id)
VALUES
    ('003','24003','Aquismón',               'Aquismón',               21.6333, -99.0000, 1),
    ('004','24004','Axtla de Terrazas',      'Axtla de Terrazas',      21.7333, -98.8667, 1),
    ('013','24013','Ciudad Valles',          'Ciudad Valles',          21.9983, -99.0178, 1),
    ('017','24017','Coxcatlán',              'Coxcatlán',              21.5167, -99.0000, 1),
    ('019','24019','Ébano',                  'Ébano',                  22.1833, -98.3833, 1),
    ('021','24021','El Naranjo',             'El Naranjo',             22.5167, -99.4833, 1),
    ('025','24025','Huehuetlán',             'Huehuetlán',             21.6833, -98.8500, 1),
    ('030','24030','Matlapa',                'Matlapa',                21.4667, -98.7667, 1),
    ('039','24039','San Antonio',            'San Antonio',            21.9500, -98.8167, 1),
    ('043','24043','San Martín Chalchicuautla','San Martín Chalchicuautla',21.5333,-98.6500,1),
    ('045','24045','San Vicente Tancuayalab','San Vicente Tancuayalab',22.0000, -98.6333, 1),
    ('049','24049','Tamasopo',               'Tamasopo',               21.9500, -99.4000, 1),
    ('050','24050','Tamazunchale',           'Tamazunchale',           21.2667, -98.7833, 1),
    ('051','24051','Tampacán',               'Tampacán',               21.7000, -98.8000, 1),
    ('052','24052','Tampamolón Corona',      'Tampamolón Corona',      21.6167, -98.7000, 1),
    ('054','24054','Tamuín',                 'Tamuín',                 22.0000, -98.7833, 1),
    ('055','24055','Tancanhuitz de Santos',  'Tancanhuitz de Santos',  21.6000, -98.9667, 1),
    ('056','24056','Tanlajás',               'Tanlajás',               21.8333, -99.1167, 1),
    ('057','24057','Tanquián de Escobedo',   'Tanquián de Escobedo',   21.9333, -98.6667, 1),
    ('058','24058','Xilitla',                'Xilitla',                21.3833, -98.9833, 1);

-- ============================================================
-- Lenguas originarias de la Huasteca Potosina
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
-- Pueblos originarios de la Huasteca Potosina
-- Fuente: INPI Atlas de Pueblos Indígenas 2020
-- ============================================================

INSERT INTO catalogo.pueblo_originario
    (nombre, nombre_propio, municipios_presencia)
VALUES
    ('Teenek (Huasteco)',
     'Tének',
     'Aquismón, Coxcatlán, Huehuetlán, Matlapa, San Antonio, '
     'San Martín Chalchicuautla, Tampacán, Tampamolón Corona, '
     'Tancanhuitz, Tanlajás, Tanquián de Escobedo'),

    ('Nahua de la Huasteca',
     'Maseualmej',
     'Axtla de Terrazas, Coxcatlán, Huehuetlán, Matlapa, '
     'San Martín Chalchicuautla, Tamazunchale, Tampacán, '
     'Tampamolón Corona, Xilitla'),

    ('Pame del Sur',
     'Xi iuy',
     'Tamasopo, El Naranjo, Ciudad Valles');

-- ============================================================
-- Clases de uso de suelo más comunes en la región
-- Fuentes: INEGI, FAO, CONABIO
-- ============================================================ 
INSERT INTO catalogo.clase_uso_suelo 
(codigo, nombre, categoria_general, relevante_maiz) VALUES
('MILPA','Milpa tradicional','agricola',TRUE),
('MAIZ','Cultivo de maíz','agricola',TRUE),
('AGRICOLA_TEMPORAL','Agricultura de temporal','agricola',TRUE),
('AGRICOLA_RIEGO','Agricultura de riego','agricola',TRUE),
('PASTIZAL','Pastizal','ganadero',FALSE),
('BOSQUE','Bosque','forestal',FALSE),
('SELVA','Selva','forestal',FALSE),
('MATORRAL','Matorral','forestal',FALSE),
('ACUICOLA','Cuerpos de agua','agua',FALSE),
('URBANO','Zona urbana','urbano',FALSE),
('SIN_VEGETACION','Suelo desnudo','otros',FALSE);