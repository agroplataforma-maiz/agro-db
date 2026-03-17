-- ============================================================
-- ESQUEMA: geografico
-- Ubicaciones, parcelas, capas SIG, imágenes satelitales,
-- vuelos de dron, productos de dron, zonas prioritarias
-- ============================================================

SET search_path TO geografico, public;

-- Ubicación geoespacial con PostGIS
CREATE TABLE geografico.ubicacion (
    id                  SERIAL PRIMARY KEY,
    latitud             DECIMAL(10,7) NOT NULL,
    longitud            DECIMAL(10,7) NOT NULL,
    altitud_m           DECIMAL(8,2),
    municipio_id        INTEGER REFERENCES catalogo.municipio(id),
    comunidad_id        INTEGER REFERENCES catalogo.comunidad(id),
    tipo_suelo          VARCHAR(100),
    zona_agroecologica  VARCHAR(100),
    sistema_referencia  VARCHAR(20) DEFAULT 'WGS84',
    fuente_captura      VARCHAR(50) CHECK (fuente_captura IN ('GPS','dron','satelite','estimado')),
    geom                GEOMETRY(Point, 4326),
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ubicacion_geom ON geografico.ubicacion USING GIST (geom);

CREATE OR REPLACE FUNCTION geografico.set_ubicacion_geom()
RETURNS TRIGGER AS $$
BEGIN
    NEW.geom := ST_SetSRID(ST_MakePoint(NEW.longitud, NEW.latitud), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ubicacion_geom
BEFORE INSERT OR UPDATE ON geografico.ubicacion
FOR EACH ROW EXECUTE FUNCTION geografico.set_ubicacion_geom();

-- Parcela agrícola
CREATE TABLE geografico.parcela (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(150),
    superficie_ha   DECIMAL(8,4),
    sistema_manejo  VARCHAR(50) CHECK (sistema_manejo IN ('tradicional','mixto','convencional','agroecologico')),
    tenencia        VARCHAR(50) CHECK (tenencia IN ('ejidal','privada','comunal','rentada','desconocida')),
    productor_id    INTEGER REFERENCES social.productor(id),
    comunidad_id    INTEGER REFERENCES catalogo.comunidad(id),
    ubicacion_id    INTEGER REFERENCES geografico.ubicacion(id),
    poligono        GEOMETRY(Polygon, 4326),
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_parcela_poligono ON geografico.parcela USING GIST (poligono);

CREATE INDEX idx_parcela_productor ON geografico.parcela(productor_id);
CREATE INDEX idx_parcela_comunidad ON geografico.parcela(comunidad_id);
CREATE INDEX idx_parcela_ubicacion ON geografico.parcela(ubicacion_id);

-- Imagen satelital descargada
CREATE TABLE geografico.imagen_satelital (
    id                  SERIAL PRIMARY KEY,
    fuente              VARCHAR(50) CHECK (fuente IN ('Sentinel-2','Landsat-8','Landsat-9','MODIS','PlanetScope','otro')),
    fecha_captura       DATE NOT NULL,
    fecha_descarga      DATE DEFAULT CURRENT_DATE,
    resolucion_m        DECIMAL(6,2),
    bandas              VARCHAR(200),
    nubosidad_pct       DECIMAL(5,2),
    ruta_archivo        VARCHAR(500),
    extent_geom         GEOMETRY(Polygon, 4326),
    plataforma          VARCHAR(100),
    notas               TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_imagen_satelital_geom ON geografico.imagen_satelital USING GIST (extent_geom);

-- ============================================================
-- VUELO DE DRON (evento operativo)
-- Registra el vuelo como actividad de campo
-- ============================================================
CREATE TABLE geografico.vuelo_dron (
    id                  SERIAL PRIMARY KEY,
    fecha_vuelo         DATE NOT NULL,
    piloto              VARCHAR(150),
    modelo_dron         VARCHAR(100),        -- ej. DJI Mavic 3 Multispectral
    tipo_sensor         VARCHAR(50) CHECK (tipo_sensor IN ('RGB','multiespectral','termal','LiDAR')),
    altitud_vuelo_m     DECIMAL(7,2),
    solapamiento_pct    DECIMAL(5,2),
    area_cubierta_ha    DECIMAL(10,4),
    resolucion_cm_px    DECIMAL(6,2),
    num_imagenes        INTEGER,             -- total de fotos capturadas en el vuelo
    software_vuelo      VARCHAR(100),        -- ej. DJI Pilot 2, Pix4Dcapture
    condiciones_clima   TEXT,
    parcela_id          INTEGER REFERENCES geografico.parcela(id),
    area_vuelo          GEOMETRY(Polygon, 4326),
    notas               TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_vuelo_dron_geom ON geografico.vuelo_dron USING GIST (area_vuelo);

-- ============================================================
-- PRODUCTO PROCESADO DEL VUELO DE DRON
-- Cada vuelo genera múltiples productos:
-- ortomosaicos, DEM, bandas individuales e índices
--
-- Flujo completo:
-- vuelo_dron → producto_dron → ambiental.indice_vegetacion
--                                      ↓
--                              ambiental.serie_ndvi
--                                      ↓
--                           geografico.zona_prioritaria
-- ============================================================
CREATE TABLE geografico.producto_dron (
    id                      SERIAL PRIMARY KEY,
    vuelo_id                INTEGER REFERENCES geografico.vuelo_dron(id) NOT NULL,

    -- Tipo de producto
    tipo                    VARCHAR(50) CHECK (tipo IN (
                                'ortomosaico_rgb',
                                'ortomosaico_multiespectral',
                                'dem',              -- Modelo Digital de Elevación
                                'dsm',              -- Modelo Digital de Superficie
                                'banda_verde',
                                'banda_rojo',
                                'banda_red_edge',
                                'banda_nir',
                                'indice_ndvi',
                                'indice_ndwi',
                                'indice_gndvi',
                                'indice_ndre',      -- Normalized Difference Red Edge
                                'nube_puntos',      -- Point cloud LiDAR
                                'otro'
                            )) NOT NULL,

    -- Archivo generado
    ruta_archivo            VARCHAR(500) NOT NULL,
    formato_archivo         VARCHAR(20) CHECK (formato_archivo IN (
                                'tif','geotiff','jpg','png','las','laz','shp','otro'
                            )),
    tamaño_mb               DECIMAL(10,2),
    resolucion_cm_px        DECIMAL(6,2),
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
    indice_vegetacion_id    INTEGER,        -- FK a ambiental.indice_vegetacion

    notas                   TEXT,
    created_at              TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_producto_dron_extent ON geografico.producto_dron USING GIST (extent_geom);

-- Capa SIG temática
CREATE TABLE geografico.capa_sig (
    id                  SERIAL PRIMARY KEY,
    nombre              VARCHAR(200) NOT NULL,
    tipo                VARCHAR(50) CHECK (tipo IN (
                            'uso_suelo','cobertura_vegetal','zona_prioritaria',
                            'amenaza','hidrologia','edafologia',
                            'division_municipal','comunidades','otro')),
    fuente              VARCHAR(200),
    fecha_fuente        DATE,
    formato             VARCHAR(30) CHECK (formato IN ('shapefile','geojson','geopackage','raster','wms')),
    ruta_archivo        VARCHAR(500),
    url_descarga        TEXT,
    descripcion         TEXT,
    año_referencia      SMALLINT,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- Zona prioritaria de conservación (se llena en Etapa 2)
CREATE TABLE geografico.zona_prioritaria (
    id                          SERIAL PRIMARY KEY,
    nombre                      VARCHAR(200),
    nivel_prioridad             VARCHAR(20) CHECK (nivel_prioridad IN ('muy_alta','alta','media','baja')),
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
    created_at                  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_zona_prioritaria_geom ON geografico.zona_prioritaria USING GIST (poligono);

-- Cambio de uso de suelo (multitemporal)
CREATE TABLE geografico.cambio_uso_suelo (
    id              SERIAL PRIMARY KEY,
    año_inicial     SMALLINT NOT NULL,
    año_final       SMALLINT NOT NULL,
    clase_inicial   INTEGER REFERENCES catalogo.clase_uso_suelo(id),
    clase_final     INTEGER REFERENCES catalogo.clase_uso_suelo(id),
    superficie_ha   DECIMAL(12,4),
    fuente_datos    VARCHAR(200),
    municipio_id    INTEGER REFERENCES catalogo.municipio(id),
    poligono        GEOMETRY(MultiPolygon, 4326),
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_cambio_uso_suelo_geom ON geografico.cambio_uso_suelo USING GIST (poligono);
CREATE INDEX idx_cambio_uso_suelo_municipio ON geografico.cambio_uso_suelo(municipio_id);
CREATE INDEX idx_cambio_uso_suelo_clase_inicial ON geografico.cambio_uso_suelo(clase_inicial);
CREATE INDEX idx_cambio_uso_suelo_clase_final ON geografico.cambio_uso_suelo(clase_final);


-- Registro de visita de campo
CREATE TABLE geografico.visita_campo (
    id                  SERIAL PRIMARY KEY,
    fecha_visita        DATE NOT NULL,
    localidad_id        INTEGER REFERENCES catalogo.localidad(id),
    municipio_id        INTEGER REFERENCES catalogo.municipio(id),
    responsable_visita  VARCHAR(150),
    equipo              TEXT,
    num_productores     SMALLINT,
    num_muestras        SMALLINT,
    punto_inicio        GEOMETRY(Point, 4326),
    condiciones_campo   TEXT,
    observaciones       TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_visita_campo_punto ON geografico.visita_campo USING GIST (punto_inicio);
CREATE INDEX idx_visita_campo_localidad ON geografico.visita_campo(localidad_id);
CREATE INDEX idx_visita_campo_municipio ON geografico.visita_campo(municipio_id);


-- ============================================================
-- VISTA: inventario de productos por vuelo
-- ============================================================
CREATE VIEW geografico.v_inventario_dron AS
SELECT
    vd.id               AS vuelo_id,
    vd.fecha_vuelo,
    vd.modelo_dron,
    vd.tipo_sensor,
    vd.area_cubierta_ha,
    vd.resolucion_cm_px,
    vd.num_imagenes,
    par.nombre          AS parcela,
    mun.nombre          AS municipio,
    COUNT(pd.id)        AS total_productos,
    STRING_AGG(pd.tipo, ', ' ORDER BY pd.tipo) AS productos_generados,
    SUM(pd.tamaño_mb)   AS tamaño_total_mb,
    SUM(CASE WHEN pd.validado THEN 1 ELSE 0 END) AS productos_validados,
    BOOL_OR(pd.tipo = 'indice_ndvi')                AS tiene_ndvi,
    BOOL_OR(pd.tipo = 'indice_ndwi')                AS tiene_ndwi,
    BOOL_OR(pd.tipo = 'indice_gndvi')               AS tiene_gndvi,
    BOOL_OR(pd.tipo = 'dem')                        AS tiene_dem,
    BOOL_OR(pd.tipo = 'ortomosaico_rgb')            AS tiene_ortomosaico_rgb,
    BOOL_OR(pd.tipo = 'ortomosaico_multiespectral') AS tiene_ortomosaico_ms
FROM geografico.vuelo_dron vd
LEFT JOIN geografico.producto_dron pd   ON pd.vuelo_id = vd.id
LEFT JOIN geografico.parcela par        ON par.id = vd.parcela_id
LEFT JOIN social.productor p            ON p.id = par.productor_id
LEFT JOIN catalogo.municipio mun        ON mun.id = p.municipio_id
GROUP BY vd.id, vd.fecha_vuelo, vd.modelo_dron, vd.tipo_sensor,
         vd.area_cubierta_ha, vd.resolucion_cm_px, vd.num_imagenes,
         par.nombre, mun.nombre
ORDER BY vd.fecha_vuelo DESC;