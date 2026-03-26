-- ============================================================
-- ESQUEMA: cultural
-- Dimensión biocultural del maíz nativo en la Huasteca Potosina
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Versión: 1.0 | Etapa 1
--
-- EJECUTAR DESPUÉS de 05_agronomico.sql
-- EJECUTAR ANTES de 07_fenotipico.sql
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

SET search_path TO cultural, public;

-- ============================================================
-- 1. SABER TRADICIONAL DE CULTIVO
--    Conocimiento local asociado al manejo del maíz nativo
--    capturado durante entrevistas etnográficas
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.saber_tradicional (
    id                          SERIAL PRIMARY KEY,
    productor_id                INTEGER NOT NULL REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a social.productor
    comunidad_id                INTEGER NOT NULL REFERENCES catalogo.comunidad(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a catalogo.comunidad

    -- Categoría del saber
    categoria_saber_agricola_id INTEGER NOT NULL REFERENCES catalogo.categoria_saber_agricola(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a catalogo.categoria_saber_agricola

    -- Descripción (voz del productor)
    descripcion                 TEXT NOT NULL,
    descripcion_lengua_orig     TEXT,       -- en lengua originaria si aplica
    lengua_id                   INTEGER NOT NULL REFERENCES catalogo.lengua(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a catalogo.lengua

    -- Contexto de transmisión
    aprendio_de                 VARCHAR(50) CHECK (aprendio_de IN (
                                    'padre','madre','abuelo','abuela',
                                    'familiar','vecino','comunidad','otro'
                                )),
    generaciones_estimadas      SMALLINT CHECK (generaciones_estimadas >= 0),   -- cuántas generaciones lleva este saber

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
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. RITUAL Y CEREMONIA AGRÍCOLA
--    Prácticas rituales vinculadas al ciclo del maíz
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.ritual_agricola (
    id                          SERIAL PRIMARY KEY,
    comunidad_id                INTEGER NOT NULL REFERENCES catalogo.comunidad(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a catalogo.comunidad

    -- Identificación
    nombre                      VARCHAR(200) NOT NULL,
    nombre_lengua_orig          VARCHAR(200),
    lengua_id                   INTEGER REFERENCES catalogo.lengua(id),    -- FK a catalogo.lengua

    -- Tipo y momento en el ciclo agrícola
    tipo_ritual_agricola_id INTEGER NOT NULL REFERENCES catalogo.tipo_ritual_agricola(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a catalogo.tipo_ritual_agricola
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
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

-- Productores que conocen o participan en el ritual (N:M)
CREATE TABLE IF NOT EXISTS cultural.ritual_productor (
    ritual_id       INTEGER NOT NULL REFERENCES cultural.ritual_agricola(id) ON DELETE CASCADE ON UPDATE CASCADE,
    productor_id    INTEGER NOT NULL REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a social.productor
    rol             VARCHAR(100),   -- ej. organizador, participante, informante
    PRIMARY KEY (ritual_id, productor_id)
);

-- ============================================================
-- 3. NARRATIVA ORAL
--    Mitos, relatos, leyendas y cosmovisión relacionada al maíz
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.narrativa_oral (
    id                          SERIAL PRIMARY KEY,
    comunidad_id                INTEGER NOT NULL REFERENCES catalogo.comunidad(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a catalogo.comunidad
    productor_id                INTEGER NOT NULL REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a social.productor (narrador)

    -- Clasificación
    tipo_narrativa_oral_id INTEGER NOT NULL REFERENCES catalogo.tipo_narrativa_oral(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a catalogo.tipo_narrativa_oral      ,
    titulo                      VARCHAR(300),
    titulo_lengua_orig          VARCHAR(300),
    lengua_id                   INTEGER REFERENCES catalogo.lengua(id),    -- FK a catalogo.lengua

    -- Contenido
    contenido_resumen           TEXT NOT NULL,      -- resumen del investigador
    contenido_transcripcion     TEXT,               -- transcripción literal si aplica
    contenido_lengua_orig       TEXT,               -- en lengua originaria
    temas_principales           TEXT,               -- maíz, lluvia, tierra, deidades, etc.

    -- Vínculo con el maíz
    vinculo_maiz_id INTEGER REFERENCES catalogo.vinculo_maiz(id) ON DELETE SET NULL ON UPDATE CASCADE,    -- FK a catalogo.vinculo_maiz
    descripcion_vinculo_maiz     TEXT,               -- en qué consiste el vínculo con el maíz

    -- Contexto
    circunstancia_narracion     TEXT,   -- cuándo y dónde se narra normalmente
    audiencia_habitual          VARCHAR(100),   -- niños, adultos, toda la comunidad

    -- Transmisión
    aprendio_de                 VARCHAR(100),
    generaciones_estimadas      SMALLINT CHECK (generaciones_estimadas >= 0),
    esta_vigente                BOOLEAN DEFAULT TRUE,

    -- Evidencia
    tiene_audio                 BOOLEAN DEFAULT FALSE,
    tiene_video                 BOOLEAN DEFAULT FALSE,
    ruta_archivo_multimedia     VARCHAR(500),

    fecha_registro              DATE DEFAULT CURRENT_DATE,
    registrado_por              VARCHAR(150),
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 4. GASTRONOMÍA TRADICIONAL
--    Recetas y preparaciones derivadas del maíz nativo
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.gastronomia_tradicional (
    id                          SERIAL PRIMARY KEY,
    comunidad_id                INTEGER NOT NULL REFERENCES catalogo.comunidad(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a catalogo.comunidad

    -- Identificación
    nombre_platillo             VARCHAR(200) NOT NULL,
    nombre_lengua_orig          VARCHAR(200),
    lengua_id                   INTEGER REFERENCES catalogo.lengua(id),    -- FK a catalogo.lengua

    -- Categoría
    uso_maiz_id INTEGER REFERENCES catalogo.uso_maiz(id) ON DELETE SET NULL ON UPDATE CASCADE,    -- FK a catalogo.uso_maiz
    ocasion_id INTEGER REFERENCES catalogo.ocasion(id) ON DELETE SET NULL ON UPDATE CASCADE,    -- FK a catalogo.ocasion

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
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

-- Productores que conocen o preparan el platillo (N:M)
CREATE TABLE IF NOT EXISTS cultural.gastronomia_productor (
    gastronomia_id  INTEGER NOT NULL REFERENCES cultural.gastronomia_tradicional(id) ON DELETE CASCADE ON UPDATE CASCADE,
    productor_id    INTEGER NOT NULL REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,    -- FK a social.productor
    es_preparador   BOOLEAN DEFAULT TRUE,   -- si lo prepara o solo lo conoce
    PRIMARY KEY (gastronomia_id, productor_id)
);

-- ============================================================
-- 5. TRANSMISIÓN INTERGENERACIONAL
--    Cómo se transfiere el conocimiento sobre el maíz nativo
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.transmision_conocimiento (
    id                              SERIAL PRIMARY KEY,
    productor_id                    INTEGER REFERENCES social.productor(id),    -- FK a social.productor

    -- Recepción del conocimiento
    recibio_conocimiento_familiar   BOOLEAN DEFAULT FALSE,
    generacion_transmisora          VARCHAR(50) CHECK (generacion_transmisora IN (
                                        'bisabuelos','abuelos','padres',
                                        'tios','comunidad','otro'
                                    )),
    edad_inicio_aprendizaje         SMALLINT CHECK (edad_inicio_aprendizaje BETWEEN 0 AND 100),   -- a qué edad empezó a aprender

    -- Transmisión activa
    transmite_a_hijos               BOOLEAN DEFAULT FALSE,
    transmite_a_nietos              BOOLEAN DEFAULT FALSE,
    transmite_a_comunidad           BOOLEAN DEFAULT FALSE,
    transmite_a_jovenes             BOOLEAN DEFAULT FALSE,
    mecanismo_transmision_id INTEGER REFERENCES catalogo.mecanismo_transmision(id) ON DELETE SET NULL ON UPDATE CASCADE,    -- FK a catalogo.mecanismo_transmision
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
    created_at                      TIMESTAMP DEFAULT NOW(),
    updated_at                      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 6. IDENTIDAD CULTURAL
--    Vínculo del productor con el maíz como elemento identitario
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.identidad_cultural (
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
    created_at                      TIMESTAMP DEFAULT NOW(),
    updated_at                      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 7. NOMBRE EN LENGUA ORIGINARIA 
--    Registro lingüístico de los nombres nativos del maíz
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.nombre_lengua_originaria (
    id                      SERIAL PRIMARY KEY,
    germoplasma_id          INTEGER REFERENCES agronomico.germoplasma(id),    -- FK a agronomico.germoplasma
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
    updated_at              TIMESTAMP DEFAULT NOW(),

    UNIQUE (germoplasma_id, lengua_id, nombre)
);

-- ============================================================
-- 8. MEDIO CULTURAL
--    Repositorio centralizado de archivos multimedia capturados
--    durante las entrevistas etnográficas (F5).
--
--    Diseño: una fila por archivo.
--    El campo entidad_tipo + entidad_id apunta a la tabla de origen
--    (saber_tradicional, ritual_agricola, narrativa_oral, etc.)
--    sin necesidad de FK rígidas hacia cada tabla.
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.medio_cultural (
    id              SERIAL PRIMARY KEY,

    -- Referencia polimórfica al registro cultural que documenta
    entidad_tipo    VARCHAR(60) NOT NULL CHECK (entidad_tipo IN (
                        'saber_tradicional',
                        'ritual_agricola',
                        'narrativa_oral',
                        'gastronomia_tradicional',
                        'nombre_lengua_originaria',
                        'identidad_cultural',
                        'transmision_conocimiento',
                        'sesion_entrevista'       -- para medios del cierre general
                    )),
    entidad_id      INTEGER NOT NULL,   -- id del registro en la tabla indicada

    -- Identificación del archivo
    tipo_medio      VARCHAR(20) NOT NULL CHECK (tipo_medio IN (
                        'foto', 'audio', 'video'
                    )),
    nombre_archivo  VARCHAR(300) NOT NULL,  -- nombre exportado por KoboToolbox
    -- La ruta completa se construye como:
    --   <ruta_base_proyecto>/<form_id>/<uuid_envio>/<nombre_archivo>
    -- KoboToolbox la entrega en el media attachment del JSON de exportación.

    -- Contexto de captura (del campo Kobo que lo originó)
    campo_origen    VARCHAR(100),   -- ej. foto_saber1, audio_ritual1, foto_platillo2
    descripcion     TEXT,           -- descripción libre del encuestador

    -- Consentimiento (heredado del consentimiento del productor en F1)
    consentimiento_verificado BOOLEAN DEFAULT FALSE,
    productor_id    INTEGER REFERENCES social.productor(id),

    -- Metadatos técnicos (opcionales, para enriquecer en post-proceso)
    duracion_seg    INTEGER,        -- solo para audio/video
    resolucion      VARCHAR(30),    -- ej. "1920x1080", "4032x3024"
    peso_kb         INTEGER,
    formato         VARCHAR(20),    -- jpg, png, mp3, wav, mp4, etc.

    -- Trazabilidad
    uuid_envio      VARCHAR(100),   -- _uuid del envío en KoboToolbox
    fecha_captura   DATE DEFAULT CURRENT_DATE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);


-- ============================================================
-- 9. SESIÓN DE ENTREVISTA
--    Metadatos de cada sesión del formulario F5:
--    vinculación con el productor (F1), GPS del lugar,
--    duración, lengua y estado de la entrevista.
-- ============================================================

CREATE TABLE IF NOT EXISTS cultural.sesion_entrevista (
    id                      SERIAL PRIMARY KEY,

    -- Vínculo con el productor (código capturado en grp_vinculo de F5)
    productor_id            INTEGER REFERENCES social.productor(id),
    codigo_productor        VARCHAR(20),    -- HP-2025-001, para validación cruzada con F1

    -- Metadatos de la visita
    fecha_registro          DATE DEFAULT CURRENT_DATE,
    registrador             VARCHAR(150),
    municipio_id            INTEGER REFERENCES catalogo.municipio(id),
    comunidad_id            INTEGER REFERENCES catalogo.comunidad(id),
    comunidad_texto         VARCHAR(200),   -- si no está catalogada aún
    lengua_entrevista       VARCHAR(30) CHECK (lengua_entrevista IN (
                                'teenek','nahuatl','pame','español','otra'
                            )),

    -- Geolocalización del lugar de la entrevista
    -- (campo geopoint_entrevista del grp_cierre en F5)
    latitud                 DECIMAL(10,7) CHECK (latitud IS NULL OR latitud BETWEEN 20.0 AND 23.0),
    longitud                DECIMAL(10,7) CHECK (longitud IS NULL OR longitud BETWEEN -100.5 AND -97.5),
    altitud_m               DECIMAL(8,2),
    precision_gps_m         DECIMAL(6,2),

    -- Validación geográfica (Huasteca Potosina)
    CONSTRAINT chk_lat_cultural CHECK (latitud  BETWEEN 20.0 AND 23.0),
    CONSTRAINT chk_lon_cultural CHECK (longitud BETWEEN -100.5 AND -97.5),

    -- Calidad y cierre de la sesión
    duracion_min            SMALLINT CHECK (duracion_min IS NULL OR (duracion_min > 0 AND duracion_min < 300)),
    productor_satisfecho    BOOLEAN,
    temas_pendientes        TEXT,       -- lista de temas no cubiertos
    notas_etnograficas      TEXT,       -- observaciones del entrevistador

    -- Trazabilidad KoboToolbox
    uuid_envio              VARCHAR(100) UNIQUE,
    deviceid                VARCHAR(100),
    fecha_inicio_kobo       TIMESTAMP,  -- campo start de KoboToolbox
    fecha_fin_kobo          TIMESTAMP,  -- campo end de KoboToolbox

    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);
