-- ============================================================
-- ESQUEMA: agronomico
-- Datos agronómicos de maíz nativo en la Huasteca Potosina
-- Incluye información sobre germoplasma, cultivos, ciclos agrícolas, sistema de semillas, usos del maíz cosechado y economía del cultivo
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Versión: 1.0 | Etapa 1
-- PostgreSQL
-- Residente
--
-- EJECUTAR DESPUÉS de 04_social.sql
-- EJECUTAR ANTES de 06_cultural.sql
--
-- Tablas:
-- 1. registros_agronomicos: registros detallados de descriptores agronómicos clave (25, 38, 64-68) relacionados con el cultivo y el germoplasma.
-- ============================================================

-- ═══════════════════════════════════════════════════════
--  MÓDULO AGRONÓMICO — descriptores 25, 38 y 64-68
--  + datos espaciales con PostGIS
-- ═══════════════════════════════════════════════════════

SET search_path TO agro, public;

-- ============================================================
-- Enum para clasificar las variedades de maíz según su origen y método de reproducción, facilitando el análisis de su diversidad genética, características agronómicas y adaptación a condiciones ambientales y prácticas agrícolas en la Huasteca Potosina.
-- ============================================================
CREATE TYPE agro.tipo_variedad AS ENUM (
    'linea_pura', -- Autofecundación, alta homogeneidad y estabilidad genética.
    'hibrido_simple', -- Cruce de dos líneas puras, alto rendimiento en F1.
    'hibrido_trilineal', -- Cruce de híbrido simple y línea pura, vigor y estabilidad intermedios.
    'polinizacion_abierta' -- Polinización abierta, alta diversidad genética y adaptabilidad.
);

-- ============================================================
-- Enum para clasificar los cultivos según la temporada de siembra y cosecha, útil para análisis estacionales y para entender las preferencias de los productores en las épocas de cultivo.
-- ============================================================
CREATE TYPE agro.ciclo_productivo AS ENUM (
    'Otoño-Invierno', -- Siembra en otoño, cosecha en invierno.
    'Primavera-Verano' -- Siembra en primavera, cosecha en verano.
);

-- ============================================================
-- Enum para clasificar los cultivos según el régimen hídrico durante su ciclo productivo, útil para analizar estrategias de manejo del agua y su relación con las características fenotípicas y agronómicas del maíz nativo.
-- ============================================================
CREATE TYPE agro.regimen_hidrico AS ENUM (
    'Riego completo', -- Riego todo el ciclo.
    'Riego parcial', -- Riego solo en etapas críticas.
    'Buen temporal', -- Sin riego, buen temporal.
    'Temporal regular', -- Temporal regular, posible estrés hídrico.
    'Otros' -- Régimen no especificado.
);

-- ============================================================
-- Enum para clasificar los descriptores fenotípicos y agronómicos según su naturaleza y método de captura, facilitando la organización y el análisis de la información de caracterización del maíz nativo.
-- ============================================================
CREATE TYPE agro.tipo_descriptor AS ENUM (
    'QN', -- Cuantitativo numérico, medido con instrumentos o contadores.
    'QL', -- Cualitativo nominal, categorías sin orden específico.
    'PQ'  -- Cualitativo ordinal, categorías con orden o jerarquía.
);

-- ============================================================
-- Enum para clasificar las observaciones fenotípicas y agronómicas según su calidad o confiabilidad, útil para evaluar la calidad de los datos e identificar posibles sesgos o errores en la caracterización del maíz nativo.
-- ============================================================
CREATE TYPE agro.tipo_observacion AS ENUM (
    'VG', -- Genéticamente pura, confiable.
    'VS', -- Segregante, indica heterogeneidad genética.
    'MG', -- Mezcla genética, características mixtas.
    'MS' -- Mezcla segregante, mixto y segregante.
);

-- ============================================================
-- 32. CATALOGO: ciclo agrícola
-- Catálogo para clasificar los ciclos agrícolas asociados a las muestras de germoplasma y a las prácticas agrícolas. Basado en categorías comunes de ciclos agrícolas, que se pueden usar para organizar la  información sobre los períodos de cultivo y para analizar la relación entre el ciclo agrícola y las características fenotípicas, agronómicas y culturales de las variedades de maíz nativo en la Huasteca Potosina.
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.ciclo_agricola (
    id           SERIAL PRIMARY KEY,
    anio         SMALLINT NOT NULL ,
    temporada    agro.ciclo_productivo NOT NULL,
    fecha_inicio DATE,
    fecha_fin    DATE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (anio BETWEEN 1900 AND 2100),
    CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT uq_ciclo_agricola UNIQUE (anio, temporada)
);

-- ============================================================
-- 5. CULTIVO 
-- El cultivo es la instancia espacio-temporal de la siembra de un germoplasma específico en una parcela determinada. Es la entidad central para el análisis agronómico, ya que a partir de ella se pueden relacionar las prácticas de manejo, los rendimientos, los usos del maíz cosechado y la economía del cultivo.
-- ============================================================ 
CREATE TABLE IF NOT EXISTS core.cultivo (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fecha_siembra       DATE NOT NULL,
    fecha_cosecha       DATE,
    sistema_manejo_id   INTEGER NOT NULL REFERENCES catalogo.sistema_manejo(id) 
                        ON DELETE RESTRICT 
                        ON UPDATE CASCADE,
    rendimiento_kg_ha   DECIMAL(10,2),
    observaciones       TEXT,
    germoplasma_id      UUID NOT NULL REFERENCES core.germoplasma(id) 
                        ON DELETE RESTRICT 
                        ON UPDATE CASCADE,
    parcela_id          UUID NOT NULL REFERENCES core.parcela(id) 
                        ON DELETE RESTRICT 
                        ON UPDATE CASCADE,   -- FK a core.parcela
    ubicacion_id        UUID REFERENCES core.ubicacion(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    ciclo_agricola_id   INTEGER REFERENCES catalogo.ciclo_agricola(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now(),

    CHECK (fecha_cosecha IS NULL OR fecha_cosecha >= fecha_siembra),
    CHECK (rendimiento_kg_ha >= 0)
);

CREATE INDEX IF NOT EXISTS idx_cultivo_parcela ON core.cultivo(parcela_id);
CREATE INDEX IF NOT EXISTS idx_cultivo_germoplasma ON core.cultivo(germoplasma_id);
CREATE INDEX IF NOT EXISTS idx_cultivo_ciclo ON core.cultivo(ciclo_agricola_id);
CREATE INDEX IF NOT EXISTS idx_cultivo_parcela_fecha ON core.cultivo(parcela_id, fecha_siembra);
CREATE INDEX IF NOT EXISTS idx_cultivo_fecha ON core.cultivo(fecha_siembra);

-- ============================================================
-- 33. CATALOGO: descriptores fenotípicos y agronómicos
-- Basado en los 68 descriptores del manual SNICS 2010 para caracterización de maíz nativo
-- Incluye información sobre el tipo de descriptor, la etapa fenológica asociada, el tipo de campo de captura y si es considerado importante para la caracterización UPOV
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.descriptores (
    id              SMALLINT PRIMARY KEY,   -- 1 al 68
    modulo          VARCHAR(15) NOT NULL,       -- 'fenotipico' | 'agronomico'
                        
    etapa_bbch      VARCHAR(30) NOT NULL,      -- 'plántula', 'antesis', etc.     -- 'plántula', 'antesis', etc.
    etapa_codigo    VARCHAR(20),                   -- 'E12-14', 'E61', 'E92-93'
    label_es        VARCHAR(250) NOT NULL,
    label_en        VARCHAR(250),
    tipo_desc       tipo_descriptor NOT NULL,
    tipo_obs        tipo_observacion NOT NULL,
    tipo_campo      VARCHAR(10) NOT NULL,
    importante      BOOLEAN DEFAULT FALSE,  -- asterisco UPOV
    hint_es         VARCHAR(300),                   -- instrucción de campo
    rango_min       NUMERIC(6,1),                   -- solo para number
    rango_max       NUMERIC(6,1),

    CHECK (modulo IN ('fenotipico', 'agronomico')),
    CHECK (tipo_campo IN ('select', 'number')),
);

-- ============================================================
-- 34. CATALOGO: opciones de descriptores fenotípicos y agronómicos
-- Catálogo para clasificar las opciones de respuesta para descriptores de tipo 'select' en la caracterización fenotípica y agronómica de las variedades de maíz nativo
-- Basado en los 68 descriptores del manual SNICS 2010 para caracterización de maíz nativo, donde cada descriptor de tipo 'select' tiene un conjunto específico de opciones de respuesta codificadas numéricamente (ej. 1, 3, 5, 7, 9) y con etiquetas descriptivas en español e inglés
-- ============================================================
CREATE TABLE IF NOT EXISTS catalogo.opciones_descriptor (
    id            SERIAL     PRIMARY KEY,
    descriptor_id SMALLINT NOT NULL 
                  REFERENCES catalogo.descriptores(id)
                  ON DELETE CASCADE
                  ON UPDATE CASCADE,
    codigo        SMALLINT NOT NULL,              -- 1, 3, 5, 7, 9 (escala UPOV)
    texto_es      VARCHAR(120) NOT NULL,
    texto_en      VARCHAR(120),

    UNIQUE(descriptor_id, codigo)
);

-- ============================================================
-- 1. AGRONÓMICO: VARIEDAD
-- Catálogo para clasificar las variedades de maíz nativo presentes en la Huasteca Potosina
-- Basado en clasificaciones académicas y etnobotánicas
-- ============================================================
CREATE TABLE agro.variedad (
    id            SERIAL PRIMARY KEY,
    codigo        VARCHAR(30) UNIQUE,
    nombre        VARCHAR(120)    NOT NULL UNIQUE,
    tipo_variedad agro.tipo_variedad,
    raza_id       INTEGER REFERENCES catalogo.raza_maiz(id) 
                  ON DELETE SET NULL 
                  ON UPDATE CASCADE,
    color_grano_id INTEGER REFERENCES catalogo.color_grano(id) 
                  ON DELETE SET NULL 
                  ON UPDATE CASCADE,
    obtentor_id   INTEGER REFERENCES core.productor(id) 
                  ON DELETE SET NULL 
                  ON UPDATE CASCADE,
    colector_id   INTEGER REFERENCES sistema.usuario(id) 
                  ON DELETE SET NULL 
                  ON UPDATE CASCADE, -- técnico de campo que colecta
    notas         TEXT,
    activo        BOOLEAN         DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (codigo ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT uq_variedad_nombre UNIQUE (nombre)
);

CREATE INDEX ix_variedades_tipo   ON agro.variedad(tipo_variedad_id);

CREATE INDEX ix_variedades_nombre ON agro.variedad USING gin(to_tsvector('spanish', nombre));

-- ============================================================
-- 4. REGISTROS AGRONÓMICOS DE DESCRIPTORES CLAVE
-- Tabla de registros agronómicos para los descriptores 25, 38 y 64-68, que se pueden relacionar con el cultivo y el germoplasma para análisis específicos de estos descriptores. Esta tabla permite documentar información detallada sobre el ciclo productivo, los días a floración masculina y femenina, la zona de adaptación, la estación de crecimiento y el régimen hídrico, que son aspectos clave para entender el comportamiento agronómico de las variedades de maíz nativo en la región y para identificar patrones o correlaciones con otras variables agronómicas, sociales o ambientales. 
-- ============================================================
CREATE TABLE IF NOT EXISTS agro.registros_agronomicos (
    id                  SERIAL PRIMARY KEY,
    variedad_id         INTEGER NOT NULL REFERENCES agro.variedad(id),
    ciclo               agro.ciclo_productivo,

    -- D25: días a floración masculina
    dias_floracion_masc SMALLINT            CHECK(dias_floracion_masc BETWEEN 40 AND 150),
    -- D38: días a floración femenina
    dias_floracion_fem  SMALLINT            CHECK(dias_floracion_fem  BETWEEN 40 AND 155),
    -- Intervalo antesis-estigma (calculado)
    intervalo_ase       SMALLINT
        GENERATED ALWAYS AS (dias_floracion_fem - dias_floracion_masc) STORED,

    -- D64: zona de adaptación principal
    zona_adapt_ppal     VARCHAR(60),
    -- D65: zona de adaptación secundaria
    zona_adapt_sec      VARCHAR(60),
    -- D66: estación de crecimiento principal
    estacion_ppal       catalogo.ciclo_productivo,
    -- D67: estación de crecimiento secundaria
    estacion_sec        catalogo.ciclo_productivo,
    -- D68: régimen hídrico
    regimen_hid         catalogo.regimen_hidrico,

    anio                SMALLINT            NOT NULL,
    observaciones       TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW(),
    UNIQUE(variedad_id, ciclo, anio)
);

-- Ciclos agricolas
-- Campo: anio 
INSERT INTO catalogo.ciclo_agricola (anio, temporada, fecha_inicio, fecha_fin)
VALUES
    (2025, 'Primavera-Verano', '2025-04-01', '2025-10-31'),
    (2025, 'Otoño-Invierno',   '2025-11-01', '2026-03-31');

-- ============================================================
--  SEED: 68 descriptores del manual SNICS 2010
--  Módulo fenotípico: D1-D24, D26-D37, D39-D63  (62 desc.)
--  Módulo agronómico: D25, D38, D64-D68           (6 desc.)
-- ============================================================

-- ── MÓDULO FENOTÍPICO ─────────────────────────────────────

INSERT INTO catalogo.descriptores (
    id, modulo, etapa_id, etapa_codigo, label_es, label_en, tipo_desc, tipo_obs, tipo_campo, importante, hint_es, rango_min, rango_max
) VALUES
-- Plántula E12-14
(1,'fenotipico','plántula','E12','Primera hoja: coloración de la vaina por antocianinas','First leaf: anthocyanin coloration of sheath','QN','VG','select',false,null,null,null),
(2,'fenotipico','plántula','E14','Primera hoja: longitud (cm)','First leaf: length (cm)','QN','MS','number',false,'Medir lámina del extremo inferior al ápice',0,20),
(3,'fenotipico','plántula','E14','Primera hoja: ancho (cm)','First leaf: width (cm)','QN','MS','select',false,null,null,null),
(4,'fenotipico','plántula','E14','Primera hoja: relación largo/ancho','First leaf: ratio length/width','QN','VG','select',false,null,null,null),
(5,'fenotipico','plántula','E14','Primera hoja: forma de la punta','First leaf: shape of apex','PQ','VG','select',false,null,null,null),
-- Inicio antesis E61
(6,'fenotipico','antesis','E61','Hoja: ángulo de inserción de las hojas abajo de la mazorca superior','Leaf: insertion angle of the leaves below upper ear','QN','MS','select',false,null,null,null),
(7,'fenotipico','antesis','E61','Hoja: ángulo entre la lámina y el tallo','Leaf: angle between blade and stem','QN','MS','select',false,'Medir en la hoja justo arriba de la mazorca superior',null,null),
(8,'fenotipico','antesis','E61','Hoja: ángulo de inserción de las hojas por arriba de la mazorca superior','Leaf: insertion angle of the leaves just above upper ear','QN','MS','select',false,null,null,null),
(9,'fenotipico','antesis','E61','Hoja: forma característica (actitud)','Leaf: attitude','QN','VG','select',false,null,null,null),
(10,'fenotipico','antesis','E61','Hoja: ondulación del margen laminar','Leaf: undulation of margin of blade','QN','VG','select',false,'Observar en la hoja de la mazorca principal',null,null),
-- Mitad antesis E65
(11,'fenotipico','antesis2','E65','Tallo: coloración por antocianinas en raíces adventicias','Stem: anthocyanin coloration in the brace roots','QN','VG','select',false,'Observar en raíces bien desarrolladas del 2° nudo',null,null),
(12,'fenotipico','antesis2','E65','Tallo: número de hijuelos por planta','Stem: number of tillers per plant','QN','VG','select',false,null,null,null),
(13,'fenotipico','antesis2','E65','Tallo: longitud media de entrenudos inferiores (cm)','Stem: average length of the lower internodes (cm)','QN','MS','select',false,'Del nudo de mazorca superior al nudo de la base',null,null),
(14,'fenotipico','antesis2','E65-71','Tallo: diámetro (mm)','Stem: diameter (mm)','QN','MS','select',false,'Medir el entrenudo del nudo de la mazorca superior',null,null),
(15,'fenotipico','antesis2','E65','Tallo: longitud media de entrenudos superiores (cm)','Stem: average length of the upper internodes (cm)','QN','MS','select',false,'Del nudo de la mazorca superior al nudo de la hoja bandera',null,null),
(16,'fenotipico','antesis2','E65','Tallo: grado de zigzagueo','Stem: degree of zig-zag','QN','VG','select',false,null,null,null),
(17,'fenotipico','antesis2','E65-71','Tallo: coloración por antocianinas en nudos','Stem: anthocyanin coloration of nodes','QN','VG','select',false,null,null,null),
(18,'fenotipico','antesis2','E65','Hoja: presencia de arrugas longitudinales','Leaf: presence of longitudinal wrinkles','QL','VG','select',false,'Observar en la hoja de la mazorca principal',null,null),
(19,'fenotipico','antesis2','E65','Hoja: coloración de la lámina','Leaf: coloration of blade','PQ','VG','select',false,'Observar en la hoja justo debajo de la mazorca superior',null,null),
(20,'fenotipico','antesis2','E65-71','Hoja: coloración de la vaina en las tres primeras hojas de la base del tallo','Leaf: sheath coloration of the first three leaves at base of stem','PQ','VG','select',false,null,null,null),
(21,'fenotipico','antesis2','E65','Hoja: coloración por antocianinas en la vaina, en la parte media de la planta','Leaf: anthocyanin coloration of sheath in middle of plant','QN','VG','select',false,null,null,null),
(22,'fenotipico','antesis2','E65-71','Hoja: coloración de la vaina en la hoja de la mazorca principal','Leaf: sheath coloration in the leaf of main ear','PQ','VG','select',false,'Observar en la vaina justo debajo de la mazorca superior',null,null),
(23,'fenotipico','antesis2','E65-71','Hoja: coloración de la aurícula','Leaf: auricle coloration','QL','VG','select',false,'Observar en la hoja justo debajo de la mazorca superior',null,null),
(24,'fenotipico','antesis2','E65-71','Hoja: pubescencia sobre el margen de la vaina','Leaf: pubescence on the sheath margin','QN','VG','select',false,'Observar en la vaina justo debajo de la mazorca superior',null,null),
-- Estado lechoso E65-75 (espiga/jilote, excepto D25 y D38 que son agronómicos)
(26,'fenotipico','lechoso','E65','Espiga: longitud del pedúnculo (cm)','Tassel: peduncle length (cm)','QN','MS','select',false,'Del nudo de la hoja bandera a la rama lateral más baja',null,null),
(27,'fenotipico','lechoso','E65','Espiga: longitud (cm)','Tassel: length (cm)','QN','MS','select',false,'De la base de la rama lateral más baja al ápice de la espiga',null,null),
(28,'fenotipico','lechoso','E65','Espiga: longitud del eje principal (cm)','Tassel: length of main axis (cm)','QN','MS','select',true,'De la base de la rama lateral más alta al ápice',null,null),
(29,'fenotipico','lechoso','E65','Espiga: ángulo','Tassel: angle','QN','MS','select',true,'Ángulo entre el eje principal y las ramas laterales, tercio inferior',null,null),
(30,'fenotipico','lechoso','E65','Espiga: posición de ramas laterales','Tassel: attitude of lateral branches','QN','VG','select',true,'Observar en el tercio inferior de la rama principal',null,null),
(31,'fenotipico','lechoso','E65','Espiga: número de ramas laterales primarias','Tassel: number of primary lateral branches','QN','MS','select',true,null,null,null),
(32,'fenotipico','lechoso','E65','Espiga: ramas secundarias','Tassel: secondary branches','QL','VG','select',false,null,null,null),
(33,'fenotipico','lechoso','E65','Espiga: densidad de espiguillas','Tassel: density of spikelets','QN','VG','select',false,'Observar en el tercio medio del eje principal',null,null),
(34,'fenotipico','lechoso','E65','Espiga: coloración por antocianinas en la base de las glumas','Tassel: anthocyanin coloration at base of glumes','QN','VG','select',true,'Observar en el tercio medio del eje principal',null,null),
(35,'fenotipico','lechoso','E65','Espiga: coloración por antocianinas en las glumas','Tassel: anthocyanin coloration of glumes','QN','VG','select',false,'Observar excluyendo la base de las glumas',null,null),
(36,'fenotipico','lechoso','E65','Espiga: coloración por antocianinas en las anteras','Tassel: anthocyanin coloration of anthers','QN','VG','select',false,'Observar en el tercio medio del eje principal',null,null),
(37,'fenotipico','lechoso','E65-71','Espiga: cubrimiento por la hoja bandera','Tassel: covered by the flag leave','QN','VG','select',false,'Cuando el 50% de las plantas está en antesis',null,null),
(39,'fenotipico','lechoso','E65','Jilote: coloración por antocianinas en los estigmas','Ear: anthocyanin stigmas coloration','QL','VG','select',true,'Observar en los estigmas de la mazorca superior',null,null),
(40,'fenotipico','lechoso','E65','Jilote: intensidad de la coloración por antocianinas en los estigmas','Ear: intensity of stigmas coloration by anthocyanin','QN','VG','select',false,null,null,null),
(41,'fenotipico','lechoso','E65','Jilote: desarrollo de filodios','Ear: "filodios" development','QN','VG','select',false,'Extensiones de las brácteas de la mazorca superior',null,null),
(42,'fenotipico','lechoso','E71','Espiga: longitud de ramas laterales (cm)','Tassel: length of lateral branches (cm)','QN','MS','select',false,'Del punto de inserción de la rama lateral inferior a su ápice',null,null),
-- Masoso suave E85
(43,'fenotipico','masoso','E85','Planta: longitud (cm)','Plant: length (cm)','QN','MS','select',true,'Desde la superficie del suelo hasta el ápice de la espiga',null,null),
(44,'fenotipico','masoso','E85','Planta: altura de la mazorca (cm)','Plant: height of ear (cm)','QN','MS','select',false,'Desde la superficie del suelo hasta el nudo de la mazorca superior',null,null),
(45,'fenotipico','masoso','E85','Planta: relación entre altura de la mazorca superior y altura de planta','Plant: ratio height of insertion of peduncle of upper ear to plant length','QN','MS','select',false,'Dividir la altura de mazorca entre la altura de planta',null,null),
(46,'fenotipico','masoso','E85','Hoja: ancho de lámina (cm)','Leaf: width of blade (cm)','QN','MS','select',false,'Medir en la parte media de la hoja justo debajo de la mazorca superior',null,null),
-- Madurez E92-93
(47,'fenotipico','madurez','E92','Planta: número de mazorcas por planta (%)','Plant: number of ears per plant (%)','QN','MS','select',false,'Total de mazorcas / número de tallos principales × 100',null,null),
(48,'fenotipico','madurez','E92','Mazorca: longitud del pedúnculo (cm)','Ear: peduncle length (cm)','QN','MS','select',false,'Del nudo de inserción en el tallo a la base de la mazorca superior',null,null),
(49,'fenotipico','madurez','E92','Mazorca: longitud (cm)','Ear: length (cm)','QN','MS','select',true,'Desde la base al ápice de la mazorca superior',null,null),
(50,'fenotipico','madurez','E92','Mazorca: diámetro (cm)','Ear: diameter (cm)','QN','MS','select',false,'Medir en la parte media de la mazorca superior',null,null),
(51,'fenotipico','madurez','E92','Mazorca: forma','Ear: shape','PQ','VS','select',false,'Observar en la mazorca superior',null,null),
(52,'fenotipico','madurez','E92','Mazorca: arreglo de hileras de granos','Ear: grain rows arrangement','QN','MS','select',false,'Observar en la mazorca superior',null,null),
(53,'fenotipico','madurez','E92','Mazorca: número de hileras de granos','Ear: number of rows of grain','QN','MS','select',false,'Contar en la parte media de la mazorca superior',null,null),
(54,'fenotipico','madurez','E92','Mazorca: número de granos por hilera','Ear: number of grains per row','QN','MS','select',false,'Contar de la base al ápice en la mazorca superior',null,null),
(55,'fenotipico','madurez','E92','Mazorca: tipo de grano','Ear: type of grain','QL','VS','select',true,'Observar en el tercio central de la mazorca superior',null,null),
(56,'fenotipico','madurez','E92','Mazorca: forma de la corona del grano','Ear: shape of grain top','PQ','VG','select',false,'Observar en el tercio central de la mazorca superior',null,null),
(57,'fenotipico','madurez','E92','Mazorca: color del grano','Ear: grain color','QL','VS','select',true,'Apariencia externa de la mazorca superior. Evitar efecto xenia',null,null),
(58,'fenotipico','madurez','E92','Mazorca: color dorsal del grano','Ear: color of dorsal side of grain','QL','VS','select',false,'Lado opuesto a la posición del embrión, parte media','null',null),
(59,'fenotipico','madurez','E92','Mazorca: color del endospermo del grano','Ear: color of endosperm of grain','QL','VS','select',false,'Hacer un corte transversal del grano. Evitar efecto xenia',null,null),
(60,'fenotipico','madurez','E93','Mazorca: coloración por antocianinas en las glumas del olote','Ear: anthocyanin coloration of glumes of cob','QL','VG','select',true,'Observar en el olote de la mazorca superior',null,null),
(61,'fenotipico','madurez','E93','Mazorca: intensidad de la coloración por antocianinas en las glumas del olote','Ear: coloration intensity by anthocyanin in the cob glumes','PQ','VS','select',false,null,null,null),
(62,'fenotipico','madurez','E93','Tipo de androesterilidad','Type of male sterility','QL','VG','select',false,null,null,null),
(63,'fenotipico','madurez','E93','Carácter braquítico','Brachitic character','QL','VG','select',false,'Determina el acortamiento de los entrenudos',null,null);

-- ── MÓDULO AGRONÓMICO ─────────────────────────────────────

INSERT INTO catalogo.descriptores (
    id, modulo, etapa_id, etapa_codigo, label_es, label_en, tipo_desc, tipo_obs, tipo_campo, importante, hint_es, rango_min, rango_max
) VALUES
(25,'agronomico','lechoso','E65','Espiga: floración masculina (días desde siembra)','Tassel: male flowering (days after sowing)','QN','MG','number',true,'Días hasta que el 50% de las plantas se encuentren en antesis. Observar en el tercio medio del eje principal.',40,140),
(38,'agronomico','lechoso','E65','Jilote: floración femenina (días desde siembra)','Ear: female flowering (days after sowing)','QN','MG','number',false,'Días hasta que el 50% de las plantas presenten estigmas de más de 1 cm de longitud.',40,145),
(64,'agronomico','general','—','Área de adaptación principal','Main adaptation area','QL','—','select',false,null,null,null),
(65,'agronomico','general','—','Área de adaptación secundaria','Secondary adaptation area','QL','—','select',false,null,null,null),
(66,'agronomico','general','—','Estación de crecimiento principal','Main growth season','QL','—','select',false,null,null,null),
(67,'agronomico','general','—','Estación de crecimiento secundaria','Secondary growth season','QL','—','select',false,null,null,null),
(68,'agronomico','general','—','Régimen hídrico','Hydric regime','QL','—','select',false,null,null,null);

-- ── OPCIONES DE DESCRIPTORES (muestra representativa) ────

INSERT INTO catalogo.opciones_descriptor (descriptor_id, codigo, texto_es, texto_en) VALUES
-- D1 Coloración antocianinas (escala 1-9)
(1,1,'Ausente o muy débil','Absent or very weak'),
(1,3,'Débil','Weak'),
(1,5,'Media','Medium'),
(1,7,'Fuerte','Strong'),
(1,9,'Muy fuerte','Very strong'),
-- D5 Forma de la punta
(5,1,'Puntiaguda','Pointed'),
(5,2,'Puntiaguda a redondeada','Pointed to rounded'),
(5,3,'Redondeada','Rounded'),
(5,4,'Redondeada a espatulada','Rounded to spatulate'),
(5,5,'Espatulada','Spatulate'),
-- D55 Tipo de grano
(55,1,'Cristalino (flint)','Flint'),
(55,2,'Semicristalino','Flint-like'),
(55,3,'Intermedio','Intermediate'),
(55,4,'Semidentado (dent-like)','Dent-like'),
(55,5,'Dentado (dent)','Dent'),
(55,6,'Reventador (pop)','Pop'),
(55,7,'Dulce (sweet)','Sweet'),
(55,8,'Ceroso (waxy)','Waxy'),
(55,9,'Harinoso (floury)','Floury'),
-- D57 Color del grano
(57,1,'Blanco','White'),
(57,2,'Blanco cremoso','Yellowish white'),
(57,3,'Amarillo claro','Light yellow'),
(57,4,'Amarillo','Yellow'),
(57,5,'Amarillo oscuro','Dark yellow'),
(57,6,'Naranja','Orange'),
(57,7,'Rojo claro','Light red'),
(57,8,'Rojo','Red'),
(57,9,'Rojo oscuro','Dark red'),
(57,10,'Azul','Blue'),
(57,11,'Oscuro','Dark'),
(57,12,'Negro','Black'),
-- D64 Área de adaptación
(64,1,'Trópico húmedo (0–100 msnm)','Tropical wet (0–100 masl)'),
(64,2,'Trópico subhúmedo (0–1150 msnm)','Tropical subwet (0–1150 masl)'),
(64,3,'Trópico seco (0–1000 msnm)','Tropical dry (0–1000 masl)'),
(64,4,'Bajío/subtrópico (1151–1800 msnm)','Intermediate zone (1151–1800 masl)'),
(64,5,'Zona de transición (1801–2150 msnm)','Transition zone (1801–2150 masl)'),
(64,6,'Valles altos (2151–2500 msnm)','Highlands (2151–2500 masl)'),
(64,7,'Valles muy altos (>2500 msnm)','Very highlands (>2500 masl)'),
-- D65 mismo catálogo que D64
(65,1,'Trópico húmedo (0–100 msnm)','Tropical wet (0–100 masl)'),
(65,2,'Trópico subhúmedo (0–1150 msnm)','Tropical subwet (0–1150 masl)'),
(65,3,'Trópico seco (0–1000 msnm)','Tropical dry (0–1000 masl)'),
(65,4,'Bajío/subtrópico (1151–1800 msnm)','Intermediate zone (1151–1800 masl)'),
(65,5,'Zona de transición (1801–2150 msnm)','Transition zone (1801–2150 masl)'),
(65,6,'Valles altos (2151–2500 msnm)','Highlands (2151–2500 masl)'),
(65,7,'Valles muy altos (>2500 msnm)','Very highlands (>2500 masl)'),
-- D66 Estación de crecimiento
(66,1,'Otoño–Invierno','Fall–Winter'),
(66,2,'Primavera–Verano','Spring–Summer'),
-- D67
(67,1,'Otoño–Invierno','Fall–Winter'),
(67,2,'Primavera–Verano','Spring–Summer'),
(68,1,'Riego completo','Complete irrigation'),
(68,2,'Riego parcial','Partial irrigation'),
(68,3,'Buen temporal','Good rainfall'),
(68,4,'Temporal regular','Regular rainfall'),
(68,5,'Otros','Other');


