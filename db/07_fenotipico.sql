-- ============================================================
-- ESQUEMA: fenotipico
-- Evaluaciones fenotípicas (22 variables Anexo I),
-- evidencia multimedia, análisis nutrimental (Etapa 2)
-- ============================================================

SET search_path TO fenotipico, public;

-- ============================================================
-- 1. EVALUACION FENOTIPICA
-- Evaluación fenotípica completa (22 variables Anexo I)
-- ============================================================
CREATE TABLE IF NOT EXISTS fenotipico.evaluacion_fenotipica (
    id                              SERIAL PRIMARY KEY,
    cultivo_id                      INTEGER NOT NULL REFERENCES agronomico.cultivo(id) ON DELETE RESTRICT ON UPDATE CASCADE,   -- FK a agronomico.cultivo
    comunidad_id                    INTEGER REFERENCES catalogo.comunidad(id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha_evaluacion                DATE NOT NULL,
    evaluador                       VARCHAR(150),

    etapa_fenologica_id           INTEGER REFERENCES catalogo.etapa_fenologica(id) ON DELETE SET NULL ON UPDATE CASCADE,
    -- === VARIABLES DE MAZORCA (11 variables) ===
    tamanio_mazorca_cm               DECIMAL(6,2),
    diametro_mazorca_cm             DECIMAL(6,2),
    num_hileras                     SMALLINT CHECK (num_hileras >= 0),
    num_granos_por_hilera           SMALLINT CHECK (num_granos_por_hilera >= 0),
    peso_50_semillas_g              DECIMAL(6,2) CHECK (peso_50_semillas_g >= 0),
    color_grano                     VARCHAR(100),
    grosor_grano_mm                 DECIMAL(6,2),   -- promedio 50 granos
    ancho_grano_mm                  DECIMAL(6,2),   -- AGR
    longitud_grano_mm               DECIMAL(6,2),   -- LGR
    indice_lgr_agr                  DECIMAL(6,4) GENERATED ALWAYS AS (
                                        CASE WHEN ancho_grano_mm > 0
                                        THEN longitud_grano_mm / ancho_grano_mm
                                        ELSE NULL END
                                    ) STORED,
    volumen_50_semillas_ml          DECIMAL(6,2),

    -- === VARIABLES DE PLANTA (11 variables) ===
    altura_planta_cm                DECIMAL(7,2) CHECK (altura_planta_cm >= 0),   -- APL
    altura_mazorca_cm               DECIMAL(7,2) CHECK (altura_mazorca_cm >= 0),   -- AMZ
    indice_apl_amz                  DECIMAL(6,4) GENERATED ALWAYS AS (
                                        CASE WHEN altura_mazorca_cm > 0
                                        THEN altura_planta_cm / altura_mazorca_cm
                                        ELSE NULL END
                                    ) STORED,
    num_hojas                       SMALLINT CHECK (num_hojas >= 0),
    hojas_arriba_mazorca            SMALLINT CHECK (hojas_arriba_mazorca >= 0),
    dias_floracion_masculina        SMALLINT CHECK (dias_floracion_masculina >= 0),
    dias_floracion_femenina         SMALLINT CHECK (dias_floracion_femenina >= 0),
    asincronia_floral               SMALLINT GENERATED ALWAYS AS (
                                        ABS(COALESCE(dias_floracion_masculina,0) -
                                            COALESCE(dias_floracion_femenina,0))
                                    ) STORED,
    longitud_espiga_cm              DECIMAL(6,2),
    longitud_rama_central_cm        DECIMAL(6,2),
    num_ramificaciones_primarias    SMALLINT CHECK (num_ramificaciones_primarias >= 0),

    -- === VARIABLES SANITARIAS ===
    presencia_plaga                 BOOLEAN CHECK (presencia_plaga = FALSE OR tipo_plaga IS NOT NULL),
    tipo_plaga                      VARCHAR(200),
    severidad_plaga                 VARCHAR(20) CHECK (severidad_plaga IN ('baja','media','alta','muy_alta')),
    presencia_enfermedad            BOOLEAN CHECK (presencia_enfermedad = FALSE OR tipo_enfermedad IS NOT NULL),
    tipo_enfermedad                 VARCHAR(200),
    severidad_enfermedad            VARCHAR(20) CHECK (severidad_enfermedad IN ('baja','media','alta','muy_alta')),
    obs_sanitarias_detalle          TEXT,
    notas_evaluacion                TEXT,
    -- === AGRONÓMICAS ADICIONALES ===
    rendimiento_estimado_kg         DECIMAL(10,2) CHECK (rendimiento_estimado_kg >= 0),
    notas_campo                     TEXT,
    created_at                      TIMESTAMP DEFAULT NOW(),
    updated_at                      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. EVIDENCIA MULTIMEDIA
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

-- ============================================================
-- ANÁLISIS NUTRIMENTAL (Etapa 2 - 30 muestras mínimo)
-- ============================================================

-- ============================================================
-- 3. MUESTRA NUTRIMENTAL
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

-- ============================================================
-- 4. RESULTADO NUTRIMENTAL
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

