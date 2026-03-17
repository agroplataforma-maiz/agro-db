-- ============================================================
-- DATOS BASE INICIALES
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Version: 3.1
--
-- NOTA: Los municipios, lenguas y pueblos originarios
-- están en 02_catalogo.sql
-- Este script contiene solo datos operacionales iniciales.
-- ============================================================

-- Ciclos agricolas
-- Campo: año (no anno)
INSERT INTO agronomico.ciclo_agricola (año, temporada, fecha_inicio, fecha_fin)
VALUES
    (2025, 'Primavera-Verano', '2025-04-01', '2025-10-31'),
    (2025, 'Otoño-Invierno',   '2025-11-01', '2026-03-31');

-- Practicas agricolas
INSERT INTO social.practica_agricola (nombre, tipo) VALUES
    ('Milpa',                           'tradicional'),
    ('Roza-tumba-quema',                'tradicional'),
    ('Asociacion maiz-frijol',          'tradicional'),
    ('Uso de semilla propia',           'tradicional'),
    ('Calendario agricola tradicional', 'tradicional'),
    ('Abono organico',                  'agroecologica'),
    ('Composta',                        'agroecologica'),
    ('Control biologico de plagas',     'agroecologica'),
    ('Fertilizante quimico',            'convencional'),
    ('Riego por gravedad',              'convencional'),
    ('Labranza minima',                 'mixta'),
    ('Rotacion de cultivos',            'mixta');

-- Estaciones meteorologicas virtuales (APIs)
-- Campos: nombre, tipo, fuente, municipio_id
INSERT INTO ambiental.estacion_meteorologica
    (nombre, tipo, fuente, municipio_id)
VALUES
    ('NASA POWER - Ciudad Valles',   'virtual', 'NASA_POWER',  (SELECT id FROM catalogo.municipio WHERE nombre = 'Ciudad Valles')),
    ('NASA POWER - Tamazunchale',    'virtual', 'NASA_POWER',  (SELECT id FROM catalogo.municipio WHERE nombre = 'Tamazunchale')),
    ('NASA POWER - Tamuin',          'virtual', 'NASA_POWER',  (SELECT id FROM catalogo.municipio WHERE nombre = 'Tamuín')),
    ('CONAGUA SMN - Ciudad Valles',  'virtual', 'CONAGUA',     (SELECT id FROM catalogo.municipio WHERE nombre = 'Ciudad Valles')),
    ('OpenWeather - Aquismón',       'virtual', 'OpenWeather', (SELECT id FROM catalogo.municipio WHERE nombre = 'Aquismón')),
    ('Copernicus ERA5 - Huasteca',   'virtual', 'Copernicus',  (SELECT id FROM catalogo.municipio WHERE nombre = 'Huasteca Potosina'));

-- Capas SIG base
-- Campo: año_referencia (no anno_referencia)
INSERT INTO geografico.capa_sig
    (nombre, tipo, fuente, año_referencia, formato, url_descarga, descripcion)
VALUES
    ('Municipios Huasteca Potosina (INEGI 2024)',
     'division_municipal', 'INEGI', 2024, 'geojson',
     'https://www.inegi.org.mx/app/biblioteca/ficha.html?upc=702825292805',
     'Marco Geoestadistico Nacional, 20 municipios de la Huasteca Potosina'),

    ('Localidades Huasteca Potosina (INEGI 2024)',
     'comunidades', 'INEGI', 2024, 'geojson',
     'https://www.inegi.org.mx/app/areasgeograficas/',
     'Catalogo de localidades de los 20 municipios de la Huasteca'),

    ('Uso de suelo y vegetacion Serie VII (INEGI 2021)',
     'uso_suelo', 'INEGI', 2021, 'shapefile',
     'https://www.inegi.org.mx/temas/usosuelo/',
     'Descarga manual requerida. Ver DESCARGA_MANUAL_INEGI.txt'),

    ('Red Hidrografica Nacional (INEGI 2021)',
     'hidrologia', 'INEGI', 2021, 'shapefile',
     'https://www.inegi.org.mx/temas/hidrografia/',
     'Descarga manual requerida. Ver DESCARGA_MANUAL_INEGI.txt'),

    ('Edafologia tipos de suelo (INEGI 2014)',
     'edafologia', 'INEGI', 2014, 'shapefile',
     'https://www.inegi.org.mx/temas/edafologia/',
     'Descarga manual requerida. Ver DESCARGA_MANUAL_INEGI.txt'),

    ('Distribucion de maices nativos y razas 1966-1990 (CONABIO 2011)',
     'zona_prioritaria', 'CONABIO', 2011, 'geojson',
     'https://www.biodiversidad.gob.mx/diversidad/maices',
     'Cuadricula 0.25 grados con numero de razas por celda'),

    ('Centros de origen y diversidad genetica del maiz (CONABIO 2012)',
     'zona_prioritaria', 'CONABIO', 2012, 'geojson',
     'https://www.biodiversidad.gob.mx/diversidad/maices/centrosOrigen',
     'Zonas de maxima proteccion contra transgenicos. DOF 02/11/2012'),

    ('Areas Naturales Protegidas Federales (CONANP/CONABIO 2024)',
     'zona_prioritaria', 'CONANP', 2024, 'geojson',
     'https://sig.conanp.gob.mx/website/pagsig/',
     '232 ANPs federales. Incluye Sierra del Abra Tanchipa en la Huasteca');