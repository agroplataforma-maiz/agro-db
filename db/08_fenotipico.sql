-- ============================================================
-- ESQUEMA: fenotipico
-- Evaluaciones fenotípicas (22 variables Anexo I),
-- evidencia multimedia, análisis nutrimental (Etapa 2)
-- ============================================================

SET search_path TO fenotipico, public;

-- Evaluación fenotípica completa (22 variables Anexo I)
CREATE TABLE fenotipico.evaluacion_fenotipica (
    id                              SERIAL PRIMARY KEY,
    cultivo_id                      INTEGER REFERENCES agronomico.cultivo(id),   -- FK a agronomico.cultivo
    comunidad_id                    INTEGER REFERENCES catalogo.comunidad(id),
    fecha_evaluacion                DATE NOT NULL,
    evaluador                       VARCHAR(150),

    -- === VARIABLES DE MAZORCA (11 variables) ===
    tamaño_mazorca_cm               DECIMAL(6,2),
    diametro_mazorca_cm             DECIMAL(6,2),
    num_hileras                     SMALLINT,
    num_granos_por_hilera           SMALLINT,
    peso_50_semillas_g              DECIMAL(6,2),
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
    altura_planta_cm                DECIMAL(7,2),   -- APL
    altura_mazorca_cm               DECIMAL(7,2),   -- AMZ
    indice_apl_amz                  DECIMAL(6,4) GENERATED ALWAYS AS (
                                        CASE WHEN altura_mazorca_cm > 0
                                        THEN altura_planta_cm / altura_mazorca_cm
                                        ELSE NULL END
                                    ) STORED,
    num_hojas                       SMALLINT,
    hojas_arriba_mazorca            SMALLINT,
    dias_floracion_masculina        SMALLINT,
    dias_floracion_femenina         SMALLINT,
    asincronia_floral               SMALLINT GENERATED ALWAYS AS (
                                        ABS(COALESCE(dias_floracion_masculina,0) -
                                            COALESCE(dias_floracion_femenina,0))
                                    ) STORED,
    longitud_espiga_cm              DECIMAL(6,2),
    longitud_rama_central_cm        DECIMAL(6,2),
    num_ramificaciones_primarias    SMALLINT,

    -- === VARIABLES SANITARIAS ===
    presencia_plaga                 BOOLEAN DEFAULT FALSE,
    tipo_plaga                      VARCHAR(200),
    severidad_plaga                 VARCHAR(20) CHECK (severidad_plaga IN ('baja','media','alta','muy_alta')),
    presencia_enfermedad            BOOLEAN DEFAULT FALSE,
    tipo_enfermedad                 VARCHAR(200),
    severidad_enfermedad            VARCHAR(20) CHECK (severidad_enfermedad IN ('baja','media','alta','muy_alta')),

    -- === AGRONÓMICAS ADICIONALES ===
    rendimiento_estimado_kg         DECIMAL(10,2),
    notas_campo                     TEXT,
    created_at                      TIMESTAMP DEFAULT NOW()
);

-- Evidencia multimedia
CREATE TABLE fenotipico.evidencia (
    id              SERIAL PRIMARY KEY,
    evaluacion_id   INTEGER REFERENCES fenotipico.evaluacion_fenotipica(id),
    tipo            VARCHAR(50) CHECK (tipo IN (
                        'planta','mazorca','parcela','productor',
                        'plaga','enfermedad','contexto','dron','satelital')),
    ruta_archivo    VARCHAR(500) NOT NULL,
    fecha_captura   TIMESTAMP,
    modelo_captura  VARCHAR(100),
    resolucion      VARCHAR(50),
    notas           TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- ANÁLISIS NUTRIMENTAL (Etapa 2 - 30 muestras mínimo)
-- ============================================================

-- Muestra de maíz para análisis
CREATE TABLE fenotipico.muestra_nutrimental (
    id                  SERIAL PRIMARY KEY,
    codigo_muestra      VARCHAR(30) UNIQUE NOT NULL,   -- ej. MN-2026-001
    germoplasma_id      INTEGER REFERENCES agronomico.germoplasma(id),   -- FK a agronomico.germoplasma
    parcela_id          INTEGER REFERENCES geografico.parcela(id),   -- FK a geografico.parcela
    comunidad_id        INTEGER REFERENCES catalogo.comunidad(id),
    fecha_colecta       DATE,
    peso_muestra_g      DECIMAL(8,2),
    condicion_muestra   VARCHAR(50) CHECK (condicion_muestra IN (
                            'fresca','seca','procesada','harina')),
    laboratorio         VARCHAR(200),
    fecha_analisis      DATE,
    notas               TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- Resultados del análisis nutrimental
CREATE TABLE fenotipico.resultado_nutrimental (
    id                          SERIAL PRIMARY KEY,
    muestra_id                  INTEGER REFERENCES fenotipico.muestra_nutrimental(id),

    -- Macronutrientes (g/100g base seca)
    humedad_pct                 DECIMAL(6,3),
    proteina_pct                DECIMAL(6,3),
    grasa_pct                   DECIMAL(6,3),
    carbohidratos_pct           DECIMAL(6,3),
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
    created_at                  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- INDICES FENOTIPICOS
-- ============================================================

CREATE INDEX idx_eval_cultivo
ON fenotipico.evaluacion_fenotipica(cultivo_id);

CREATE INDEX idx_evidencia_evaluacion
ON fenotipico.evidencia(evaluacion_id);

CREATE INDEX idx_muestra_germoplasma
ON fenotipico.muestra_nutrimental(germoplasma_id);

CREATE INDEX idx_resultado_muestra
ON fenotipico.resultado_nutrimental(muestra_id);

-- Vista integrada: fenotipo del maíz por territorio
CREATE VIEW fenotipico.v_fenotipo_territorial AS
SELECT
    ef.id                     AS evaluacion_id,
    ef.fecha_evaluacion,

    g.id                      AS germoplasma_id,
    g.nombre_local            AS variedad_local,
    g.raza,
    g.color_grano,

    com.nombre                AS comunidad,
    mun.nombre                AS municipio,

    ef.altura_planta_cm,
    ef.altura_mazorca_cm,
    ef.indice_apl_amz,

    ef.tamaño_mazorca_cm,
    ef.diametro_mazorca_cm,
    ef.num_hileras,
    ef.num_granos_por_hilera,

    ef.longitud_grano_mm,
    ef.ancho_grano_mm,
    ef.indice_lgr_agr,

    ef.dias_floracion_masculina,
    ef.dias_floracion_femenina,
    ef.asincronia_floral,

    ef.presencia_plaga,
    ef.presencia_enfermedad,

    ef.rendimiento_estimado_kg

FROM fenotipico.evaluacion_fenotipica ef
JOIN agronomico.cultivo cu         ON cu.id = ef.cultivo_id
JOIN agronomico.germoplasma g      ON g.id = cu.germoplasma_id
LEFT JOIN catalogo.comunidad com   ON com.id = ef.comunidad_id
LEFT JOIN catalogo.municipio mun   ON mun.id = com.municipio_id;

-- Vista integrada: nutrición del maíz nativo por territorio
CREATE VIEW fenotipico.v_nutricion_maiz AS
SELECT
    mn.codigo_muestra,
    mn.fecha_colecta,

    g.id                   AS germoplasma_id,
    g.nombre_local         AS variedad_local,
    g.raza,
    g.color_grano,

    com.nombre             AS comunidad,
    mun.nombre             AS municipio,

    rn.proteina_pct,
    rn.grasa_pct,
    rn.carbohidratos_pct,
    rn.fibra_dietetica_total_pct,
    rn.energia_kcal,

    rn.calcio_mg,
    rn.hierro_mg,
    rn.zinc_mg,
    rn.magnesio_mg,
    rn.potasio_mg,

    rn.antocianinas_mg,
    rn.carotenoides_mg,
    rn.polifenoles_mg,
    rn.capacidad_antioxidante,

    rn.lisina_pct,
    rn.triptofano_pct

FROM fenotipico.muestra_nutrimental mn
JOIN agronomico.germoplasma g      ON g.id = mn.germoplasma_id
LEFT JOIN fenotipico.resultado_nutrimental rn
       ON rn.muestra_id = mn.id
LEFT JOIN catalogo.comunidad com   ON com.id = mn.comunidad_id
LEFT JOIN catalogo.municipio mun   ON mun.id = com.municipio_id;