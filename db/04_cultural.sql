-- ============================================================
-- ESQUEMA: cultural
-- Dimensión biocultural del maíz nativo en la Huasteca Potosina
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Versión: 1.0 | Etapa 1
--
-- EJECUTAR DESPUÉS de 02_social.sql
-- EJECUTAR ANTES de 03_geografico.sql
--
-- Tablas:
--   1. saber_tradicional
--   2. ritual_agricola
--   3. narrativa_oral
--   4. gastronomia_tradicional
--   5. transmision_conocimiento
--   6. identidad_cultural
--   7. nombre_lengua_originaria
-- ============================================================

CREATE SCHEMA IF NOT EXISTS cultural;
SET search_path TO cultural, public;

-- ============================================================
-- 1. SABER TRADICIONAL DE CULTIVO
--    Conocimiento local asociado al manejo del maíz nativo
--    capturado durante entrevistas etnográficas
-- ============================================================

CREATE TABLE cultural.saber_tradicional (
    id                          SERIAL PRIMARY KEY,
    productor_id                INTEGER REFERENCES social.productor(id),    -- FK a social.productor
    comunidad_id                INTEGER REFERENCES catalogo.comunidad(id),    -- FK a catalogo.comunidad

    -- Categoría del saber
    categoria                   VARCHAR(80) CHECK (categoria IN (
                                    'preparacion_suelo',
                                    'seleccion_semilla',
                                    'siembra',
                                    'manejo_cultivo',
                                    'control_plagas_tradicional',
                                    'cosecha',
                                    'almacenamiento',
                                    'prediccion_clima',
                                    'asociacion_plantas',
                                    'uso_medicinal',
                                    'calendario_agricola',
                                    'otro'
                                )),

    -- Descripción (voz del productor)
    descripcion                 TEXT NOT NULL,
    descripcion_lengua_orig     TEXT,       -- en lengua originaria si aplica
    lengua_id                   INTEGER,    -- FK a catalogo.lengua

    -- Contexto de transmisión
    aprendio_de                 VARCHAR(50) CHECK (aprendio_de IN (
                                    'padre','madre','abuelo','abuela',
                                    'familiar','vecino','comunidad','otro'
                                )),
    generaciones_estimadas      SMALLINT,   -- cuántas generaciones lleva este saber

    -- Vigencia
    esta_vigente                BOOLEAN DEFAULT TRUE,
    razon_perdida               TEXT,       -- si ya no se practica, por qué

    -- Valoración del productor
    considera_importante        BOOLEAN DEFAULT TRUE,
    importancia_descripcion     TEXT,

    -- Evidencia multimedia
    tiene_evidencia_audio       BOOLEAN DEFAULT FALSE,
    tiene_evidencia_video       BOOLEAN DEFAULT FALSE,
    tiene_evidencia_foto        BOOLEAN DEFAULT FALSE,
    ruta_archivo_multimedia     VARCHAR(500),

    fecha_registro              DATE DEFAULT CURRENT_DATE,
    registrado_por              VARCHAR(150),
    created_at                  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. RITUAL Y CEREMONIA AGRÍCOLA
--    Prácticas rituales vinculadas al ciclo del maíz
-- ============================================================

CREATE TABLE cultural.ritual_agricola (
    id                          SERIAL PRIMARY KEY,
    comunidad_id                INTEGER REFERENCES catalogo.comunidad(id),    -- FK a catalogo.comunidad

    -- Identificación
    nombre                      VARCHAR(200) NOT NULL,
    nombre_lengua_orig          VARCHAR(200),
    lengua_id                   INTEGER REFERENCES catalogo.lengua(id),    -- FK a catalogo.lengua

    -- Tipo y momento en el ciclo agrícola
    tipo                        VARCHAR(60) CHECK (tipo IN (
                                    'siembra',
                                    'crecimiento',
                                    'cosecha',
                                    'almacenamiento',
                                    'intercambio_semillas',
                                    'peticion_lluvia',
                                    'agradecimiento',
                                    'otro'
                                )),
    mes_aproximado              SMALLINT CHECK (mes_aproximado BETWEEN 1 AND 12),
    vinculado_ciclo_agricola    VARCHAR(30) CHECK (vinculado_ciclo_agricola IN (
                                    'Primavera-Verano','Otoño-Invierno','ambos','sin_ciclo_fijo'
                                )),

    -- Descripción
    descripcion                 TEXT NOT NULL,
    descripcion_lengua_orig     TEXT,
    participantes               TEXT,       -- quiénes participan (hombres, mujeres, niños, autoridades)
    elementos_utilizados        TEXT,       -- ofrendas, plantas, objetos rituales
    lugar_realizacion           VARCHAR(200),

    -- Estado de vigencia
    frecuencia_actual           VARCHAR(30) CHECK (frecuencia_actual IN (
                                    'anual','ocasional','en_desuso','recuperado','desconocido'
                                )),
    esta_vigente                BOOLEAN DEFAULT TRUE,
    razon_perdida               TEXT,
    esfuerzos_recuperacion      TEXT,

    -- Evidencia
    tiene_evidencia_audio       BOOLEAN DEFAULT FALSE,
    tiene_evidencia_video       BOOLEAN DEFAULT FALSE,
    tiene_evidencia_foto        BOOLEAN DEFAULT FALSE,
    ruta_archivo_multimedia     VARCHAR(500),

    fecha_registro              DATE DEFAULT CURRENT_DATE,
    registrado_por              VARCHAR(150),
    created_at                  TIMESTAMP DEFAULT NOW()
);

-- Productores que conocen o participan en el ritual (N:M)
CREATE TABLE cultural.ritual_productor (
    ritual_id       INTEGER REFERENCES cultural.ritual_agricola(id),
    productor_id    INTEGER REFERENCES social.productor(id),    -- FK a social.productor
    rol             VARCHAR(100),   -- ej. organizador, participante, informante
    PRIMARY KEY (ritual_id, productor_id)
);

-- ============================================================
-- 3. NARRATIVA ORAL
--    Mitos, relatos, leyendas y cosmovisión relacionada al maíz
-- ============================================================

CREATE TABLE cultural.narrativa_oral (
    id                          SERIAL PRIMARY KEY,
    comunidad_id                INTEGER REFERENCES catalogo.comunidad(id),    -- FK a catalogo.comunidad
    productor_id                INTEGER REFERENCES social.productor(id),    -- FK a social.productor (narrador)

    -- Clasificación
    tipo                        VARCHAR(50) CHECK (tipo IN (
                                    'mito_origen',
                                    'leyenda',
                                    'cuento',
                                    'refrán',
                                    'cancion',
                                    'oracion_agricola',
                                    'testimonio',
                                    'otro'
                                )),
    titulo                      VARCHAR(300),
    titulo_lengua_orig          VARCHAR(300),
    lengua_id                   INTEGER REFERENCES catalogo.lengua(id),    -- FK a catalogo.lengua

    -- Contenido
    contenido_resumen           TEXT NOT NULL,      -- resumen del investigador
    contenido_transcripcion     TEXT,               -- transcripción literal si aplica
    contenido_lengua_orig       TEXT,               -- en lengua originaria
    temas_principales           TEXT,               -- maíz, lluvia, tierra, deidades, etc.

    -- Vínculo con el maíz
    vinculo_maiz                VARCHAR(50) CHECK (vinculo_maiz IN (
                                    'origen_del_maiz',
                                    'manejo_del_cultivo',
                                    'seleccion_semilla',
                                    'cosmovisión_agricola',
                                    'identidad_cultural',
                                    'otro'
                                )),

    -- Contexto
    circunstancia_narracion     TEXT,   -- cuándo y dónde se narra normalmente
    audiencia_habitual          VARCHAR(100),   -- niños, adultos, toda la comunidad

    -- Transmisión
    aprendio_de                 VARCHAR(100),
    generaciones_estimadas      SMALLINT,
    esta_vigente                BOOLEAN DEFAULT TRUE,

    -- Evidencia
    tiene_audio                 BOOLEAN DEFAULT FALSE,
    tiene_video                 BOOLEAN DEFAULT FALSE,
    ruta_archivo_multimedia     VARCHAR(500),

    fecha_registro              DATE DEFAULT CURRENT_DATE,
    registrado_por              VARCHAR(150),
    created_at                  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 4. GASTRONOMÍA TRADICIONAL
--    Recetas y preparaciones derivadas del maíz nativo
-- ============================================================

CREATE TABLE cultural.gastronomia_tradicional (
    id                          SERIAL PRIMARY KEY,
    comunidad_id                INTEGER REFERENCES catalogo.comunidad(id),    -- FK a catalogo.comunidad

    -- Identificación
    nombre_platillo             VARCHAR(200) NOT NULL,
    nombre_lengua_orig          VARCHAR(200),
    lengua_id                   INTEGER REFERENCES catalogo.lengua(id),    -- FK a catalogo.lengua

    -- Categoría
    tipo                        VARCHAR(50) CHECK (tipo IN (
                                    'tortilla',
                                    'tamal',
                                    'atole',
                                    'pozole',
                                    'bebida_fermentada',
                                    'elote_preparado',
                                    'masa_especialidad',
                                    'dulce',
                                    'otro'
                                )),
    ocasion                     VARCHAR(80) CHECK (ocasion IN (
                                    'cotidiana',
                                    'festiva',
                                    'ritual',
                                    'medicinal',
                                    'intercambio',
                                    'otra'
                                )),

    -- Ingredientes y preparación
    ingredientes_principales    TEXT,
    descripcion_preparacion     TEXT,
    descripcion_lengua_orig     TEXT,
    variedad_maiz_preferida     VARCHAR(200),   -- qué variedad nativa usan para este platillo
    color_grano_preferido       VARCHAR(100),

    -- Valor cultural
    significado_cultural        TEXT,
    vinculo_ritual              BOOLEAN DEFAULT FALSE,
    ritual_asociado             VARCHAR(200),

    -- Vigencia
    frecuencia_preparacion      VARCHAR(30) CHECK (frecuencia_preparacion IN (
                                    'diaria','semanal','mensual',
                                    'estacional','festiva','en_desuso'
                                )),
    esta_vigente                BOOLEAN DEFAULT TRUE,
    razon_perdida               TEXT,

    -- Evidencia
    tiene_foto                  BOOLEAN DEFAULT FALSE,
    tiene_video                 BOOLEAN DEFAULT FALSE,
    ruta_archivo_multimedia     VARCHAR(500),

    fecha_registro              DATE DEFAULT CURRENT_DATE,
    registrado_por              VARCHAR(150),
    created_at                  TIMESTAMP DEFAULT NOW()
);

-- Productores que conocen o preparan el platillo (N:M)
CREATE TABLE cultural.gastronomia_productor (
    gastronomia_id  INTEGER REFERENCES cultural.gastronomia_tradicional(id),
    productor_id    INTEGER REFERENCES social.productor(id),    -- FK a social.productor
    es_preparador   BOOLEAN DEFAULT TRUE,   -- si lo prepara o solo lo conoce
    PRIMARY KEY (gastronomia_id, productor_id)
);

-- ============================================================
-- 5. TRANSMISIÓN INTERGENERACIONAL
--    Cómo se transfiere el conocimiento sobre el maíz nativo
-- ============================================================

CREATE TABLE cultural.transmision_conocimiento (
    id                              SERIAL PRIMARY KEY,
    productor_id                    INTEGER REFERENCES social.productor(id),    -- FK a social.productor

    -- Recepción del conocimiento
    recibio_conocimiento_familiar   BOOLEAN DEFAULT FALSE,
    generacion_transmisora          VARCHAR(50) CHECK (generacion_transmisora IN (
                                        'bisabuelos','abuelos','padres',
                                        'tios','comunidad','otro'
                                    )),
    edad_inicio_aprendizaje         SMALLINT,   -- a qué edad empezó a aprender

    -- Transmisión activa
    transmite_a_hijos               BOOLEAN DEFAULT FALSE,
    transmite_a_nietos              BOOLEAN DEFAULT FALSE,
    transmite_a_comunidad           BOOLEAN DEFAULT FALSE,
    transmite_a_jovenes             BOOLEAN DEFAULT FALSE,
    mecanismo_transmision           VARCHAR(50) CHECK (mecanismo_transmision IN (
                                        'practica_directa',
                                        'narración_oral',
                                        'participacion_ritual',
                                        'escuela_comunitaria',
                                        'milpa_familiar',
                                        'otro'
                                    )),
    descripcion_transmision         TEXT,

    -- Barreras para la transmisión
    hay_barreras                    BOOLEAN DEFAULT FALSE,
    barrera_migracion_jovenes       BOOLEAN DEFAULT FALSE,
    barrera_desinteres              BOOLEAN DEFAULT FALSE,
    barrera_escolarizacion          BOOLEAN DEFAULT FALSE,
    barrera_cambio_cultivos         BOOLEAN DEFAULT FALSE,
    barrera_perdida_lengua          BOOLEAN DEFAULT FALSE,
    barreras_otras                  TEXT,

    -- Percepción del riesgo de pérdida
    percibe_riesgo_perdida          BOOLEAN DEFAULT FALSE,
    nivel_riesgo_percibido          VARCHAR(20) CHECK (nivel_riesgo_percibido IN (
                                        'bajo','medio','alto','critico'
                                    )),
    descripcion_riesgo              TEXT,

    -- Iniciativas propias de preservación
    tiene_iniciativas_preservacion  BOOLEAN DEFAULT FALSE,
    descripcion_iniciativas         TEXT,

    -- Deseos y propuestas del productor
    propuestas_preservacion         TEXT,

    fecha_registro                  DATE DEFAULT CURRENT_DATE,
    registrado_por                  VARCHAR(150),
    created_at                      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 6. IDENTIDAD CULTURAL
--    Vínculo del productor con el maíz como elemento identitario
-- ============================================================

CREATE TABLE cultural.identidad_cultural (
    id                              SERIAL PRIMARY KEY,
    productor_id                    INTEGER REFERENCES social.productor(id),    -- FK a social.productor

    -- Autoadscripción étnica
    se_identifica_etnia             BOOLEAN DEFAULT FALSE,
    etnia_nombre                    VARCHAR(100),   -- Teenek, Náhuatl, Pame, etc.
    habla_lengua_originaria         BOOLEAN DEFAULT FALSE,
    lengua_id                       INTEGER REFERENCES catalogo.lengua(id),    -- FK a catalogo.lengua
    nivel_dominio_lengua            VARCHAR(20) CHECK (nivel_dominio_lengua IN (
                                        'nativo','fluido','basico','comprende_solo'
                                    )),

    -- Vínculo con el maíz
    maiz_es_parte_identidad         BOOLEAN DEFAULT FALSE,
    descripcion_vinculo_identidad   TEXT,   -- en sus propias palabras
    descripcion_vinculo_lengua_orig TEXT,

    -- Orgullo y valoración
    se_siente_orgulloso_maiz_nativo BOOLEAN DEFAULT FALSE,
    razon_orgullo                   TEXT,
    valora_diversidad_variedades    BOOLEAN DEFAULT FALSE,
    descripcion_valoracion          TEXT,

    -- Sentido de responsabilidad
    se_siente_guardian_semillas     BOOLEAN DEFAULT FALSE,
    descripcion_responsabilidad     TEXT,

    -- Cambios percibidos en la identidad cultural
    percibe_perdida_cultura_maiz    BOOLEAN DEFAULT FALSE,
    descripcion_perdida_cultural    TEXT,
    factores_perdida                TEXT,

    -- Apoyos deseados para fortalecer identidad
    apoyos_para_identidad           TEXT,

    fecha_registro                  DATE DEFAULT CURRENT_DATE,
    registrado_por                  VARCHAR(150),
    created_at                      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 7. NOMBRE EN LENGUA ORIGINARIA 
--    Registro lingüístico de los nombres nativos del maíz
-- ============================================================

CREATE TABLE cultural.nombre_lengua_originaria (
    id                      SERIAL PRIMARY KEY,
    germoplasma_id          INTEGER,    -- FK a agronomico.germoplasma
    lengua_id               INTEGER REFERENCES catalogo.lengua(id),    -- FK a catalogo.lengua
    comunidad_id            INTEGER REFERENCES catalogo.comunidad(id),    -- FK a catalogo.comunidad

    -- Nombre
    nombre                  VARCHAR(300) NOT NULL,
    transcripcion_fonetica  VARCHAR(300),
    escritura_oficial       VARCHAR(300),   -- si existe ortografía normalizada

    -- Significado
    significado_literal     TEXT,
    significado_cultural    TEXT,
    contexto_uso            TEXT,   -- cuándo y cómo se usa este nombre

    -- Variantes
    tiene_variantes         BOOLEAN DEFAULT FALSE,
    variantes               TEXT,   -- otros nombres en la misma lengua

    -- Fuente
    informante_id           INTEGER REFERENCES social.productor(id),    -- FK a social.productor
    es_nombre_vigente       BOOLEAN DEFAULT TRUE,
    notas_linguisticas      TEXT,

    fecha_registro          DATE DEFAULT CURRENT_DATE,
    registrado_por          VARCHAR(150),
    created_at              TIMESTAMP DEFAULT NOW(),

    UNIQUE (germoplasma_id, lengua_id, nombre)
);

-- ============================================================
-- ÍNDICES PARA CONSULTAS FRECUENTES
-- Optimización de consultas por comunidad
-- ============================================================

CREATE INDEX idx_saber_comunidad 
ON cultural.saber_tradicional(comunidad_id);

CREATE INDEX idx_ritual_comunidad 
ON cultural.ritual_agricola(comunidad_id);

CREATE INDEX idx_narrativa_comunidad 
ON cultural.narrativa_oral(comunidad_id);

CREATE INDEX idx_nombre_lengua_germoplasma
ON cultural.nombre_lengua_originaria(germoplasma_id);

-- Índices adicionales para consultas por productor
CREATE INDEX idx_saber_productor
ON cultural.saber_tradicional(productor_id);

CREATE INDEX idx_narrativa_productor
ON cultural.narrativa_oral(productor_id);

CREATE INDEX idx_identidad_productor
ON cultural.identidad_cultural(productor_id);

CREATE INDEX idx_transmision_productor
ON cultural.transmision_conocimiento(productor_id);

-- ============================================================
-- VISTAS DEL EJE CULTURAL
-- ============================================================

-- Vista: mapa de saberes por comunidad
CREATE VIEW cultural.v_saberes_comunidad AS
SELECT
    mun.nombre          AS municipio,
    com.nombre          AS comunidad,
    com.tipo            AS tipo_comunidad,
    COUNT(DISTINCT st.id)                                AS total_saberes,
    COUNT(DISTINCT ra.id)                                AS total_rituales,
    COUNT(DISTINCT no.id)                                AS total_narrativas,
    COUNT(DISTINCT gt.id)                                AS total_platillos,
    SUM(CASE WHEN st.esta_vigente THEN 1 ELSE 0 END)     AS saberes_vigentes,
    SUM(CASE WHEN NOT st.esta_vigente THEN 1 ELSE 0 END) AS saberes_en_riesgo,
    SUM(CASE WHEN ra.esta_vigente THEN 1 ELSE 0 END)     AS rituales_vigentes
FROM catalogo.comunidad com
JOIN catalogo.municipio mun                         ON mun.id = com.municipio_id
LEFT JOIN cultural.saber_tradicional st             ON st.comunidad_id = com.id
LEFT JOIN cultural.ritual_agricola ra               ON ra.comunidad_id = com.id
LEFT JOIN cultural.narrativa_oral no                ON no.comunidad_id = com.id
LEFT JOIN cultural.gastronomia_tradicional gt       ON gt.comunidad_id = com.id
GROUP BY mun.nombre, com.nombre, com.tipo
ORDER BY total_saberes DESC;

-- Vista: riesgo de pérdida cultural por productor
CREATE VIEW cultural.v_riesgo_perdida_cultural AS
SELECT
    p.nombres || ' ' || COALESCE(p.apellido_paterno,'') AS productor,
    mun.nombre      AS municipio,
    ic.se_identifica_etnia,
    ic.etnia_nombre,
    ic.habla_lengua_originaria,
    ic.maiz_es_parte_identidad,
    ic.se_siente_guardian_semillas,
    ic.percibe_perdida_cultura_maiz,
    tc.percibe_riesgo_perdida,
    tc.nivel_riesgo_percibido,
    tc.hay_barreras,
    tc.barrera_migracion_jovenes,
    tc.barrera_perdida_lengua,
    tc.transmite_a_hijos,
    tc.transmite_a_jovenes,
    (CASE WHEN ic.percibe_perdida_cultura_maiz THEN 2 ELSE 0 END +
     CASE WHEN tc.percibe_riesgo_perdida THEN 2 ELSE 0 END +
     CASE WHEN tc.barrera_migracion_jovenes THEN 1 ELSE 0 END +
     CASE WHEN tc.barrera_perdida_lengua THEN 1 ELSE 0 END +
     CASE WHEN NOT ic.habla_lengua_originaria THEN 1 ELSE 0 END +
     CASE WHEN NOT tc.transmite_a_hijos THEN 1 ELSE 0 END
    ) AS score_riesgo_cultural
FROM social.productor p
LEFT JOIN catalogo.municipio mun                    ON mun.id = p.municipio_id
LEFT JOIN cultural.identidad_cultural ic            ON ic.productor_id = p.id
LEFT JOIN cultural.transmision_conocimiento tc      ON tc.productor_id = p.id
ORDER BY score_riesgo_cultural DESC;

-- Vista: patrimonio gastronómico por variedad de maíz
CREATE VIEW cultural.v_gastronomia_variedad AS
SELECT
    gt.variedad_maiz_preferida,
    gt.color_grano_preferido,
    COUNT(DISTINCT gt.id)           AS total_platillos,
    COUNT(DISTINCT gt.comunidad_id) AS comunidades_que_lo_usan,
    STRING_AGG(DISTINCT gt.nombre_platillo, ', ') AS platillos,
    SUM(CASE WHEN gt.vinculo_ritual THEN 1 ELSE 0 END) AS platillos_rituales,
    SUM(CASE WHEN gt.esta_vigente THEN 1 ELSE 0 END)   AS platillos_vigentes
FROM cultural.gastronomia_tradicional gt
WHERE gt.variedad_maiz_preferida IS NOT NULL
GROUP BY gt.variedad_maiz_preferida, gt.color_grano_preferido
ORDER BY total_platillos DESC;

-- Vista integrada: germoplasma con su riqueza cultural
CREATE VIEW cultural.v_germoplasma_cultural AS
SELECT
    nlo.germoplasma_id,
    l.nombre            AS lengua,
    nlo.nombre          AS nombre_originario,
    nlo.significado_literal,
    nlo.significado_cultural,
    com.nombre          AS comunidad_origen,
    mun.nombre          AS municipio,
    (SELECT COUNT(*) FROM cultural.gastronomia_tradicional gt
     WHERE gt.variedad_maiz_preferida ILIKE '%' || nlo.nombre || '%') AS platillos_asociados
FROM cultural.nombre_lengua_originaria nlo
JOIN catalogo.lengua l              ON l.id = nlo.lengua_id
LEFT JOIN catalogo.comunidad com    ON com.id = nlo.comunidad_id
LEFT JOIN catalogo.municipio mun    ON mun.id = com.municipio_id;