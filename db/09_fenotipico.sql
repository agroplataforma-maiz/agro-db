-- ============================================================
-- ESQUEMA: fenotipico
-- Evaluaciones fenotípicas (22 variables Anexo I),
-- evidencia multimedia, análisis nutrimental (Etapa 2)
-- Residente
-- ============================================================

SET search_path TO fenotipico, public;

-- ============================================================
-- 1. EVALUACION FENOTIPICA
-- Evaluación fenotípica completa (22 variables Anexo I)
-- ============================================================
CREATE TABLE IF NOT EXISTS fenotipico.evaluacion_fenotipica (
    id               SERIAL PRIMARY KEY,
    variedad_id      INTEGER NOT NULL REFERENCES agro.variedades(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    ciclo_eval       VARCHAR(20) NOT NULL,        -- 'OI-2024', 'PV-2024'
    anio_eval        SMALLINT NOT NULL,
    comunidad_id     INTEGER REFERENCES core.comunidad(id) ON DELETE SET NULL ON UPDATE CASCADE, -- localidad normalizada
    evaluador_id     INTEGER REFERENCES sistema.usuarios(id) ON DELETE SET NULL ON UPDATE CASCADE,      -- evaluador normalizado
    etapa_bbch_max   INTEGER REFERENCES catalogo.etapa_fenologica(id) ON DELETE SET NULL ON UPDATE CASCADE, -- última etapa alcanzada
    completitud_pct  NUMERIC(5,2) DEFAULT 0.00,  -- 0-100, calculado por trigger
    observaciones    TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(variedad_id, ciclo_eval, comunidad_id)
);

CREATE INDEX IF NOT EXISTS idx_eval_cultivo ON fenotipico.evaluacion_fenotipica(cultivo_id);
CREATE INDEX IF NOT EXISTS idx_eval_comunidad ON fenotipico.evaluacion_fenotipica(comunidad_id);
CREATE INDEX IF NOT EXISTS idx_evidencia_evaluacion ON fenotipico.evidencia(evaluacion_id);

CREATE INDEX ix_ef_variedad  ON fenotipico.evaluacion_fenotipica(variedad_id);
CREATE INDEX ix_ef_ciclo     ON fenotipico.evaluacion_fenotipica(ciclo_eval, año_eval);
CREATE INDEX ix_vf_eval      ON fenotipico.valores_fenotipicos(evaluacion_id);
CREATE INDEX ix_vf_desc      ON fenotipico.valores_fenotipicos(descriptor_id);


CREATE TABLE IF NOT EXISTS fenotipico.valores_fenotipicos (
    id               SERIAL          PRIMARY KEY,
    evaluacion_id    INTEGER         NOT NULL REFERENCES fenotipico.evaluacion_fenotipica(id) ON DELETE CASCADE,
    descriptor_id    SMALLINT        NOT NULL REFERENCES catalogo.descriptores_catalogo(id),
    valor_texto      VARCHAR(120),   -- para QL, PQ: "3. Débil"
    valor_numerico   NUMERIC(8,3),   -- para QN medibles: 68 (días), 4.2 (cm)
    valor_codigo     SMALLINT,       -- código numérico de la opción (1,3,5,7,9)
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT uq_eval_desc UNIQUE(evaluacion_id, descriptor_id),
    CONSTRAINT ck_valor CHECK (
        valor_texto IS NOT NULL OR valor_numerico IS NOT NULL
    )
);


-- ============================================================
-- 3. EVIDENCIA MULTIMEDIA
-- Evidencia multimedia
-- ============================================================
CREATE TABLE IF NOT EXISTS fenotipico.evidencia (
    id              SERIAL PRIMARY KEY,
    evaluacion_id   INTEGER NOT NULL REFERENCES fenotipico.evaluacion_fenotipica(id) ON DELETE CASCADE ON UPDATE CASCADE,
    tipo            VARCHAR(50) CHECK (tipo IN (
                        'planta','mazorca','parcela','productor',
                        'plaga','enfermedad','contexto','dron','satelital')),
    ruta_archivo    VARCHAR(500) NOT NULL,
    nombre_archivo  VARCHAR(300),
    campo_origen    VARCHAR(100),
    uuid_envio      VARCHAR(100),
    subtipo         VARCHAR(30) CHECK (subtipo IN (
                                 'planta_completa',
                                 'mazorca_evaluada',
                                 'granos_medicion',
                                 'espiga',
                                 'plaga_enfermedad',
                                 'parcela',
                                 'dron',
                                 'satelital',
                                 'otro'
                             )),
    fecha_captura   TIMESTAMP,
    modelo_captura  VARCHAR(100),
    resolucion      VARCHAR(50),
    notas           TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_evidencia_eval ON fenotipico.evidencia(evaluacion_id);


-- ============================================================
-- ANÁLISIS NUTRIMENTAL (Etapa 2 - 30 muestras mínimo)
-- ============================================================

-- ============================================================
-- 4. MUESTRA NUTRIMENTAL
-- Muestra de maíz para análisis
-- ============================================================
CREATE TABLE IF NOT EXISTS fenotipico.muestra_nutrimental (
    id                  SERIAL PRIMARY KEY,
    codigo_muestra      VARCHAR(30) UNIQUE NOT NULL,   -- ej. MN-2026-001
    germoplasma_id      INTEGER NOT NULL REFERENCES agronomico.germoplasma(id) ON DELETE RESTRICT ON UPDATE CASCADE,   -- FK a agronomico.germoplasma
    parcela_id          INTEGER NOT NULL REFERENCES geografico.parcela(id) ON DELETE RESTRICT ON UPDATE CASCADE,   -- FK a geografico.parcela
    comunidad_id        INTEGER REFERENCES catalogo.comunidad(id) ON DELETE SET NULL,
    fecha_colecta       DATE CHECK (fecha_colecta <= CURRENT_DATE),
    peso_muestra_g      DECIMAL(8,2),
    condicion_muestra   VARCHAR(50) CHECK (condicion_muestra IN (
                            'fresca','seca','procesada','harina')),
    laboratorio         VARCHAR(200),
    fecha_analisis      DATE,
    notas               TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_muestra_germoplasma ON fenotipico.muestra_nutrimental(germoplasma_id);

-- ============================================================
-- 5. RESULTADO NUTRIMENTAL
-- Resultados del análisis nutrimental
-- ============================================================
CREATE TABLE IF NOT EXISTS fenotipico.resultado_nutrimental (
    id                          SERIAL PRIMARY KEY,
    muestra_id                  INTEGER NOT NULL REFERENCES fenotipico.muestra_nutrimental(id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Macronutrientes (g/100g base seca)
    humedad_pct                 DECIMAL(6,3) CHECK (humedad_pct BETWEEN 0 AND 100),
    proteina_pct                DECIMAL(6,3) CHECK (proteina_pct >= 0),
    grasa_pct                   DECIMAL(6,3) CHECK (grasa_pct >= 0),
    carbohidratos_pct           DECIMAL(6,3) CHECK (carbohidratos_pct >= 0),
    fibra_cruda_pct             DECIMAL(6,3),
    fibra_dietetica_total_pct   DECIMAL(6,3),
    cenizas_pct                 DECIMAL(6,3),
    energia_kcal                DECIMAL(8,2),

    -- Micronutrientes (mg/100g)
    calcio_mg                   DECIMAL(8,3),
    fosforo_mg                  DECIMAL(8,3),
    hierro_mg                   DECIMAL(8,3),
    zinc_mg                     DECIMAL(8,3),
    magnesio_mg                 DECIMAL(8,3),
    potasio_mg                  DECIMAL(8,3),
    sodio_mg                    DECIMAL(8,3),

    -- Vitaminas (mg/100g o µg/100g)
    vitamina_a_ug               DECIMAL(8,3),
    vitamina_b1_mg              DECIMAL(8,3),
    vitamina_b2_mg              DECIMAL(8,3),
    vitamina_b3_mg              DECIMAL(8,3),
    vitamina_c_mg               DECIMAL(8,3),
    vitamina_e_mg               DECIMAL(8,3),

    -- Compuestos bioactivos
    antocianinas_mg             DECIMAL(8,3),   -- relevante en maíces de color
    carotenoides_mg             DECIMAL(8,3),
    polifenoles_mg              DECIMAL(8,3),
    capacidad_antioxidante      DECIMAL(8,3),   -- DPPH o ABTS

    -- Aminoácidos esenciales (g/100g proteína)
    lisina_pct                  DECIMAL(6,3),
    triptofano_pct              DECIMAL(6,3),

    -- Metadatos del análisis
    metodo_proteina             VARCHAR(100),   -- ej. Kjeldahl, AOAC 2001.11
    metodo_grasa                VARCHAR(100),   -- ej. Soxhlet
    metodo_fibra                VARCHAR(100),
    metodo_minerales            VARCHAR(100),   -- ej. ICP-OES
    laboratorio_certificado     BOOLEAN DEFAULT FALSE,
    norma_referencia            VARCHAR(100),   -- ej. NMX-F-068-S-1980
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_resultado_muestra ON fenotipico.resultado_nutrimental(muestra_id);