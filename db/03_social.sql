-- ============================================================
-- ESQUEMA: social
-- Productores, redes, seguridad alimentaria
-- PEE-2025-G-369 | TecNM Ciudad Valles
--
-- DEPENDE DE: 02_catalogo.sql (debe ejecutarse primero)
-- ============================================================

SET search_path TO social, catalogo, public;


-- ============================================================
-- 1. PRODUCTOR / CUSTODIO
-- Referencia catalogo.municipio, catalogo.localidad
-- y catalogo.comunidad en lugar de social.comunidad
-- ============================================================

CREATE TABLE IF NOT EXISTS social.productor (
    id                  SERIAL PRIMARY KEY, -- Identificador único del productor
    nombres             VARCHAR(150) NOT NULL, -- Nombres del productor
    apellido_paterno    VARCHAR(100), -- Apellido paterno
    apellido_materno    VARCHAR(100), -- Apellido materno
    fecha_nacimiento    DATE DEFAULT NULL, -- Fecha de nacimiento
    genero              VARCHAR(30) CHECK (genero IN (
                            'masculino','femenino','no_binario','prefiere_no_decir'
                        )), -- Género del productor
    estado_civil        VARCHAR(30) CHECK (estado_civil IN (
                            'soltero','casado','union_libre','divorciado','viudo','otro'
                        )), -- Estado civil
    anios_experiencia   SMALLINT, -- Años de experiencia en la actividad
    telefono            VARCHAR(20), -- Teléfono de contacto
    correo_electronico  VARCHAR(150) DEFAULT NULL, -- Correo electrónico (opcional)
    tipo_productor_id   INTEGER REFERENCES catalogo.tipo_productor(id) ON DELETE SET NULL ON UPDATE CASCADE, -- FK tipo de productor
    municipio_id        INTEGER REFERENCES catalogo.municipio(id) ON DELETE SET NULL ON UPDATE CASCADE, -- FK municipio
    localidad_id        INTEGER REFERENCES catalogo.localidad(id) ON DELETE SET NULL ON UPDATE CASCADE, -- FK localidad
    fecha_registro      DATE DEFAULT CURRENT_DATE, -- Fecha de registro de datos
    created_at          TIMESTAMP DEFAULT NOW(), -- Timestamp de creación
    updated_at          TIMESTAMP DEFAULT NOW()
);


-- ============================================================
-- 2. PRODUCTOR - PRÁCTICA AGRÍCOLA (N:M)
-- Relación entre productores y prácticas agrícolas (un productor puede tener varias prácticas, y una práctica puede aplicarse a varios productores)
-- Relacion productor <-> practicas (N:M)
-- ============================================================

CREATE TABLE IF NOT EXISTS social.productor_practica (
    productor_id INTEGER REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
    practica_id  INTEGER REFERENCES catalogo.practica_agricola(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (productor_id, practica_id)
);

-- ============================================================
-- 3. PRODUCTOR - LENGUA (N:M)
-- Relación entre productores y lenguas originarias (un productor puede hablar varias lenguas, y una lengua puede ser hablada por varios productores)   
-- Relacion productor <-> lenguas (N:M)
-- ============================================================

CREATE TABLE IF NOT EXISTS social.productor_lengua (
    productor_id INTEGER REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
    lengua_id    INTEGER REFERENCES catalogo.lengua(id) ON DELETE CASCADE ON UPDATE CASCADE,
    es_materna   BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (productor_id, lengua_id)
);

-- ============================================================
-- 4. CONSENTIMIENTO INFORMADO
-- Registro de consentimiento informado para uso de datos y fotografías de los productores
-- ============================================================

CREATE TABLE IF NOT EXISTS social.consentimiento (
    id                   SERIAL PRIMARY KEY,
    productor_id         INTEGER REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
    fecha                DATE DEFAULT CURRENT_DATE,
    tipo                 VARCHAR(20) CHECK (tipo IN ('verbal','escrito')),
    autoriza_foto        BOOLEAN DEFAULT FALSE,
    autoriza_datos       BOOLEAN DEFAULT FALSE,
    autoriza_publicacion BOOLEAN DEFAULT FALSE,
    observaciones        TEXT,
    registrado_por       VARCHAR(150),
    created_at           TIMESTAMP DEFAULT NOW(),
    updated_at           TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 5. PERFIL SOCIOECONOMICO
-- Información socioeconómica de los productores, incluyendo seguridad alimentaria, acceso a servicios, redes de intercambio, etc.
-- ============================================================

CREATE TABLE IF NOT EXISTS social.perfil_socioeconomico (
    id                            SERIAL PRIMARY KEY,
    productor_id                  INTEGER REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE UNIQUE,
    escolaridad                   VARCHAR(30) CHECK (escolaridad IN (
                                      'sin_escolaridad','primaria','secundaria',
                                      'preparatoria','superior','otra'
                                  )),
    escolaridad_otra              VARCHAR(100),
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
    circunferencia_pantorrilla_cm DECIMAL(5,2),
    diagnostico_enfermedad        TEXT,
    fecha_registro                DATE DEFAULT CURRENT_DATE,
    created_at                    TIMESTAMP DEFAULT NOW(),
    updated_at                    TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 6. SEGURIDAD ALIMENTARIA (Escala ELCSA)
-- Información sobre la seguridad alimentaria de los productores, utilizando la escala ELCSA (Escala Latinoamericana y Caribeña de Seguridad Alimentaria)
-- ============================================================

CREATE TABLE IF NOT EXISTS social.seguridad_alimentaria (
    id                         SERIAL PRIMARY KEY,
    productor_id               INTEGER REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
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
    created_at                 TIMESTAMP DEFAULT NOW(),
    updated_at                 TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 7. RED DE INTERCAMBIO Y CAPITAL SOCIAL
-- Información sobre las redes de intercambio de semillas, conocimientos y apoyos entre los productores, así como su acceso a servicios básicos y programas de apoyo.
-- ============================================================

CREATE TABLE IF NOT EXISTS social.red_intercambio (
    id                               SERIAL PRIMARY KEY,
    productor_id                     INTEGER REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
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

-- ============================================================
-- 8. VULNERABILIDAD CLIMATICA PERCIBIDA
-- Información sobre la percepción de vulnerabilidad climática de los productores, incluyendo eventos climáticos extremos, cambios en patrones de lluvia y temperatura, y estrategias de adaptación.
-- ============================================================

CREATE TABLE IF NOT EXISTS social.vulnerabilidad_climatica (
    id                               SERIAL PRIMARY KEY,
    productor_id                     INTEGER REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE,
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

-- ============================================================
-- 9. GEOLOCALIZACIÓN DE PRODUCTORES
-- Información de geolocalización de los productores, incluyendo coordenadas GPS, fotografías de campo y metadatos de captura.
-- ============================================================
CREATE TABLE IF NOT EXISTS social.geolocalizacion_productor (
    id                  SERIAL PRIMARY KEY,
    productor_id        INTEGER REFERENCES social.productor(id) ON DELETE CASCADE ON UPDATE CASCADE UNIQUE,

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

