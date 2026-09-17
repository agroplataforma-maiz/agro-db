-- ============================================================
-- ESQUEMA: social
--  Módulo Social + Cultural · Maíz Nativo
--  Refs: Hammersley & Atkinson (2007), Spradley (2016),
--        Patton (2014), Cotton (1996)
-- Productores, redes, seguridad alimentaria
-- PEE-2025-G-369 | TecNM Ciudad Valles
--
-- DEPENDE DE: 02_catalogo.sql (debe ejecutarse primero)
-- ============================================================

SET search_path TO social, public;

CREATE TYPE social.modulo_etno AS ENUM (
    'comunidad',    -- S1: caracterización territorial
    'informante',   -- S2: perfil sociodemográfico
    'entrevista',   -- S3: entrevista semiestructurada
    'encuesta',     -- S4: encuesta socioeconómica
    'variedad',     -- C1: variedad local / taxonomía folk
    'practica',     -- C2: práctica tradicional
    'saber',        -- C3: saber etnoecológico (TEK)
    'discurso'      -- C4: análisis cualitativo del discurso
);

-- Tipo de dato del descriptor (igual que SNICS)
CREATE TYPE social.tipo_descriptor_etno AS ENUM (
    'QN',   -- cuantitativo continuo
    'QL',   -- cualitativo nominal/ordinal
    'PQ',   -- pseudo-cualitativo (escala visual)
    'TX'    -- texto libre / narrativa
);

-- Tipo de observación (expandido para etnografía)
CREATE TYPE social.tipo_observacion_etno AS ENUM (
    'MS',   -- medición directa
    'VG',   -- visual por el evaluador
    'EN',   -- entrevista/narrativa
    'LK',   -- escala Likert 1-5
    'CB',   -- casilla(s) de verificación
    'MX'    -- selección múltiple
);

-- Tipo de widget en el formulario
CREATE TYPE social.tipo_campo_etno AS ENUM (
    'select',       -- una opción
    'multiselect',  -- varias opciones
    'number',       -- valor numérico
    'text',         -- texto corto
    'textarea',     -- texto largo / narrativa
    'likert5',      -- botones 1-5
    'checkbox'      -- booleano
);

CREATE TABLE IF NOT EXISTS social.productor_usuario (
    productor_id        UUID PRIMARY KEY REFERENCES core.productor(id) 
                        ON DELETE CASCADE,
    user_id             UUID NOT NULL UNIQUE REFERENCES sistema.usuario(id) 
                        ON DELETE CASCADE,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 1b. TECNICO DE CAMPO - USUARIO (1:1)
-- Relación entre técnico de campo y usuario del sistema
-- ==============================================================
CREATE TABLE IF NOT EXISTS social.tecnico_campo (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL UNIQUE REFERENCES sistema.usuario(id) 
                        ON DELETE CASCADE,
    institucion         VARCHAR(200),
    especialidad        VARCHAR(150),
    notas               TEXT,
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 1c. TECNICO DE CAMPO - PRODUCTOR
-- Relación entre técnicos de campo y productores
-- ============================================================
CREATE TABLE IF NOT EXISTS social.tecnico_productor (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    tecnico_campo_id        UUID NOT NULL
                            REFERENCES social.tecnico_campo(id)
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,

    productor_id            UUID NOT NULL
                            REFERENCES core.productor(id)
                            ON DELETE CASCADE
                            ON UPDATE CASCADE,

    estado                  VARCHAR(20) NOT NULL DEFAULT 'activo'
                            CHECK (estado IN ('activo', 'finalizado')),

    fecha_asignacion        TIMESTAMPTZ NOT NULL DEFAULT now(),

    fecha_finalizacion      TIMESTAMPTZ,

    notas                   TEXT,

    motivo_finalizacion     TEXT,

    asignado_por_usuario_id UUID
                            REFERENCES sistema.usuario(id)
                            ON DELETE SET NULL,

    finalizado_por_usuario_id UUID
                            REFERENCES sistema.usuario(id)
                            ON DELETE SET NULL,

    creado_en               TIMESTAMPTZ NOT NULL DEFAULT now(),

    actualizado_en          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (tecnico_campo_id, productor_id)
);

-- ============================================================
-- 1a. INVESTIGADOR - USUARIO (1:1)
-- Relación entre investigador y usuario del sistema
-- ============================================================
CREATE TABLE IF NOT EXISTS social.investigador (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES sistema.usuario(id) 
                        ON DELETE CASCADE,
  institucion           VARCHAR(200),
  especialidad          VARCHAR(150),
  orcid                 VARCHAR(30),
  pais                  VARCHAR(80),
  notas                 TEXT,
  creado_en             TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en        TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(user_id)
);

-- ============================================================
-- 4. CONSENTIMIENTO INFORMADO
-- Registro de consentimiento informado para uso de datos y fotografías de los productores
-- ============================================================

CREATE TABLE IF NOT EXISTS social.consentimiento (
    id                   SERIAL PRIMARY KEY,
    productor_id         UUID REFERENCES core.productor(id) 
                         ON DELETE CASCADE 
                         ON UPDATE CASCADE,
    fecha                DATE DEFAULT CURRENT_DATE,
    tipo                 VARCHAR(20) ,
    autoriza_foto        BOOLEAN DEFAULT FALSE,
    autoriza_datos       BOOLEAN DEFAULT FALSE,
    autoriza_publicacion BOOLEAN DEFAULT FALSE,
    observaciones        TEXT,
    registrado_por       UUID REFERENCES social.tecnico_campo(id) 
                         ON DELETE SET NULL 
                         ON UPDATE CASCADE,
    created_at           TIMESTAMP DEFAULT NOW(),
    updated_at           TIMESTAMP DEFAULT NOW(),
    creado_en            TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (tipo IN ('verbal','escrito'))
);

CREATE INDEX IF NOT EXISTS idx_consentimiento_productor ON social.consentimiento(productor_id);

CREATE TABLE IF NOT EXISTS social.informante (
    id                  SERIAL PRIMARY KEY,
    uuid                UUID UNIQUE DEFAULT uuid_generate_v4(),
    clave_anonima       VARCHAR(20) UNIQUE NOT NULL, -- Ej: INF-OAX-001
    comunidad_id        UUID REFERENCES core.comunidad(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE, -- localidad normalizada
    productor_id        UUID REFERENCES core.productor(id) 
                        ON DELETE SET NULL, -- Si el informante es productor registrado
    consentimiento_id   INTEGER REFERENCES social.consentimiento(id) 
                        ON DELETE SET NULL, -- Consentimiento formal asociado (opcional)
    -- Perfil sociodemográfico
    edad                SMALLINT,
    genero              VARCHAR(30),
    escolaridad         VARCHAR(80),
    ocupacion_principal VARCHAR(150),
    lengua_materna      VARCHAR(80),
    habla_espanol       BOOLEAN DEFAULT true,
    años_cultivando_maiz INTEGER,
    superficie_cultivo_ha NUMERIC(8,2),
    -- Tipo de informante clave
    es_custodio_semilla BOOLEAN DEFAULT false,
    es_lider_comunitario BOOLEAN DEFAULT false,
    es_curandero_tradicional BOOLEAN DEFAULT false,
    es_agricultor_tradicional BOOLEAN DEFAULT true,
    -- Metadatos
    fecha_registro       TIMESTAMPTZ DEFAULT now(),
    creado_por           UUID REFERENCES social.investigador(id),
    activo               BOOLEAN DEFAULT true,
    notas                TEXT,
    creado_en            TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 13. PRODUCTOR - GERMOPLASMA (N:M SIMPLIFICADA)
-- Relación directa y sencilla entre productores y germoplasma conservado.
-- Útil para consultas rápidas, sin detalles adicionales.
-- ============================================================
CREATE TABLE IF NOT EXISTS social.productor_germoplasma (
    productor_id        UUID NOT NULL REFERENCES core.productor(id) 
                        ON DELETE CASCADE 
                        ON UPDATE CASCADE,
    germoplasma_id      UUID NOT NULL REFERENCES core.germoplasma(id) 
                        ON DELETE CASCADE 
                        ON UPDATE CASCADE,

    PRIMARY KEY (productor_id, germoplasma_id)
);

-- ============================================================
-- 2. PRODUCTOR - PRÁCTICA AGRÍCOLA (N:M)
-- Relación entre productores y prácticas agrícolas (un productor puede tener varias prácticas, y una práctica puede aplicarse a varios productores)
-- Relacion productor <-> practicas (N:M)
-- ============================================================

CREATE TABLE IF NOT EXISTS social.productor_practica (
    productor_id        UUID REFERENCES core.productor(id) 
                        ON DELETE CASCADE 
                        ON UPDATE CASCADE,
    practica_id         INTEGER REFERENCES catalogo.practica_agricola(id) 
                        ON DELETE CASCADE 
                        ON UPDATE CASCADE,

    PRIMARY KEY (productor_id, practica_id)
);

-- ============================================================
-- 3. PRODUCTOR - LENGUA (N:M)
-- Relación entre productores y lenguas originarias (un productor puede hablar varias lenguas, y una lengua puede ser hablada por varios productores)   
-- Relacion productor <-> lenguas (N:M)
-- ============================================================

CREATE TABLE IF NOT EXISTS social.productor_lengua (
    productor_id        UUID REFERENCES core.productor(id) 
                        ON DELETE CASCADE 
                        ON UPDATE CASCADE,
    lengua_id           INTEGER REFERENCES catalogo.lengua(id) 
                        ON DELETE CASCADE 
                        ON UPDATE CASCADE,
    es_materna          BOOLEAN DEFAULT FALSE,

    PRIMARY KEY (productor_id, lengua_id)
);


-- ============================================================
-- 5. PERFIL SOCIOECONOMICO
-- Información socioeconómica de los productores, incluyendo seguridad alimentaria, acceso a servicios, redes de intercambio, etc.
-- ============================================================

CREATE TABLE IF NOT EXISTS social.perfil_socioeconomico (
    id                            SERIAL PRIMARY KEY,
    productor_id                  UUID REFERENCES core.productor(id) ON DELETE CASCADE ON UPDATE CASCADE UNIQUE,
    escolaridad                   VARCHAR(30) CHECK (escolaridad IN (
                                      'sin_escolaridad','primaria','secundaria',
                                      'preparatoria','superior','otra'
                                  )),
    escolaridad_otra              VARCHAR(100), -- quitar si no se usa
    superficie_total_ha           DECIMAL(8,4) CHECK (superficie_total_ha >= 0),
    superficie_maiz_ha            DECIMAL(8,4) CHECK (superficie_maiz_ha >= 0),
    otros_cultivos                TEXT,
    decision_siembra              VARCHAR(50) CHECK (decision_siembra IN (
                                      'productor','pareja','ambos','familia','otro'
                                  )),
    -- Datos antropometricos
    peso_kg                       DECIMAL(5,2) CHECK (peso_kg BETWEEN 30 AND 200),
    talla_cm                      DECIMAL(5,2) CHECK (talla_cm BETWEEN 120 AND 220),
    imc                           DECIMAL(5,2) GENERATED ALWAYS AS (
                                      CASE WHEN talla_cm > 0
                                      THEN peso_kg / POWER(talla_cm / 100.0, 2)
                                      ELSE NULL END
                                  ) STORED,
    pct_grasa                     DECIMAL(5,2),
    circunferencia_cintura_cm     DECIMAL(5,2),
    circunferencia_cadera_cm      DECIMAL(5,2),
    circunferencia_pantorrilla_cm DECIMAL(5,2), -- quitar si no se usa
    diagnostico_enfermedad        TEXT,
    fecha_registro                DATE DEFAULT CURRENT_DATE, -- quitar si no se usa
    created_at                    TIMESTAMP DEFAULT NOW(),
    updated_at                    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 6. SEGURIDAD ALIMENTARIA (Escala ELCSA)
-- Información sobre la seguridad alimentaria de los productores, utilizando la escala ELCSA (Escala Latinoamericana y Caribeña de Seguridad Alimentaria)
-- ============================================================

CREATE TABLE IF NOT EXISTS social.seguridad_alimentaria (
    id                         SERIAL PRIMARY KEY,
    productor_id               UUID REFERENCES core.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
    num_personas_hogar         SMALLINT,
    num_hombres_adultos        SMALLINT,
    num_mujeres_adultas        SMALLINT,
    num_ninos                  SMALLINT,
    num_ninas                  SMALLINT,
    gasto_semanal_maiz         DECIMAL(8,2),
    gasto_semanal_frijol       DECIMAL(8,2),
    produce_suficiente_maiz    VARCHAR(20) CHECK (produce_suficiente_maiz IN (
                                   'si','no','parcialmente'
                               )),
    alimentacion_variada       BOOLEAN,
    alimentacion_variada_razon TEXT,
    -- Frecuencia de consumo (ultimos 7 dias) Ajustar esto 
    freq_tortilla              VARCHAR(20) CHECK (freq_tortilla IN (
                                   'nunca','1_2_veces','3_5_veces','mas_5_veces'
                               )),
    freq_tamales               VARCHAR(20) CHECK (freq_tamales IN (
                                   'nunca','1_2_veces','3_5_veces','mas_5_veces'
                               )),
    freq_atole                 VARCHAR(20) CHECK (freq_atole IN (
                                   'nunca','1_2_veces','3_5_veces','mas_5_veces'
                               )),
    freq_pozole                VARCHAR(20) CHECK (freq_pozole IN (
                                   'nunca','1_2_veces','3_5_veces','mas_5_veces'
                               )),
    otros_alimentos            TEXT,
    -- ELCSA (0=Nunca 1=Rara vez 2=Algunas veces 3=Frecuentemente)
    elcsa_preocupacion         SMALLINT CHECK (elcsa_preocupacion BETWEEN 0 AND 3),
    elcsa_poca_variedad        SMALLINT CHECK (elcsa_poca_variedad BETWEEN 0 AND 3),
    elcsa_salto_comida         SMALLINT CHECK (elcsa_salto_comida BETWEEN 0 AND 3),
    elcsa_comio_menos          SMALLINT CHECK (elcsa_comio_menos BETWEEN 0 AND 3),
    elcsa_sintio_hambre        SMALLINT CHECK (elcsa_sintio_hambre BETWEEN 0 AND 3),
    elcsa_dejo_comer_dia       SMALLINT CHECK (elcsa_dejo_comer_dia BETWEEN 0 AND 3),
    elcsa_puntaje_total        SMALLINT GENERATED ALWAYS AS (
                                   COALESCE(elcsa_preocupacion,0) +
                                   COALESCE(elcsa_poca_variedad,0) +
                                   COALESCE(elcsa_salto_comida,0) +
                                   COALESCE(elcsa_comio_menos,0) +
                                   COALESCE(elcsa_sintio_hambre,0) +
                                   COALESCE(elcsa_dejo_comer_dia,0)
                               ) STORED,
    nivel_inseguridad          VARCHAR(30) GENERATED ALWAYS AS (
                                   CASE
                                     WHEN (COALESCE(elcsa_preocupacion,0)+
                                           COALESCE(elcsa_poca_variedad,0)+
                                           COALESCE(elcsa_salto_comida,0)+
                                           COALESCE(elcsa_comio_menos,0)+
                                           COALESCE(elcsa_sintio_hambre,0)+
                                           COALESCE(elcsa_dejo_comer_dia,0)) = 0
                                          THEN 'seguridad_alimentaria'
                                     WHEN (COALESCE(elcsa_preocupacion,0)+
                                           COALESCE(elcsa_poca_variedad,0)+
                                           COALESCE(elcsa_salto_comida,0)+
                                           COALESCE(elcsa_comio_menos,0)+
                                           COALESCE(elcsa_sintio_hambre,0)+
                                           COALESCE(elcsa_dejo_comer_dia,0))
                                           BETWEEN 1 AND 5 THEN 'inseguridad_leve'
                                     WHEN (COALESCE(elcsa_preocupacion,0)+
                                           COALESCE(elcsa_poca_variedad,0)+
                                           COALESCE(elcsa_salto_comida,0)+
                                           COALESCE(elcsa_comio_menos,0)+
                                           COALESCE(elcsa_sintio_hambre,0)+
                                           COALESCE(elcsa_dejo_comer_dia,0))
                                           BETWEEN 6 AND 10 THEN 'inseguridad_moderada'
                                     ELSE 'inseguridad_severa'
                                   END
                               ) STORED,
    fecha_evaluacion           DATE DEFAULT CURRENT_DATE,
    created_at                 TIMESTAMP DEFAULT NOW(),
    updated_at                 TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seguridad_productor ON social.seguridad_alimentaria(productor_id);

-- ============================================================
-- 7. RED DE INTERCAMBIO Y CAPITAL SOCIAL
-- Información sobre las redes de intercambio de semillas, conocimientos y apoyos entre los productores, así como su acceso a servicios básicos y programas de apoyo.
-- ============================================================

CREATE TABLE IF NOT EXISTS social.red_intercambio (
    id                               SERIAL PRIMARY KEY,
    productor_id                     UUID REFERENCES core.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
    frecuencia_intercambio_semilla   VARCHAR(30) CHECK (frecuencia_intercambio_semilla IN (
                                         'nunca','ocasionalmente','frecuentemente','siempre'
                                     )),
    participa_ferias_semillas        BOOLEAN DEFAULT FALSE,
    ferias_descripcion               TEXT,
    decision_cultivos                VARCHAR(50),
    -- Servicios basicos del hogar
    servicio_agua_entubada           BOOLEAN DEFAULT FALSE,
    servicio_electricidad            BOOLEAN DEFAULT FALSE,
    servicio_internet                BOOLEAN DEFAULT FALSE,
    servicio_drenaje                 BOOLEAN DEFAULT FALSE,
    tiene_telefono_movil             BOOLEAN DEFAULT FALSE,
    tiene_radio                      BOOLEAN DEFAULT FALSE,
    -- Capacitacion y apoyos
    recibio_capacitacion             BOOLEAN DEFAULT FALSE,
    capacitacion_fuente              VARCHAR(200),
    tiene_acceso_credito             BOOLEAN DEFAULT FALSE,
    credito_fuente                   VARCHAR(200),
    recibio_apoyo_programa           BOOLEAN DEFAULT FALSE,
    apoyo_descripcion                TEXT,
    pertenece_organizacion           BOOLEAN DEFAULT FALSE,
    organizacion_nombre              VARCHAR(200),
    organizacion_tipo                VARCHAR(50),
    -- Migracion
    hay_migracion_hogar              BOOLEAN DEFAULT FALSE,
    impacto_migracion                TEXT,
    -- Motivaciones para sembrar
    motivacion_tradicion             BOOLEAN DEFAULT FALSE,
    motivacion_ingresos              BOOLEAN DEFAULT FALSE,
    motivacion_autoconsumo           BOOLEAN DEFAULT FALSE,
    motivacion_seguridad_alimentaria BOOLEAN DEFAULT FALSE,
    motivacion_otra                  VARCHAR(200),
    -- Desmotivaciones
    desmotivacion_costo_insumos      BOOLEAN DEFAULT FALSE,
    desmotivacion_falta_mano_obra    BOOLEAN DEFAULT FALSE,
    desmotivacion_cambio_climatico   BOOLEAN DEFAULT FALSE,
    desmotivacion_plagas             BOOLEAN DEFAULT FALSE,
    desmotivacion_falta_agua         BOOLEAN DEFAULT FALSE,
    desmotivacion_baja_rentabilidad  BOOLEAN DEFAULT FALSE,
    desmotivacion_otra               VARCHAR(200),
    razon_abandono_nativas           TEXT,
    apoyos_necesarios                TEXT,
    fecha_registro                   DATE DEFAULT CURRENT_DATE,
    created_at                       TIMESTAMP DEFAULT NOW(),
    updated_at                       TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_red_productor ON social.red_intercambio(productor_id);

-- ============================================================
-- 8. VULNERABILIDAD CLIMATICA PERCIBIDA
-- Información sobre la percepción de vulnerabilidad climática de los productores, incluyendo eventos climáticos extremos, cambios en patrones de lluvia y temperatura, y estrategias de adaptación.
-- ============================================================

CREATE TABLE IF NOT EXISTS social.vulnerabilidad_climatica (
    id                               SERIAL PRIMARY KEY,
    productor_id                     UUID REFERENCES core.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
    se_siente_vulnerable             BOOLEAN,
    razon_vulnerabilidad             TEXT,
    afecta_sequia                    BOOLEAN DEFAULT FALSE,
    afecta_heladas                   BOOLEAN DEFAULT FALSE,
    afecta_lluvias_intensas          BOOLEAN DEFAULT FALSE,
    afecta_vientos                   BOOLEAN DEFAULT FALSE,
    afecta_inundaciones              BOOLEAN DEFAULT FALSE,
    afecta_granizo                   BOOLEAN DEFAULT FALSE,
    otros_eventos                    VARCHAR(200),
    percibe_cambio_lluvia            BOOLEAN,
    descripcion_cambio_lluvia        TEXT,
    percibe_cambio_temperatura       BOOLEAN,
    descripcion_cambio_temperatura   TEXT,
    percibe_cambio_ciclo_cultivo     BOOLEAN,
    descripcion_cambio_ciclo         TEXT,
    -- Estrategias de adaptacion actuales
    estrategia_cambio_fecha_siembra  BOOLEAN DEFAULT FALSE,
    estrategia_variedad_resistente   BOOLEAN DEFAULT FALSE,
    estrategia_diversificacion       BOOLEAN DEFAULT FALSE,
    estrategia_almacenamiento_agua   BOOLEAN DEFAULT FALSE,
    estrategia_seguro_agricola       BOOLEAN DEFAULT FALSE,
    estrategias_otras                TEXT,
    anios_sembrando_maiz              SMALLINT,
    fecha_registro                   DATE DEFAULT CURRENT_DATE,
    created_at                       TIMESTAMP DEFAULT NOW(),
    updated_at                       TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vulnerabilidad_productor ON social.vulnerabilidad_climatica(productor_id);

-- ============================================================
-- 9. GEOLOCALIZACIÓN DE PRODUCTORES
-- Información de geolocalización de los productores, incluyendo coordenadas GPS, fotografías de campo y metadatos de captura.
-- ============================================================
CREATE TABLE IF NOT EXISTS social.geolocalizacion_productor (
    id                  SERIAL PRIMARY KEY,
    productor_id        UUID REFERENCES core.productor(id) ON DELETE CASCADE ON UPDATE CASCADE UNIQUE,

    -- Coordenadas GPS (formato KoboToolbox: lat lon alt precisión)
    latitud             DECIMAL(10, 7),
    longitud            DECIMAL(10, 7),
    altitud_m           DECIMAL(8, 2),
    precision_m         DECIMAL(6, 2),    -- Precisión GPS en metros
    geom                GEOMETRY(Point, 4326), -- Columna geométrica para PostGIS

    -- Validación geográfica (Huasteca Potosina)
    -- SLP: lat ~20.5–22.5 / lon ~-99.5 a -98.0
    CONSTRAINT chk_latitud  CHECK (latitud  BETWEEN 20.0 AND 23.0),
    CONSTRAINT chk_longitud CHECK (longitud BETWEEN -100.5 AND -97.5),

    -- Fotografías (rutas relativas al almacenamiento del proyecto)
    -- KoboToolbox exporta los nombres de archivo; las rutas
    -- se construyen al momento de la descarga del media.
    foto_productor      VARCHAR(255),     -- Nombre de archivo: foto_productor.jpg
    foto_parcela        VARCHAR(255),     -- Nombre de archivo: foto_parcela.jpg
    foto_cultivo        VARCHAR(255),     -- Nombre de archivo: foto_cultivo.jpg
    descripcion_foto    TEXT,             -- Descripción libre de las fotografías

    -- Metadatos de captura
    fecha_captura       DATE DEFAULT CURRENT_DATE,
    dispositivo_id      VARCHAR(100),     -- deviceid de KoboToolbox
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 10. SISTEMA DE SEMILLA
-- El sistema de semilla documenta las prácticas de conservación, selección, almacenamiento y tratamiento de la semilla que los productores utilizan para mantener su germoplasma a lo largo del tiempo. Es fundamental para entender la dinámica de la diversidad genética y las estrategias de manejo que los productores emplean para conservar sus variedades de maíz nativo. 
-- ============================================================
CREATE TABLE IF NOT EXISTS social.sistema_semilla (
    id                          SERIAL PRIMARY KEY,
    productor_id                UUID NOT NULL REFERENCES core.productor(id) ON DELETE RESTRICT ON UPDATE CASCADE,   -- FK a social.productor
    germoplasma_id              UUID NOT NULL REFERENCES core.germoplasma(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- Origen
    origen_semilla_id           INTEGER REFERENCES catalogo.origen_semilla(id) ON DELETE SET NULL ON UPDATE CASCADE,
    origen_detalle              VARCHAR(200),
    anios_conservando_semilla    SMALLINT CHECK (anios_conservando_semilla >= 0),
    anios_antes_renovar          SMALLINT CHECK (anios_antes_renovar >= 0),
    -- Criterios de selección
    criterio_tamaño             BOOLEAN DEFAULT FALSE,
    criterio_color              BOOLEAN DEFAULT FALSE,
    criterio_sanidad            BOOLEAN DEFAULT FALSE,
    criterio_planta_madre       BOOLEAN DEFAULT FALSE,
    criterio_rendimiento        BOOLEAN DEFAULT FALSE,
    criterio_ciclo              BOOLEAN DEFAULT FALSE,
    criterios_otros             TEXT,
    descripcion_seleccion       TEXT,
    -- Almacenamiento
    metodo_almacenamiento_id       INTEGER REFERENCES catalogo.metodo_almacenamiento(id) ON DELETE SET NULL ON UPDATE CASCADE,
    metodo_almacenamiento_otro  VARCHAR(100),
    -- Tratamiento
    aplica_tratamiento          BOOLEAN DEFAULT FALSE,
    tratamiento_ceniza          BOOLEAN DEFAULT FALSE,
    tratamiento_cal             BOOLEAN DEFAULT FALSE,
    tratamiento_hierbas         BOOLEAN DEFAULT FALSE,
    tratamiento_insecticida     BOOLEAN DEFAULT FALSE,
    tratamiento_otro            VARCHAR(150),
    -- Resguardo
    tiene_semilla_resguardo     BOOLEAN DEFAULT FALSE,
    cantidad_resguardo_kg       DECIMAL(8,2),
    -- Ventajas percibidas
    ventaja_resistencia_acame   BOOLEAN DEFAULT FALSE,
    ventaja_resistencia_heladas BOOLEAN DEFAULT FALSE,
    ventaja_resistencia_plagas  BOOLEAN DEFAULT FALSE,
    ventaja_resistencia_sequia  BOOLEAN DEFAULT FALSE,
    ventaja_alto_rendimiento    BOOLEAN DEFAULT FALSE,
    ventaja_buen_sabor          BOOLEAN DEFAULT FALSE,
    ventajas_otras              TEXT,
    -- Problemas percibidos
    problema_acame              BOOLEAN DEFAULT FALSE,
    problema_heladas            BOOLEAN DEFAULT FALSE,
    problema_plagas             BOOLEAN DEFAULT FALSE,
    problema_sequia             BOOLEAN DEFAULT FALSE,
    problema_bajo_rendimiento   BOOLEAN DEFAULT FALSE,
    problemas_otros             TEXT,
    fecha_registro              DATE DEFAULT CURRENT_DATE,
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sistema_semilla_productor ON social.sistema_semilla(productor_id);

CREATE INDEX IF NOT EXISTS idx_sistema_semilla_germoplasma ON social.sistema_semilla(germoplasma_id);

-- ============================================================
-- 11. ECONOMÍA DEL CULTIVO
-- Esta tabla documenta los costos e ingresos asociados a cada cultivo, así como las prácticas de manejo implementadas y los problemas de producción enfrentados. Esta información es crucial para realizar análisis económicos que permitan entender la rentabilidad de los cultivos de maíz nativo y para identificar las principales limitaciones y oportunidades que enfrentan los productores en la región. 
-- ============================================================
CREATE TABLE IF NOT EXISTS social.economia_cultivo (
    id                          SERIAL PRIMARY KEY,
    cultivo_id                  UUID NOT NULL REFERENCES core.cultivo(id) ON DELETE CASCADE ON UPDATE CASCADE,
    -- Costos (pesos MXN)
    costo_semilla               DECIMAL(10,2) CHECK (costo_semilla >= 0),
    costo_fertilizantes         DECIMAL(10,2) CHECK (costo_fertilizantes >= 0),
    costo_plaguicidas           DECIMAL(10,2) CHECK (costo_plaguicidas >= 0),
    costo_mano_obra             DECIMAL(10,2) CHECK (costo_mano_obra >= 0),
    costo_transporte            DECIMAL(10,2) CHECK (costo_transporte >= 0),
    costo_riego                 DECIMAL(10,2) CHECK (costo_riego >= 0),
    costo_otros                 DECIMAL(10,2) CHECK (costo_otros >= 0),
    costo_otros_descripcion     VARCHAR(200),
    costo_total                 DECIMAL(10,2) GENERATED ALWAYS AS (
                                    COALESCE(costo_semilla,0) + COALESCE(costo_fertilizantes,0) +
                                    COALESCE(costo_plaguicidas,0) + COALESCE(costo_mano_obra,0) +
                                    COALESCE(costo_transporte,0) + COALESCE(costo_riego,0) +
                                    COALESCE(costo_otros,0)
                                ) STORED,
    -- Ingresos
    ingreso_venta_maiz          DECIMAL(10,2),
    ingreso_otros               DECIMAL(10,2),
    ingreso_otros_descripcion   VARCHAR(200),
    -- Prácticas de manejo
    manejo_riego                BOOLEAN DEFAULT FALSE,
    manejo_fertilizacion_org    BOOLEAN DEFAULT FALSE,
    manejo_fertilizacion_quim   BOOLEAN DEFAULT FALSE,
    manejo_labranza_minima      BOOLEAN DEFAULT FALSE,
    manejo_mulch                BOOLEAN DEFAULT FALSE,
    manejo_control_manual_maleza BOOLEAN DEFAULT FALSE,
    manejo_herbicidas           BOOLEAN DEFAULT FALSE,
    manejo_plaguicidas          BOOLEAN DEFAULT FALSE,
    manejo_otros                VARCHAR(200),
    -- Problemas de producción
    problema_clima              BOOLEAN DEFAULT FALSE,
    problema_heladas            BOOLEAN DEFAULT FALSE,
    problema_sequia             BOOLEAN DEFAULT FALSE,
    problema_plagas             BOOLEAN DEFAULT FALSE,
    problema_acame              BOOLEAN DEFAULT FALSE,
    problema_malezas            BOOLEAN DEFAULT FALSE,
    problema_insumos            BOOLEAN DEFAULT FALSE,
    problema_precio             BOOLEAN DEFAULT FALSE,
    problemas_descripcion       TEXT,
    ciclo_agricola_id           INTEGER REFERENCES catalogo.ciclo_agricola(id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha_registro              DATE DEFAULT CURRENT_DATE,
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_economia_cultivo ON social.economia_cultivo(cultivo_id);


-- ============================================================
-- ENTREVISTAS SEMIESTRUCTURADAS (Hammersley & Atkinson, 2007)
-- ============================================================

-- ============================================================
-- 15. ENTREVISTAS
-- Registro detallado de entrevistas a informantes
-- ============================================================
CREATE TABLE IF NOT EXISTS social.entrevista (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo          VARCHAR(30) UNIQUE NOT NULL, -- Ej: ENT-OAX-2024-001
    informante_id   INTEGER NOT NULL REFERENCES social.informante(id),
    investigador_id UUID NOT NULL REFERENCES social.investigador(id),
    comunidad_id    UUID REFERENCES core.comunidad(id),
    -- Contexto
    fecha_inicio    TIMESTAMPTZ NOT NULL,
    fecha_fin       TIMESTAMPTZ,
    duracion_minutos INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (fecha_fin - fecha_inicio)) / 60
    ) STORED,
    modalidad       VARCHAR(30) DEFAULT 'presencial' CHECK (modalidad IN ('presencial','virtual','mixta')),
    lugar_entrevista VARCHAR(200),
    idioma          VARCHAR(80),
    traduccion_requerida BOOLEAN DEFAULT false,
    -- Estado
    estado          VARCHAR(20) DEFAULT 'programada' CHECK (
        estado IN ('programada','en_curso','completada','cancelada','pendiente_transcripcion')
    ),
    -- Guía temática (semiestructurada)
    temas_cubiertos JSONB DEFAULT '[]',
    -- Archivos
    archivo_audio_url   TEXT,
    transcripcion_url   TEXT,
    notas_campo         TEXT,
    -- Metadatos
    creado_en   TIMESTAMPTZ DEFAULT now(),
    actualizado_en TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_entrevista_informante ON social.entrevista(informante_id);
CREATE INDEX idx_entrevista_comunidad  ON social.entrevista(comunidad_id);
CREATE INDEX idx_entrevista_fecha      ON social.entrevista(fecha_inicio DESC);
CREATE INDEX idx_entrevista_estado     ON social.entrevista(estado);

CREATE TABLE social.guias_entrevista (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version     VARCHAR(10) NOT NULL DEFAULT 'v1.0',
    titulo      VARCHAR(200) NOT NULL,
    descripcion TEXT,
    modulo      VARCHAR(30) CHECK (modulo IN ('social','cultural','productivo','mixto')),
    activa      BOOLEAN DEFAULT true,
    creado_en   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE social.preguntas_guia (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guia_id         UUID NOT NULL REFERENCES social.guias_entrevista(id),
    orden           SMALLINT NOT NULL,
    categoria       VARCHAR(80),
    pregunta_base   TEXT NOT NULL,
    preguntas_sonda TEXT[], -- preguntas de seguimiento
    tipo_respuesta  VARCHAR(30) DEFAULT 'abierta' CHECK (
        tipo_respuesta IN ('abierta','cerrada','escala_likert','ranking','fotovoz')
    ),
    aplica_a        VARCHAR(20) DEFAULT 'todos' CHECK (aplica_a IN ('todos','custodios','agricultores','lideres')),
    activa          BOOLEAN DEFAULT true
);

CREATE TABLE social.respuestas_entrevista (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entrevista_id   UUID NOT NULL REFERENCES social.entrevista(id),
    pregunta_id     UUID REFERENCES social.preguntas_guia(id),
    -- Contenido
    respuesta_texto     TEXT,
    respuesta_numerica  NUMERIC,
    respuesta_json      JSONB,
    -- Análisis cualitativo del discurso (Spradley, 2016)
    codigos_analiticos  TEXT[],
    categorias_emergentes TEXT[],
    citas_textuales     TEXT[],
    memo_analitico      TEXT,
    -- Relación con maíz nativo
    menciona_variedad       BOOLEAN DEFAULT false,
    variedades_mencionadas  TEXT[],
    -- Metadatos
    creado_en   TIMESTAMPTZ DEFAULT now()
);