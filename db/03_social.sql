-- ============================================================
-- ESQUEMA: social
-- Productores, redes, seguridad alimentaria
-- PEE-2025-G-369 | TecNM Ciudad Valles
--
-- DEPENDE DE: 02_catalogo.sql (debe ejecutarse primero)
-- ============================================================

SET search_path TO social, catalogo, public;

-- Practica agricola (catalogo operacional, se queda en social)
CREATE TABLE social.practica_agricola (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL,
    descripcion TEXT,
    tipo        VARCHAR(50) CHECK (tipo IN (
                    'tradicional','agroecologica','mixta','convencional'
                ))
);

-- ============================================================
-- PRODUCTOR / CUSTODIO
-- Referencia catalogo.municipio, catalogo.localidad
-- y catalogo.comunidad en lugar de social.comunidad
-- ============================================================

CREATE TABLE social.productor (
    id                  SERIAL PRIMARY KEY,
    nombres             VARCHAR(150) NOT NULL,
    apellido_paterno    VARCHAR(100),
    apellido_materno    VARCHAR(100),
    edad                SMALLINT CHECK (edad BETWEEN 10 AND 110),
    genero              VARCHAR(30) CHECK (genero IN (
                            'masculino','femenino','no_binario','prefiere_no_decir'
                        )),
    años_experiencia    SMALLINT,
    tipo_manejo         VARCHAR(50) CHECK (tipo_manejo IN (
                            'tradicional','mixto','agroecologico','convencional'
                        )),
    fecha_registro      DATE DEFAULT CURRENT_DATE,

    -- Referencias al catalogo territorial
    municipio_id        INTEGER REFERENCES catalogo.municipio(id),
    localidad_id        INTEGER REFERENCES catalogo.localidad(id),
    comunidad_id        INTEGER REFERENCES catalogo.comunidad(id),

    -- Campo libre para comunidades no catalogadas aun
    -- (capturadas en campo antes de cruzar con el catalogo)
    comunidad_texto     VARCHAR(200),

    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_productor_municipio ON social.productor(municipio_id);
CREATE INDEX idx_productor_comunidad ON social.productor(comunidad_id);

-- Relacion productor <-> practicas (N:M)
CREATE TABLE social.productor_practica (
    productor_id INTEGER REFERENCES social.productor(id),
    practica_id  INTEGER REFERENCES social.practica_agricola(id),
    PRIMARY KEY (productor_id, practica_id)
);

-- Relacion productor <-> lenguas (N:M)
-- Referencia catalogo.lengua en lugar de social.lengua
CREATE TABLE social.productor_lengua (
    productor_id INTEGER REFERENCES social.productor(id),
    lengua_id    INTEGER REFERENCES catalogo.lengua(id),
    es_materna   BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (productor_id, lengua_id)
);

-- ============================================================
-- CONSENTIMIENTO INFORMADO
-- ============================================================

CREATE TABLE social.consentimiento (
    id                   SERIAL PRIMARY KEY,
    productor_id         INTEGER REFERENCES social.productor(id),
    fecha                DATE DEFAULT CURRENT_DATE,
    tipo                 VARCHAR(20) CHECK (tipo IN ('verbal','escrito')),
    autoriza_foto        BOOLEAN DEFAULT FALSE,
    autoriza_datos       BOOLEAN DEFAULT FALSE,
    autoriza_publicacion BOOLEAN DEFAULT FALSE,
    observaciones        TEXT,
    registrado_por       VARCHAR(150),
    created_at           TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- PERFIL SOCIOECONOMICO
-- ============================================================

CREATE TABLE social.perfil_socioeconomico (
    id                            SERIAL PRIMARY KEY,
    productor_id                  INTEGER REFERENCES social.productor(id) UNIQUE,
    escolaridad                   VARCHAR(30) CHECK (escolaridad IN (
                                      'sin_escolaridad','primaria','secundaria',
                                      'preparatoria','superior','otra'
                                  )),
    escolaridad_otra              VARCHAR(100),
    superficie_total_ha           DECIMAL(8,4) CHECK (superficie_total_ha >= 0),
    superficie_maiz_ha            DECIMAL(8,4) CHECK (superficie_maiz_ha >= 0),
    otros_cultivos                TEXT,
    decision_siembra              VARCHAR(50) CHECK (decision_siembra IN (
                                      'productor','pareja','ambos','otro'
                                  )),
    -- Datos antropometricos
    peso_kg                       DECIMAL(5,2),
    talla_cm                      DECIMAL(5,2),
    imc                           DECIMAL(5,2) GENERATED ALWAYS AS (
                                      CASE WHEN talla_cm > 0
                                      THEN peso_kg / POWER(talla_cm / 100.0, 2)
                                      ELSE NULL END
                                  ) STORED,
    pct_grasa                     DECIMAL(5,2),
    circunferencia_cintura_cm     DECIMAL(5,2),
    circunferencia_cadera_cm      DECIMAL(5,2),
    circunferencia_pantorrilla_cm DECIMAL(5,2),
    diagnostico_enfermedad        TEXT,
    fecha_registro                DATE DEFAULT CURRENT_DATE,
    created_at                    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- SEGURIDAD ALIMENTARIA (Escala ELCSA)
-- ============================================================

CREATE TABLE social.seguridad_alimentaria (
    id                         SERIAL PRIMARY KEY,
    productor_id               INTEGER REFERENCES social.productor(id),
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
    -- Frecuencia de consumo (ultimos 7 dias)
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
    created_at                 TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- RED DE INTERCAMBIO Y CAPITAL SOCIAL
-- ============================================================

CREATE TABLE social.red_intercambio (
    id                               SERIAL PRIMARY KEY,
    productor_id                     INTEGER REFERENCES social.productor(id),
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
    created_at                       TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- VULNERABILIDAD CLIMATICA PERCIBIDA
-- ============================================================

CREATE TABLE social.vulnerabilidad_climatica (
    id                               SERIAL PRIMARY KEY,
    productor_id                     INTEGER REFERENCES social.productor(id),
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
    años_sembrando_maiz              SMALLINT,
    fecha_registro                   DATE DEFAULT CURRENT_DATE,
    created_at                       TIMESTAMP DEFAULT NOW()
);
