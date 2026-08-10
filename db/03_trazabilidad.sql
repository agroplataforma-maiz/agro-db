-- ============================================================
-- ESQUEMA: trazabilidad
-- Tabla centralizada de archivos multimedia (fotos, videos, documentos, etc.)
-- para toda la plataforma agroplataforma_maiz
-- ============================================================

SET search_path TO trazabilidad, public;

-- ============================================================
-- EJE DE TRAZABILIDAD Y GEODATOS (ORIGEN Y FUENTES)
-- ============================================================

-- ============================================================
-- 1. tipo producto de dron 
-- Catálogo para clasificar los tipos de productos generados a partir de imágenes de dron
-- Basado en categorías comunes de análisis de imágenes aéreas
-- ============================================================
CREATE TABLE IF NOT EXISTS trazabilidad.tipo_producto_dron (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(50) UNIQUE NOT NULL,
    descripcion         TEXT,
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$')
);

CREATE INDEX idx_tipo_producto_dron_nombre ON trazabilidad.tipo_producto_dron(nombre);

-- ============================================================
-- 2. tipo de capa SIG
-- Catálogo para clasificar los tipos de capas SIG utilizadas en el análisis territorial
-- Basado en categorías comunes de análisis espacial
-- ============================================================
CREATE TABLE IF NOT EXISTS trazabilidad.tipo_capa_sig (
    id                  SERIAL PRIMARY KEY,
    codigo              VARCHAR(20) UNIQUE NOT NULL,
    nombre              VARCHAR(100) UNIQUE NOT NULL,
    descripcion         TEXT,
    tipo_geometria      VARCHAR(20),
    fuente              VARCHAR(100),
    ruta_almacenamiento VARCHAR(200), -- Ruta física o lógica de almacenamiento de la capa SIG
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z_]+$'),
    CHECK (tipo_geometria IN ('punto', 'linea', 'poligono', 'raster'))
);

CREATE INDEX idx_tipo_capa_sig_nombre ON trazabilidad.tipo_capa_sig(nombre);

-- ============================================================
-- 3. origen de material agrícola
-- Catálogo para clasificar el origen del material agrícola asociado a las muestras de germoplasma
-- Basado en categorías comunes de origen de material agrícola
-- ============================================================
CREATE TABLE IF NOT EXISTS trazabilidad.origen_material_agricola (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(80) UNIQUE NOT NULL,
    descripcion     TEXT,
    tipo            VARCHAR(30) NOT NULL, 
    -- SEMILLA | MUESTRA | AMBOS
    sub_tipo        VARCHAR(30),
    -- autoconsumo, campo, mercado, intercambio, almacen, etc.
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z0-9_]+$'),
    CHECK (tipo IN ('semilla','muestra','ambos')),
    CHECK (sub_tipo IN ('autoconsumo', 'campo', 'mercado', 'intercambio', 'almacen', 'donacion', 'banco_de_germoplasma', 'otro'))
);

-- ============================================================
-- 4. fuente
-- Catálogo para clasificar las fuentes de datos utilizadas en el sistema
-- Basado en categorías comunes de fuentes de datos geoespaciales, agronómicos y sociales
-- ============================================================
CREATE TABLE IF NOT EXISTS trazabilidad.fuente (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(100) UNIQUE NOT NULL,
    descripcion     TEXT,
    tipo            VARCHAR(30) NOT NULL,
    sub_tipo        VARCHAR(30),
    es_captura      BOOLEAN DEFAULT FALSE,
    es_informacion  BOOLEAN DEFAULT FALSE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z0-9_]+$'),
    CHECK (tipo IN ('sensor','institucion','estudio','plataforma','modelo','api','hibrido','otro'))
);

CREATE INDEX idx_fuente_tipo ON trazabilidad.fuente(tipo);
CREATE INDEX idx_fuente_nombre ON trazabilidad.fuente(nombre);

-- ============================================================
-- 5. formato de archivo 
-- Catálogo para clasificar los formatos de archivo utilizados en el almacenamiento y análisis de datos
-- Basado en categorías comunes de formatos de datos geoespaciales y agronómicos
-- ============================================================
CREATE TABLE IF NOT EXISTS trazabilidad.formato_archivo (
    id                  SERIAL PRIMARY KEY,
    nombre              VARCHAR(20) UNIQUE NOT NULL,
    descripcion         TEXT,
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_formato_archivo_nombre ON trazabilidad.formato_archivo(nombre);

-- ============================================================
-- 6. multimedia
-- Permite asociar cualquier archivo multimedia a cualquier entidad
-- mediante entidad_tipo y entidad_id (polimórfico)
-- ============================================================
CREATE TABLE IF NOT EXISTS trazabilidad.multimedia (
    id                  SERIAL PRIMARY KEY,
    entidad_tipo        VARCHAR(50) NOT NULL, -- Ej: 'parcela', 'productor', 'cultivo', 'comunidad', etc.
    entidad_id          UUID NOT NULL,        -- UUID o INTEGER según la entidad (usar UUID para consistencia)
    tipo_medio          VARCHAR(20) NOT NULL,
    subtipo             VARCHAR(40),
    nombre_archivo      VARCHAR(300) NOT NULL,
    ruta_almacenamiento VARCHAR(500) NOT NULL,
    formato_archivo_id  INTEGER REFERENCES trazabilidad.formato_archivo(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    descripcion         TEXT,
    peso_kb             INTEGER,
    resolucion          VARCHAR(30),
    fecha_captura       DATE DEFAULT CURRENT_DATE,
    uuid_envio          VARCHAR(100),
    fuente_id           INTEGER REFERENCES trazabilidad.fuente(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    registrado_por      UUID REFERENCES sistema.usuario(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now(),

    CHECK (tipo_medio IN ('foto','video','documento','audio','otro'))
);

-- Índices sugeridos para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_multimedia_entidad ON trazabilidad.multimedia(entidad_tipo, entidad_id);
CREATE INDEX IF NOT EXISTS idx_multimedia_tipo ON trazabilidad.multimedia(tipo_medio);
CREATE INDEX IF NOT EXISTS idx_multimedia_fecha ON trazabilidad.multimedia(fecha_captura);



-- ============================================================
-- formato de archivo 
-- ============================================================
INSERT INTO trazabilidad.formato_archivo
    (nombre, descripcion) 
VALUES
    ('tif', 'Archivo de imagen georreferenciada TIFF'),
    ('geotiff', 'GeoTIFF, formato estándar para datos raster geoespaciales'),
    ('jpg', 'Imagen JPEG'),
    ('png', 'Imagen PNG'),
    ('las', 'Archivo de nube de puntos LiDAR (LAS)'),
    ('laz', 'Archivo comprimido de nube de puntos LiDAR (LAZ)'),
    ('shp', 'Shapefile, formato vectorial ESRI'),
    ('otro', 'Otro formato de archivo'),
    ('shapefile', 'Archivo vectorial ESRI Shapefile'),
    ('geojson', 'Archivo vectorial GeoJSON'),
    ('geopackage', 'Archivo vectorial/raster GeoPackage'),
    ('raster', 'Archivo raster geoespacial'),
    ('wms', 'Servicio Web Map Service (WMS)'),
    ('csv', 'Archivo de texto separado por comas, útil para tablas de atributos o puntos'),
    ('kml', 'Archivo KML de Google Earth'),
    ('gpkg', 'Abreviatura común de GeoPackage'),
    ('pdf', 'Documento PDF, útil para mapas exportados'),
    ('mp4', 'Archivo de video, por ejemplo para vuelos de dron');

-- ============================================================
-- CATALOGO: fuentes de captura y de información
-- ============================================================
INSERT INTO trazabilidad.fuente (codigo, nombre, descripcion, tipo, es_captura, es_informacion) VALUES
    ('GPS', 'GPS', 'Captura directa con GPS', 'sensor', TRUE, FALSE),
    ('DRON', 'Dron', 'Captura mediante dron', 'sensor', TRUE, FALSE),
    ('SATELITE', 'Satelite', 'Captura mediante imagen satelital', 'sensor', TRUE, FALSE),
    ('ESTIMADO', 'Estimado', 'Dato estimado o aproximado', 'modelo', TRUE, FALSE),
    ('OTRO_CAPTURA', 'Otro origen de captura', 'Otro origen de captura', 'otro', TRUE, FALSE),
    ('SENTINEL_2', 'Sentinel-2', 'Satélite Sentinel-2 de la ESA', 'sensor', FALSE, TRUE),
    ('LANDSAT_8', 'Landsat-8', 'Satélite Landsat-8 de la NASA/USGS', 'sensor', FALSE, TRUE),
    ('LANDSAT_9', 'Landsat-9', 'Satélite Landsat-9 de la NASA/USGS', 'sensor', FALSE, TRUE),
    ('MODIS', 'MODIS', 'Sensor MODIS de la NASA', 'sensor', FALSE, TRUE),
    ('PLANETSCOPE', 'PlanetScope', 'Constelación de satélites PlanetScope', 'sensor', FALSE, TRUE),
    ('CONABIO', 'CONABIO', 'Comisión Nacional para el Conocimiento y Uso de la Biodiversidad', 'institucion', FALSE, TRUE),
    ('INEGI', 'INEGI', 'Instituto Nacional de Estadística y Geografía', 'institucion', FALSE, TRUE),
    ('CONAGUA', 'CONAGUA', 'Comisión Nacional del Agua', 'institucion', FALSE, TRUE),
    ('NASA', 'NASA', 'National Aeronautics and Space Administration', 'institucion', FALSE, TRUE),
    ('ESTUDIO_LOCAL', 'Estudio local', 'Estudio o levantamiento local', 'estudio', FALSE, TRUE),
    ('F2_PARCELA_GPS', 'F2_Parcela_GPS', 'Formulario F2 de parcela con GPS', 'plataforma', FALSE, TRUE),
    ('OTRO_INFO', 'Otra fuente de información', 'Otra fuente de información', 'otro', FALSE, TRUE);

-- ============================================================
-- CATALOGO: tipo producto de dron 
-- ============================================================
INSERT INTO trazabilidad.tipo_producto_dron 
    (codigo, nombre, descripcion) 
VALUES
    ('ORTOMOSAICO_RGB', 'Ortomosaico RGB', 'Ortomosaico generado con imágenes RGB'),
    ('ORTOMOSAICO_MULTI', 'Ortomosaico Multiespectral', 'Ortomosaico generado con imágenes multiespectrales'),
    ('DEM', 'Modelo Digital de Elevación', 'Modelo Digital de Elevación'),
    ('DSM', 'Modelo Digital de Superficie', 'Modelo Digital de Superficie'),
    ('BANDA_VERDE', 'Banda Verde', 'Capa de banda verde'),
    ('BANDA_ROJO', 'Banda Rojo', 'Capa de banda rojo'),
    ('BANDA_RED_EDGE', 'Banda Red Edge', 'Capa de banda red edge'),
    ('BANDA_NIR', 'Banda NIR', 'Capa de banda infrarrojo cercano (NIR)'),
    ('INDICE_NDVI', 'Índice NDVI', 'Índice de vegetación NDVI'),
    ('INDICE_NDWI', 'Índice NDWI', 'Índice de agua NDWI'),
    ('INDICE_GNDVI', 'Índice GNDVI', 'Índice GNDVI'),
    ('INDICE_NDRE', 'Índice NDRE', 'Índice NDRE (Normalized Difference Red Edge)'),
    ('NUBE_PUNTOS', 'Nube de puntos', 'Nube de puntos LiDAR'),
    ('OTRO', 'Otro', 'Otro tipo de producto');



-- ============================================================
-- 32. CATALOGO: tipo de capa SIG
-- ============================================================
INSERT INTO trazabilidad.tipo_capa_sig (codigo, nombre, descripcion, tipo_geometria) VALUES
    ('USO_SUELO', 'Capa de uso de suelo', 'Capa de uso de suelo', 'poligono'),
    ('COBERTURA_VEGETAL', 'Capa de cobertura vegetal', 'Capa de cobertura vegetal', 'poligono'),
    ('ZONA_PRIORITARIA', 'Zonas prioritarias para conservación o manejo', 'Zonas prioritarias para conservación o manejo', 'poligono'),
    ('AMENAZA', 'Capas de amenazas ambientales o antrópicas', 'Capas de amenazas ambientales o antrópicas', 'poligono'),
    ('HIDROLOGIA', 'Red hidrográfica, cuerpos de agua', 'Red hidrográfica, cuerpos de agua', 'linea'),
    ('EDAFOLGIA', 'Suelos y propiedades edáficas', 'Suelos y propiedades edáficas', 'poligono'),
    ('DIVISION_MUNICIPAL', 'División política municipal', 'División política municipal', 'poligono'),
    ('COMUNIDADES', 'Ubicación de comunidades', 'Ubicación de comunidades', 'punto'),
    ('INFRAESTRUCTURA', 'Infraestructura: caminos, escuelas, hospitales, etc.', 'Infraestructura: caminos, escuelas, hospitales, etc.', 'linea'),
    ('LIMITE_ESTATAL', 'División estatal', 'División estatal', 'poligono'),
    ('LIMITE_EJIDAL', 'División ejidal/comunal', 'División ejidal/comunal', 'poligono'),
    ('PUNTOS_DE_INTERES', 'Sitios arqueológicos, pozos, etc.', 'Sitios arqueológicos, pozos, etc.', 'punto'),
    ('USO_DE_AGUA', 'Infraestructura hidráulica, pozos, ríos', 'Infraestructura hidráulica, pozos, ríos', 'linea'),
    ('ZONAS_DE_RIESGO', 'Zonas de riesgo: inundación, deslaves, etc.', 'Zonas de riesgo: inundación, deslaves, etc.', 'poligono'),
    ('VEGETACION', 'Tipos de vegetación', 'Tipos de vegetación', 'poligono'),
    ('ALTIMETRIA', 'Curvas de nivel, elevación', 'Curvas de nivel, elevación', 'linea'),
    ('PARCELAS', 'Polígonos de parcelas agrícolas', 'Polígonos de parcelas agrícolas', 'poligono'),
    ('INFRA_ENERGIA', 'Líneas eléctricas, subestaciones', 'Líneas eléctricas, subestaciones', 'linea');

-- ============================================================
-- CATALOGO: origen_material_agricola
-- ============================================================
INSERT INTO trazabilidad.origen_material_agricola 
(codigo, nombre, descripcion, tipo, sub_tipo) VALUES

-- =========================
-- CAPTURA DIRECTA EN CAMPO
-- =========================
('GPS', 'GPS', 'Captura directa con GPS en campo', 'semilla', 'campo'),
('DRON', 'Dron', 'Captura mediante dron en campo', 'semilla', 'campo'),
('CAMPO_DIRECTO', 'Campo directo', 'Registro directo en sitio sin sensores', 'semilla', 'campo'),

-- =========================
-- CAPTURA REMOTA / TELEDINAMICA
-- =========================
('SATELITE', 'Satélite', 'Captura mediante imágenes satelitales en general', 'muestra', 'campo'),
('SENTINEL_2', 'Sentinel-2', 'Imágenes Sentinel-2 de alta resolución', 'muestra', 'campo'),
('LANDSAT_8', 'Landsat-8', 'Imágenes Landsat-8 multiespectrales', 'muestra', 'campo'),
('LANDSAT_9', 'Landsat-9', 'Imágenes Landsat-9 multiespectrales', 'muestra', 'campo'),
('MODIS', 'MODIS', 'Sensor MODIS para monitoreo ambiental', 'muestra', 'campo'),
('PLANETSCOPE', 'PlanetScope', 'Constelación de alta frecuencia PlanetScope', 'muestra', 'campo'),

-- =========================
-- ESTIMACIÓN / DERIVADOS
-- =========================
('ESTIMADO', 'Estimado', 'Datos estimados o interpolados', 'semilla', 'otro'),
('MODELO', 'Modelo', 'Datos generados por modelos predictivos', 'semilla', 'otro'),

-- =========================
-- CAMPO SOCIAL / INTERCAMBIO
-- =========================
('INTERCAMBIO', 'Intercambio', 'Material obtenido por intercambio entre productores', 'semilla', 'intercambio'),
('DONACION', 'Donación', 'Material recibido como donación comunitaria', 'semilla', 'donacion'),

-- =========================
-- CONSERVACIÓN
-- =========================
('BANCO_GEN', 'Banco de germoplasma', 'Material proveniente de bancos de germoplasma', 'muestra', 'banco_de_germoplasma'),

-- =========================
-- OTROS
-- =========================
('OTRO', 'Otro', 'Origen no clasificado', 'semilla', 'otro');