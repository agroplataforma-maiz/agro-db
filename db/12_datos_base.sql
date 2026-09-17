

-- Estaciones meteorologicas virtuales (APIs)
-- Campos: nombre, tipo, fuente, municipio_id
INSERT INTO ambiental.estacion_meteorologica
    (nombre, tipo, fuente_informacion_id, municipio_id)
VALUES
    ('NASA POWER - Ciudad Valles',   'virtual', (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'NASA'),  (SELECT id FROM catalogo.municipio WHERE nombre = 'Ciudad Valles')),
    ('NASA POWER - Tamazunchale',    'virtual', (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'NASA'),  (SELECT id FROM catalogo.municipio WHERE nombre = 'Tamazunchale')),
    ('NASA POWER - Tamuin',          'virtual', (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'NASA'),  (SELECT id FROM catalogo.municipio WHERE nombre = 'Tamuín')),
    ('CONAGUA SMN - Ciudad Valles',  'virtual', (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'CONAGUA'),     (SELECT id FROM catalogo.municipio WHERE nombre = 'Ciudad Valles')),
    ('OpenWeather - Aquismón',       'virtual', (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'OpenWeather'), (SELECT id FROM catalogo.municipio WHERE nombre = 'Aquismón')),
    ('Copernicus ERA5 - Huasteca',   'virtual', (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'Copernicus'),  (SELECT id FROM catalogo.municipio WHERE nombre = 'Huasteca Potosina'));
/*
-- Capas SIG base
-- Campo: anio_referencia 
INSERT INTO geo.capa_sig
    (nombre, tipo_capa_sig_id, fuente_informacion_id, anio_referencia, formato_archivo_id, url_descarga, descripcion)
VALUES
    ('Municipios Huasteca Potosina (INEGI 2024)',
     (SELECT id FROM catalogo.tipo_capa_sig WHERE LOWER(nombre) = 'división municipal' OR LOWER(nombre) = 'division municipal' LIMIT 1),
     (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'INEGI'),
     2024,
     (SELECT id FROM catalogo.formato_archivo WHERE nombre = 'geojson'),
     'https://www.inegi.org.mx/app/biblioteca/ficha.html?upc=702825292805',
     'Marco Geoestadistico Nacional, 20 municipios de la Huasteca Potosina'),

    ('Localidades Huasteca Potosina (INEGI 2024)',
     (SELECT id FROM catalogo.tipo_capa_sig WHERE LOWER(nombre) = 'comunidades' LIMIT 1),
     (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'INEGI'),
     2024,
     (SELECT id FROM catalogo.formato_archivo WHERE nombre = 'geojson'),
     'https://www.inegi.org.mx/app/areasgeograficas/',
     'Catalogo de localidades de los 20 municipios de la Huasteca'),

    ('Uso de suelo y vegetacion Serie VII (INEGI 2021)',
     (SELECT id FROM catalogo.tipo_capa_sig WHERE LOWER(nombre) = 'uso de suelo' OR LOWER(nombre) = 'uso_suelo' LIMIT 1),
     (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'INEGI'),
     2021,
     (SELECT id FROM catalogo.formato_archivo WHERE nombre = 'shapefile'),
     'https://www.inegi.org.mx/temas/usosuelo/',
     'Descarga manual requerida. Ver DESCARGA_MANUAL_INEGI.txt'),

    ('Red Hidrografica Nacional (INEGI 2021)',
     (SELECT id FROM catalogo.tipo_capa_sig WHERE LOWER(nombre) = 'hidrología' OR LOWER(nombre) = 'hidrologia' LIMIT 1),
     (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'INEGI'),
     2021,
     (SELECT id FROM catalogo.formato_archivo WHERE nombre = 'shapefile'),
     'https://www.inegi.org.mx/temas/hidrografia/',
     'Descarga manual requerida. Ver DESCARGA_MANUAL_INEGI.txt'),

    ('Edafologia tipos de suelo (INEGI 2014)',
     (SELECT id FROM catalogo.tipo_capa_sig WHERE LOWER(nombre) = 'edafología' OR LOWER(nombre) = 'edafologia' LIMIT 1),
     (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'INEGI'),
     2014,
     (SELECT id FROM catalogo.formato_archivo WHERE nombre = 'shapefile'),
     'https://www.inegi.org.mx/temas/edafologia/',
     'Descarga manual requerida. Ver DESCARGA_MANUAL_INEGI.txt'),

    ('Distribucion de maices nativos y razas 1966-1990 (CONABIO 2011)',
     (SELECT id FROM catalogo.tipo_capa_sig WHERE LOWER(nombre) = 'zona prioritaria' LIMIT 1),
     (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'CONABIO'),
     2011,
     (SELECT id FROM catalogo.formato_archivo WHERE nombre = 'geojson'),
     'https://www.biodiversidad.gob.mx/diversidad/maices',
     'Cuadricula 0.25 grados con numero de razas por celda'),

    ('Centros de origen y diversidad genetica del maiz (CONABIO 2012)',
     (SELECT id FROM catalogo.tipo_capa_sig WHERE LOWER(nombre) = 'zona prioritaria' LIMIT 1),
     (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'CONABIO'),
     2012,
     (SELECT id FROM catalogo.formato_archivo WHERE nombre = 'geojson'),
     'https://www.biodiversidad.gob.mx/diversidad/maices/centrosOrigen',
     'Zonas de maxima proteccion contra transgenicos. DOF 02/11/2012'),

    ('Areas Naturales Protegidas Federales (CONANP/CONABIO 2024)',
     (SELECT id FROM catalogo.tipo_capa_sig WHERE LOWER(nombre) = 'zona prioritaria' LIMIT 1),
     (SELECT id FROM catalogo.fuente_informacion WHERE nombre = 'CONANP'),
     2024,
     (SELECT id FROM catalogo.formato_archivo WHERE nombre = 'geojson'),
     'https://sig.conanp.gob.mx/website/pagsig/',
     '232 ANPs federales. Incluye Sierra del Abra Tanchipa en la Huasteca');
*/
