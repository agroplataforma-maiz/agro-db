-- ============================================================
-- DATOS BASE INICIALES
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Version: 1
-- ============================================================

-- ============================================================
-- 1. CATALOGO: razas de maíz
-- ============================================================

INSERT INTO catalogo.raza_maiz
    (nombre, es_nativa, created_at, updated_at)
VALUES 
    ('Ancho', TRUE, NOW(), NOW()),
    ('Arrocillo Amarillo', TRUE, NOW(), NOW()),
    ('Bolita', TRUE, NOW(), NOW()),
    ('Cacahuacintle', TRUE, NOW(), NOW()),
    ('Celaya', TRUE, NOW(), NOW()),
    ('Chalqueño', TRUE, NOW(), NOW()),
    ('Conejo', TRUE, NOW(), NOW()),
    ('Coscomatepec', TRUE, NOW(), NOW()),
    ('Cónico', TRUE, NOW(), NOW()),
    ('Cónico Norteño', TRUE, NOW(), NOW()),
    ('Dzit Bacal', TRUE, NOW(), NOW()),
    ('Elotes Cónicos', TRUE, NOW(), NOW()),
    ('Elotes Occidentales', TRUE, NOW(), NOW()),
    ('Mushito', TRUE, NOW(), NOW()),
    ('Nal-tel', TRUE, NOW(), NOW()),
    ('Nal-tel de Altura', TRUE, NOW(), NOW()),
    ('Negrito', TRUE, NOW(), NOW()),
    ('Olotillo', TRUE, NOW(), NOW()),
    ('Olotón', TRUE, NOW(), NOW()),
    ('Onaveño', TRUE, NOW(), NOW()),
    ('Palomero Toluqueño', TRUE, NOW(), NOW()),
    ('Pepitilla', TRUE, NOW(), NOW()),
    ('Ratón', TRUE, NOW(), NOW()),
    ('Tabloncillo', TRUE, NOW(), NOW()),
    ('Tepecintle', TRUE, NOW(), NOW()),
    ('Tuxpeño', TRUE, NOW(), NOW()),
    ('Tuxpeño Norteño', TRUE, NOW(), NOW()),
    ('Vandeño', TRUE, NOW(), NOW()),
    ('Zapalote Grande', TRUE, NOW(), NOW());

-- ============================================================
-- 2. CATALOGO: colores de grano
-- ============================================================
INSERT INTO catalogo.color_grano 
    (nombre, es_nativo, created_at, updated_at) 
VALUES 
    ('Amarillo B', TRUE, NOW(), NOW()),
    ('Amarillo Claro', TRUE, NOW(), NOW()),
    ('Amarillo Medio', TRUE, NOW(), NOW()),
    ('Amarillo Naranja F', TRUE, NOW(), NOW()),
    ('Azul K', TRUE, NOW(), NOW()),
    ('Azul Oscuro L', TRUE, NOW(), NOW()),
    ('Blanco', TRUE, NOW(), NOW()),
    ('Blanco Cremoso', TRUE, NOW(), NOW()),
    ('Blanco Puro', TRUE, NOW(), NOW()),
    ('Café E', TRUE, NOW(), NOW()),
    ('Crema', TRUE, NOW(), NOW()),
    ('Jaspeado D', TRUE, NOW(), NOW()),
    ('Morado C', TRUE, NOW(), NOW()),
    ('Naranja', TRUE, NOW(), NOW()),
    ('Negro', TRUE, NOW(), NOW()),
    ('Rojo I', TRUE, NOW(), NOW()),
    ('Rojo Naranja J', TRUE, NOW(), NOW()),
    ('Rojo Oscuro', TRUE, NOW(), NOW());

-- ============================================================
-- 3. CATALOGO: estado de conservación
-- ============================================================
INSERT INTO catalogo.estado_conservacion 
    (nombre, descripcion, nivel_riesgo, created_at, updated_at) 
VALUES
    ('Activo', 'Presente y en uso localmente', 1, NOW(), NOW()),
    ('En riesgo', 'Presente pero con riesgo de desaparecer', 3, NOW(), NOW()),
    ('Semilla guardada', 'No cultivado, pero semilla conservada', 2, NOW(), NOW()),
    ('Extinto local', 'Ya no existe en la región', 5, NOW(), NOW()),
    ('Desconocido', 'No se tiene información suficiente', NULL, NOW(), NOW()),
    ('Reintroducido', 'Reincorporado tras haber desaparecido', 2, NOW(), NOW()),
    ('En rescate', 'En proceso de rescate o multiplicación', 4, NOW(), NOW());

-- ============================================================
-- 4. CATALOGO: clases de uso de maíz
-- ============================================================
INSERT INTO catalogo.uso_maiz 
    (nombre, descripcion, created_at, updated_at) 
VALUES 
    ('Atole', 'Bebida tradicional mexicana a base de maíz cocido y molido, endulzada y servida caliente.', NOW(), NOW()),
    ('Nixtamal', 'Masa obtenida al cocer el grano de maíz en agua con cal, base para tortillas y otros alimentos.', NOW(), NOW()),
    ('Pinole', 'Harina de maíz tostado y molido, utilizada para preparar bebidas y alimentos energéticos.', NOW(), NOW()),
    ('Tamal', 'Alimento tradicional preparado con masa de maíz rellena y cocida en hojas.', NOW(), NOW()),
    ('Tortilla', 'Disco delgado hecho de masa de maíz nixtamalizado, base de la alimentación mexicana.', NOW(), NOW()),
    ('Elote', 'Mazorca de maíz tierna, consumida hervida, asada o en platillos.', NOW(), NOW()),
    ('Pozole', 'Platillo tradicional a base de maíz nixtamalizado y carne, servido en caldo.', NOW(), NOW()),
    ('Totopo', 'Tortilla de maíz deshidratada y horneada o frita, utilizada como botana o acompañamiento.', NOW(), NOW()),
    ('Forraje', 'Material vegetal, como hojas y tallos de maíz, utilizado para alimentar ganado.', NOW(), NOW()),
    ('Grano', 'Semilla de maíz seca, base para la elaboración de diversos alimentos y productos.', NOW(), NOW()),
    ('Hoja', 'Hojas de la planta de maíz, empleadas para envolver alimentos como tamales.', NOW(), NOW()),
    ('Abono', 'Uso del residuo vegetal del maíz para enriquecer la tierra agrícola.', NOW(), NOW()),
    ('Combustible', 'Uso de residuos de maíz (olote, hojas) como fuente de energía para cocinar o calentar.', NOW(), NOW()),
    ('Harina', 'Producto obtenido de la molienda del grano de maíz, base para atole, tortillas y otros.', NOW(), NOW()),
    ('Huacholes', 'Alimento tradicional preparado con maíz reventado o tostado.', NOW(), NOW()),
    ('Germoplasma en conservación', 'Material genético de maíz almacenado para preservar la diversidad biológica.', NOW(), NOW()),
    ('Otro', 'Cualquier otro uso no especificado en este catálogo.', NOW(), NOW()),
    ('Semilla', 'Grano de maíz destinado a la siembra para la producción de nuevas plantas.', NOW(), NOW());

-- ============================================================
-- 5. CATALOGO: tipos de práctica agrícola
-- ============================================================
INSERT INTO catalogo.tipo_practica 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Tradicional', 'Prácticas agrícolas ancestrales, sin uso de insumos químicos ni maquinaria.', NOW(), NOW()),
    ('Agroecológica', 'Prácticas sostenibles, con enfoque en biodiversidad y manejo integrado.', NOW(), NOW()),
    ('Convencional', 'Uso intensivo de insumos químicos y maquinaria.', NOW(), NOW()),
    ('Mixta', 'Combinación de prácticas tradicionales y modernas.', NOW(), NOW());

-- =============================================================
-- 6. Catalogo: prácticas agrícolas
-- =============================================================
INSERT INTO catalogo.practica_agricola 
    (nombre, descripcion, tipo_id) 
VALUES
    ('Milpa', 'Sistema tradicional de policultivo de maíz, frijol y calabaza.', 1),
    ('Roza-tumba-quema', 'Preparación del terreno mediante corte y quema de vegetación.', 1),
    ('Asociación maíz-frijol', 'Cultivo conjunto de maíz y frijol para aprovechar sinergias.', 2),
    ('Uso de semilla propia', 'Selección y resiembra de semilla de la cosecha anterior.', 1),
    ('Calendario agrícola tradicional', 'Siembra y cosecha siguiendo ciclos lunares y costumbres locales.', 1),
    ('Abono orgánico', 'Aplicación de composta, estiércol u otros abonos naturales.', 2),
    ('Composta', 'Producción y uso de composta para mejorar el suelo.', 2),
    ('Control biológico de plagas', 'Uso de organismos benéficos para controlar plagas.', 2),
    ('Fertilizante químico', 'Aplicación de fertilizantes sintéticos para aumentar la producción.', 3),
    ('Riego por gravedad', 'Distribución de agua por canales abiertos.', 1),
    ('Labranza mínima', 'Reducción de la remoción del suelo para conservar humedad.', 2),
    ('Rotación de cultivos', 'Alternancia de diferentes cultivos para mejorar el suelo.', 2),
    ('Riego por aspersión', 'Aplicación de agua en forma de lluvia artificial.', 3),
    ('Riego por goteo', 'Aplicación localizada de agua directamente a la raíz.', 2),
    ('Monocultivo', 'Cultivo de una sola especie en grandes extensiones.', 3),
    ('Quema de rastrojo', 'Eliminación de residuos de cosecha mediante quema.', 1),
    ('Cobertura vegetal', 'Mantenimiento de plantas vivas o residuos sobre el suelo.', 2),
    ('Aplicación de agroquímicos', 'Uso de herbicidas, insecticidas o fungicidas sintéticos.', 3),
    ('Manejo integrado de plagas', 'Uso combinado de métodos biológicos, culturales y químicos para el control de plagas.', 4);

-- ============================================================
-- 7. CATALOGO: sistema de manejo
-- ============================================================
INSERT INTO catalogo.sistema_manejo 
    (nombre, descripcion, es_tradicional, created_at, updated_at) 
VALUES
    ('Tradicional', 'Prácticas agrícolas tradicionales, bajo uso de insumos externos', TRUE, NOW(), NOW()),
    ('Mecanizado', 'Uso de maquinaria agrícola y técnicas modernas', FALSE, NOW(), NOW()),
    ('Agroecologico', 'Enfoque sustentable, integración de prácticas ecológicas', TRUE, NOW(), NOW()),
    ('Mixto', 'Combinación de prácticas tradicionales y modernas', NULL, NOW(), NOW()),
    ('Orgánico', 'Producción sin agroquímicos, certificada o en transición', FALSE, NOW(), NOW()),  
    ('Intensivo', 'Alta densidad de siembra y uso intensivo de insumos', FALSE, NOW(), NOW()),
    ('Desconocido', 'No especificado o no aplica', NULL, NOW(), NOW());

-- ============================================================
-- 8. CATALOGO: sistema de cultivo
-- ============================================================
INSERT INTO catalogo.sistema_cultivo 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Temporal', 'Cultivo de temporal, depende de lluvias', NOW(), NOW()),
    ('Riego', 'Cultivo bajo riego', NOW(), NOW()),
    ('Mixto', 'Combinación de temporal y riego', NOW(), NOW()),
    ('Secano', 'Cultivo en zonas áridas, sin riego', NOW(), NOW()),
    ('Humedal', 'Cultivo en zonas húmedas o inundables', NOW(), NOW()),
    ('Desconocido', 'No especificado o no aplica', NOW(), NOW());

-- ============================================================
-- 9. CATALOGO: método de almacenamiento
-- ============================================================

INSERT INTO catalogo.metodo_almacenamiento 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Costal yute', 'Costal de yute tradicional', NOW(), NOW()),
    ('Bote metálico', 'Bote o tambor metálico', NOW(), NOW()),
    ('Troje', 'Troje de madera o adobe', NOW(), NOW()),
    ('Silo hermético', 'Silo hermético, metálico o plástico', NOW(), NOW()),
    ('Tinaco', 'Tinaco o recipiente grande de plástico', NOW(), NOW()),
    ('Olla barro', 'Olla o cántaro de barro', NOW(), NOW()),
    ('Hornilla', 'Almacenado en la hornilla o cocina', NOW(), NOW()),
    ('Otro', 'Otro método de almacenamiento', NOW(), NOW()),
    ('Desconocido', 'No especificado o no aplica', NOW(), NOW());

-- ============================================================
-- 10. CATALOGO: tipos de fenotipo
-- ============================================================
INSERT INTO catalogo.tipo_fenotipo 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Raza', 'Fenotipo asociado a la raza de maíz', NOW(), NOW()),
    ('Color de grano', 'Fenotipo asociado al color del grano', NOW(), NOW()),
    ('Tamaño de planta', 'Fenotipo asociado al tamaño de la planta', NOW(), NOW()),
    ('Forma de mazorca', 'Fenotipo asociado a la forma de la mazorca', NOW(), NOW()),
    ('Textura del grano', 'Fenotipo asociado a la textura del grano', NOW(), NOW()),
    ('Otro', 'Otro tipo de fenotipo no especificado', NOW(), NOW());

-- ============================================================
-- 11. CATALOGO: etapa fenológica del maíz
-- ============================================================
INSERT INTO catalogo.etapa_fenologica 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Germinación', 'Inicio del desarrollo, emergencia de la plántula', NOW(), NOW()),
    ('Planta joven', 'Crecimiento inicial, hojas jóvenes', NOW(), NOW()),
    ('Vegetativo medio', 'Desarrollo vegetativo intermedio', NOW(), NOW()),
    ('Prefloración', 'Etapa previa a la floración, formación de espigas', NOW(), NOW()),
    ('Floración', 'Aparición de flores y polinización', NOW(), NOW()),
    ('Grano lechoso', 'Grano en formación, contenido lechoso', NOW(), NOW()),
    ('Grano masoso', 'Grano en maduración, textura masosa', NOW(), NOW()),
    ('Madurez', 'Grano completamente maduro, listo para cosecha', NOW(), NOW()),
    ('Cosecha', 'Recolección del maíz', NOW(), NOW());

-- ============================================================
-- DATOS INICIALES
-- Estado de San Luis Potosí
-- ============================================================
-- ============================================================
-- 12. ESTADO
-- ============================================================

INSERT INTO catalogo.estado 
    (clave_inegi, nombre, abreviatura)
VALUES 
    ('24', 'San Luis Potosí', 'SLP');

-- ============================================================
-- 13. MUNICIPIO
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
-- 17. CATALOGO: clases de uso de suelo
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
-- 18. CATALOGO: tipos de eventos climáticos
-- ============================================================
INSERT INTO catalogo.tipo_evento_climatico 
    (nombre, descripcion, created_at, updated_at)
VALUES
    ('Sequía', 'Periodo prolongado de escasez de lluvias', NOW(), NOW()),
    ('Inundación', 'Exceso de agua por lluvias intensas o desbordamiento de ríos', NOW(), NOW()),
    ('Helada', 'Descenso de temperatura por debajo de 0°C que afecta cultivos', NOW(), NOW()),
    ('Granizada', 'Precipitación de granizo que puede dañar cultivos', NOW(), NOW()),
    ('Viento fuerte', 'Rachas de viento que pueden causar daños físicos a las plantas', NOW(), NOW()),
    ('Ola de calor', 'Periodo de temperaturas extremadamente altas que afecta el desarrollo del cultivo', NOW(), NOW()),
    ('Otro', 'Otro tipo de evento climático no especificado', NOW(), NOW());

-- ============================================================
-- 19. CATALOGO: variables ambientales
-- ============================================================
INSERT INTO catalogo.variable_ambiental 
    (nombre, descripcion, unidad, created_at, updated_at)
VALUES
    ('Temperatura', 'Temperatura ambiente durante el ciclo de cultivo', '°C', NOW(), NOW()),
    ('Precipitación', 'Cantidad de lluvia durante el ciclo de cultivo', 'mm', NOW(), NOW()),
    ('Humedad relativa', 'Porcentaje de humedad en el aire durante el ciclo de cultivo', '%', NOW(), NOW()),
    ('Velocidad del viento', 'Velocidad del viento durante el ciclo de cultivo', 'km/h', NOW(), NOW()),
    ('Radiación solar', 'Cantidad de radiación solar recibida durante el ciclo de cultivo', 'MJ/m²/día', NOW(), NOW()),
    ('Otro', 'Otra variable ambiental no especificada', NULL, NOW(), NOW());

-- ============================================================
-- 20. CATALOGO: tipo de amenaza
-- ============================================================
INSERT INTO catalogo.tipo_amenaza 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Expansión agrícola industrial', 'Conversión de tierras a agricultura industrial', NOW(), NOW()),
    ('Ganadería extensiva', 'Prácticas ganaderas que afectan la cobertura vegetal', NOW(), NOW()),
    ('Deforestación', 'Pérdida de cobertura forestal por actividades humanas', NOW(), NOW()),
    ('Presencia de transgénicos', 'Introducción de semillas transgénicas en la región', NOW(), NOW()),
    ('Contaminación química', 'Uso excesivo de agroquímicos o contaminantes', NOW(), NOW()),
    ('Sequía prolongada', 'Periodos largos sin lluvias', NOW(), NOW()),
    ('Inundación', 'Afectaciones por exceso de agua o lluvias intensas', NOW(), NOW()),
    ('Helada atípica', 'Eventos de helada fuera de temporada', NOW(), NOW()),
    ('Plaga emergente', 'Aparición de nuevas plagas o enfermedades', NOW(), NOW()),
    ('Abandono del campo', 'Reducción de la actividad agrícola por abandono', NOW(), NOW()),
    ('Migración de productores', 'Salida de productores hacia otras regiones', NOW(), NOW()),
    ('Otra', 'Otra amenaza no especificada', NOW(), NOW());

-- ============================================================
-- 21. CATALOGO: tipos de productor
-- ============================================================
INSERT INTO catalogo.tipo_productor 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Pequeño', 'Productor con pequeña escala de producción, generalmente para autoconsumo o venta local', NOW(), NOW()),
    ('Mediano', 'Productor con mediana escala, puede comercializar parte de su producción', NOW(), NOW()),
    ('Subsistencia', 'Productor cuya producción es principalmente para el consumo familiar, con recursos limitados', NOW(), NOW()),
    ('Grande', 'Productor con gran escala de producción, orientado principalmente a la comercialización', NOW(), NOW()),
    ('Ejidal', 'Productor que trabaja tierras de propiedad ejidal', NOW(), NOW()),
    ('Comunal', 'Productor que trabaja tierras de propiedad comunal', NOW(), NOW()),
    ('Familiar', 'Producción gestionada principalmente por la familia', NOW(), NOW()),
    ('Empresarial', 'Productor con organización empresarial o figura legal formal', NOW(), NOW()),
    ('Orgánico', 'Productor certificado o en transición a producción orgánica', NOW(), NOW()),
    ('Tradicional', 'Productor que utiliza prácticas tradicionales o ancestrales', NOW(), NOW());

-- ============================================================
-- 22. LENGUA ORIGINARIA
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
-- 23. PUEBLO ORIGINARIO
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
-- 24. CATALOGO: tipo de ritual agrícola
-- ============================================================
INSERT INTO catalogo.tipo_ritual_agricola 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Siembra', 'Ritual relacionado con el inicio de la siembra', NOW(), NOW()),
    ('Crecimiento', 'Ritual para favorecer el crecimiento del cultivo', NOW(), NOW()),
    ('Cosecha', 'Ritual de agradecimiento o petición durante la cosecha', NOW(), NOW()),
    ('Almacenamiento', 'Ritual para la protección del grano almacenado', NOW(), NOW()),
    ('Intercambio de semillas', 'Ritual asociado al intercambio de semillas', NOW(), NOW()),
    ('Petición de lluvia', 'Ritual para pedir lluvias favorables', NOW(), NOW()),
    ('Agradecimiento', 'Ritual de agradecimiento por la cosecha o el ciclo agrícola', NOW(), NOW()),
    ('Otro', 'Otro tipo de ritual agrícola no especificado', NOW(), NOW());

-- ============================================================
-- 25. CATALOGO: tipo de narrativa oral
-- ============================================================
INSERT INTO catalogo.tipo_narrativa_oral 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Mito de origen', 'Narración mítica sobre el origen de algo o alguien', NOW(), NOW()),
    ('Leyenda', 'Relato tradicional con base histórica o fantástica', NOW(), NOW()),
    ('Cuento', 'Narración breve de hechos ficticios o reales', NOW(), NOW()),
    ('Refrán', 'Expresión popular de sabiduría o consejo', NOW(), NOW()),
    ('Canción', 'Composición musical tradicional o popular', NOW(), NOW()),
    ('Oración agrícola', 'Oración o plegaria relacionada con la agricultura', NOW(), NOW()),
    ('Testimonio', 'Relato de experiencia personal o colectiva', NOW(), NOW()),
    ('Otro', 'Otro tipo de narrativa oral no especificada', NOW(), NOW());

-- ============================================================
-- 26. CATALOGO: categoría de saber agrícola
-- ============================================================
INSERT INTO catalogo.categoria_saber_agricola 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Preparación de suelo', 'Prácticas para preparar el suelo antes de la siembra', NOW(), NOW()),
    ('Selección de semilla', 'Selección y tratamiento de semillas', NOW(), NOW()),
    ('Siembra', 'Prácticas relacionadas con la siembra', NOW(), NOW()),
    ('Manejo de cultivo', 'Manejo y cuidado del cultivo durante su desarrollo', NOW(), NOW()),
    ('Control de plagas tradicional', 'Control de plagas y enfermedades con métodos tradicionales', NOW(), NOW()),
    ('Cosecha', 'Prácticas de cosecha y recolección', NOW(), NOW()),
    ('Almacenamiento', 'Métodos de almacenamiento de la cosecha', NOW(), NOW()),
    ('Predicción del clima', 'Predicción y observación del clima', NOW(), NOW()),
    ('Asociación de plantas', 'Asociación de cultivos y plantas', NOW(), NOW()),
    ('Uso medicinal', 'Uso medicinal de plantas asociadas al cultivo', NOW(), NOW()),
    ('Calendario agrícola', 'Uso de calendarios agrícolas tradicionales', NOW(), NOW()),
    ('Otro', 'Otra categoría no especificada', NOW(), NOW());

-- ============================================================
-- 27. CATALOGO: ocasión de uso o consumo
-- ============================================================
INSERT INTO catalogo.ocasion 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Cotidiana', 'Uso o consumo en la vida diaria', NOW(), NOW()),
    ('Festiva', 'Uso o consumo en fiestas o celebraciones', NOW(), NOW()),
    ('Ritual', 'Uso o consumo en rituales o ceremonias', NOW(), NOW()),
    ('Medicinal', 'Uso con fines medicinales o curativos', NOW(), NOW()),
    ('Intercambio', 'Uso en contextos de trueque o intercambio', NOW(), NOW()),
    ('Otra', 'Otra ocasión no especificada', NOW(), NOW());

-- ============================================================
-- 28. CATALOGO: mecanismo de transmisión de saberes
-- ============================================================
INSERT INTO catalogo.mecanismo_transmision 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Práctica directa', 'Aprendizaje mediante la práctica directa en el campo', NOW(), NOW()),
    ('Narración oral', 'Transmisión de saberes a través de relatos orales', NOW(), NOW()),
    ('Participación ritual', 'Aprendizaje mediante la participación en rituales agrícolas', NOW(), NOW()),
    ('Escuela comunitaria', 'Transmisión formal en espacios educativos comunitarios', NOW(), NOW()),
    ('Milpa familiar', 'Aprendizaje y transmisión en el contexto de la milpa familiar', NOW(), NOW()),
    ('Otro', 'Otro mecanismo de transmisión no especificado', NOW(), NOW());

-- ============================================================
-- 29. CATALOGO: vínculo con el maíz
-- ============================================================
INSERT INTO catalogo.vinculo_maiz 
(nombre, descripcion, created_at, updated_at) 
VALUES
    ('Origen del maíz', 'Relato o conocimiento sobre el origen del maíz', NOW(), NOW()),
    ('Manejo del cultivo', 'Prácticas y saberes sobre el manejo del cultivo de maíz', NOW(), NOW()),
    ('Selección de semilla', 'Conocimientos y criterios para la selección de semilla', NOW(), NOW()),
    ('Cosmovisión agrícola', 'Relación simbólica, espiritual o ritual con el maíz', NOW(), NOW()),
    ('Identidad cultural', 'El maíz como elemento de identidad cultural', NOW(), NOW()),
    ('Otro', 'Otro tipo de vínculo con el maíz no especificado', NOW(), NOW());

-- ============================================================
-- 30. CATALOGO: tipo producto de dron 
-- ============================================================
INSERT INTO catalogo.tipo_producto_dron 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Ortomosaico RGB', 'Ortomosaico generado con imágenes RGB', NOW(), NOW()),
    ('Ortomosaico Multiespectral', 'Ortomosaico generado con imágenes multiespectrales', NOW(), NOW()),
    ('DEM', 'Modelo Digital de Elevación', NOW(), NOW()),
    ('DSM', 'Modelo Digital de Superficie', NOW(), NOW()),
    ('Banda Verde', 'Capa de banda verde', NOW(), NOW()),
    ('Banda Rojo', 'Capa de banda rojo', NOW(), NOW()),
    ('Banda Red Edge', 'Capa de banda red edge', NOW(), NOW()),
    ('Banda NIR', 'Capa de banda infrarrojo cercano (NIR)', NOW(), NOW()),
    ('Indice NDVI', 'Índice de vegetación NDVI', NOW(), NOW()),
    ('Indice NDWI', 'Índice de agua NDWI', NOW(), NOW()),
    ('Indice GNDVI', 'Índice GNDVI', NOW(), NOW()),
    ('Indice NDRE', 'Índice NDRE (Normalized Difference Red Edge)', NOW(), NOW()),
    ('Nube de puntos', 'Nube de puntos LiDAR', NOW(), NOW()),
    ('Otro', 'Otro tipo de producto', NOW(), NOW());

-- ============================================================
-- 31. CATALOGO: formato de archivo 
-- ============================================================
INSERT INTO catalogo.formato_archivo
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('tif', 'Archivo de imagen georreferenciada TIFF', NOW(), NOW()),
    ('geotiff', 'GeoTIFF, formato estándar para datos raster geoespaciales', NOW(), NOW()),
    ('jpg', 'Imagen JPEG', NOW(), NOW()),
    ('png', 'Imagen PNG', NOW(), NOW()),
    ('las', 'Archivo de nube de puntos LiDAR (LAS)', NOW(), NOW()),
    ('laz', 'Archivo comprimido de nube de puntos LiDAR (LAZ)', NOW(), NOW()),
    ('shp', 'Shapefile, formato vectorial ESRI', NOW(), NOW()),
    ('otro', 'Otro formato de archivo', NOW(), NOW()),
    ('shapefile', 'Archivo vectorial ESRI Shapefile', NOW(), NOW()),
    ('geojson', 'Archivo vectorial GeoJSON', NOW(), NOW()),
    ('geopackage', 'Archivo vectorial/raster GeoPackage', NOW(), NOW()),
    ('raster', 'Archivo raster geoespacial', NOW(), NOW()),
    ('wms', 'Servicio Web Map Service (WMS)', NOW(), NOW()),
    ('csv', 'Archivo de texto separado por comas, útil para tablas de atributos o puntos', NOW(), NOW()),
    ('kml', 'Archivo KML de Google Earth', NOW(), NOW()),
    ('gpkg', 'Abreviatura común de GeoPackage', NOW(), NOW()),
    ('pdf', 'Documento PDF, útil para mapas exportados', NOW(), NOW()),
    ('mp4', 'Archivo de video, por ejemplo para vuelos de dron', NOW(), NOW());

-- ============================================================
-- 32. CATALOGO: tipo de capa SIG
-- ============================================================
INSERT INTO catalogo.tipo_capa_sig (nombre, descripcion, created_at, updated_at) VALUES
    ('Uso de suelo', 'Capa de uso de suelo', NOW(), NOW()),
    ('Cobertura vegetal', 'Capa de cobertura vegetal', NOW(), NOW()),
    ('Zona prioritaria', 'Zonas prioritarias para conservación o manejo', NOW(), NOW()),
    ('Amenaza', 'Capas de amenazas ambientales o antrópicas', NOW(), NOW()),
    ('Hidrología', 'Red hidrográfica, cuerpos de agua', NOW(), NOW()),
    ('Edafología', 'Suelos y propiedades edáficas', NOW(), NOW()),
    ('División municipal', 'División política municipal', NOW(), NOW()),
    ('Comunidades', 'Ubicación de comunidades', NOW(), NOW()),
    ('Infraestructura', 'Infraestructura: caminos, escuelas, hospitales, etc.', NOW(), NOW()),
    ('Límite estatal', 'División estatal', NOW(), NOW()),
    ('Límite ejidal', 'División ejidal/comunal', NOW(), NOW()),
    ('Puntos de interés', 'Sitios arqueológicos, pozos, etc.', NOW(), NOW()),
    ('Uso de agua', 'Infraestructura hidráulica, pozos, ríos', NOW(), NOW()),
    ('Zonas de riesgo', 'Zonas de riesgo: inundación, deslaves, etc.', NOW(), NOW()),
    ('Vegetación', 'Tipos de vegetación', NOW(), NOW()),
    ('Altimetría', 'Curvas de nivel, elevación', NOW(), NOW()),
    ('Parcelas', 'Polígonos de parcelas agrícolas', NOW(), NOW()),
    ('Infraestructura energía', 'Líneas eléctricas, subestaciones', NOW(), NOW()),
    ('Otro', 'Otro tipo de capa SIG', NOW(), NOW());

-- ============================================================
-- 33. CATALOGO: fuente de captura
-- ============================================================
INSERT INTO catalogo.fuente_captura 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('GPS', 'Captura directa con GPS', NOW(), NOW()),
    ('Dron', 'Captura mediante dron', NOW(), NOW()),
    ('Satelite', 'Captura mediante imagen satelital', NOW(), NOW()),
    ('Estimado', 'Dato estimado o aproximado', NOW(), NOW()),
    ('Otro', 'Otro origen de captura', NOW(), NOW());

-- ============================================================
-- 34. CATALOGO: fuente de información
-- ============================================================
INSERT INTO catalogo.fuente_informacion 
    (nombre, descripcion, tipo, created_at, updated_at) 
VALUES
    ('Sentinel-2', 'Satélite Sentinel-2 de la ESA', 'sensor', NOW(), NOW()),
    ('Landsat-8', 'Satélite Landsat-8 de la NASA/USGS', 'sensor', NOW(), NOW()),
    ('Landsat-9', 'Satélite Landsat-9 de la NASA/USGS', 'sensor', NOW(), NOW()),
    ('MODIS', 'Sensor MODIS de la NASA', 'sensor', NOW(), NOW()),
    ('PlanetScope', 'Constelación de satélites PlanetScope', 'sensor', NOW(), NOW()),
    ('CONABIO', 'Comisión Nacional para el Conocimiento y Uso de la Biodiversidad', 'institucion', NOW(), NOW()),
    ('INEGI', 'Instituto Nacional de Estadística y Geografía', 'institucion', NOW(), NOW()),
    ('CONAGUA', 'Comisión Nacional del Agua', 'institucion', NOW(), NOW()),
    ('NASA', 'National Aeronautics and Space Administration', 'institucion', NOW(), NOW()),
    ('Estudio local', 'Estudio o levantamiento local', 'estudio', NOW(), NOW()),
    ('F2_Parcela_GPS', 'Formulario F2 de parcela con GPS', 'plataforma', NOW(), NOW()),
    ('otro', 'Otra fuente de información', 'otro', NOW(), NOW());

-- ============================================================
-- 35. CATALOGO: origen de muestra
-- ============================================================ 
INSERT INTO catalogo.origen_muestra 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Campo', 'Recolectada directamente en campo', NOW(), NOW()),
    ('Hornilla', 'Obtenida de la hornilla o cocina', NOW(), NOW()),
    ('Almacen', 'Proveniente de un almacén local', NOW(), NOW()),
    ('Mercado', 'Adquirida en mercado', NOW(), NOW()),
    ('Intercambio', 'Obtenida por intercambio', NOW(), NOW()),
    ('Desconocido', 'Origen no especificado', NOW(), NOW());

-- ============================================================
-- 36. CATALOGO: origen de semilla
-- ============================================================
INSERT INTO catalogo.origen_semilla 
    (nombre, descripcion, created_at, updated_at) 
VALUES
    ('Herencia Familiar', 'Semilla heredada de familiares', NOW(), NOW()),
    ('Intercambio_vecino', 'Intercambio con vecino', NOW(), NOW()),
    ('Intercambio_compadre', 'Intercambio con compadre/comadre', NOW(), NOW()),
    ('Regalo', 'Recibida como regalo', NOW(), NOW()),
    ('Compra', 'Adquirida por compra', NOW(), NOW()),
    ('Banco_comunitario', 'Banco comunitario de semillas', NOW(), NOW()),
    ('Organizacion', 'Organización o institución', NOW(), NOW()),
    ('Otro', 'Otro origen', NOW(), NOW()),
    ('Desconocido', 'Origen no especificado', NOW(), NOW());

-- Ciclos agricolas
-- Campo: anio 
INSERT INTO agronomico.ciclo_agricola (anio, temporada, fecha_inicio, fecha_fin)
VALUES
    (2025, 'Primavera-Verano', '2025-04-01', '2025-10-31'),
    (2025, 'Otoño-Invierno',   '2025-11-01', '2026-03-31');

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

-- Capas SIG base
-- Campo: anio_referencia 
INSERT INTO geografico.capa_sig
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