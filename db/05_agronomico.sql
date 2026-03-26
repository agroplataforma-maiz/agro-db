-- ============================================================
-- ESQUEMA: agronomico
-- Datos agronómicos de maíz nativo en la Huasteca Potosina
-- Incluye información sobre germoplasma, cultivos, ciclos agrícolas, sistema de semillas, usos del maíz cosechado y economía del cultivo
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Versión: 1.0 | Etapa 1
--
-- EJECUTAR DESPUÉS de 04_social.sql
-- EJECUTAR ANTES de 06_cultural.sql
--
-- Tablas:
--    1. ciclo_agricola
--    2. germoplasma
--    3. cultivo
--    4. sistema_semilla
--    5. uso_maiz
--    6. economia_cultivo  
-- ============================================================

SET search_path TO agronomico, public;

-- ============================================================
-- 1. CICLO AGRÍCOLA
-- El ciclo agrícola es una entidad temporal que agrupa cultivos por año y temporada.
-- Se puede usar para análisis de tendencias a lo largo del tiempo o para comparar temporadas.  
-- ============================================================
CREATE TABLE IF NOT EXISTS agronomico.ciclo_agricola (
    id           SERIAL PRIMARY KEY,
    anio          SMALLINT NOT NULL CHECK (anio BETWEEN 1900 AND 2100),
    temporada    VARCHAR(30) NOT NULL CHECK (temporada IN ('Primavera-Verano','Otoño-Invierno')),
    fecha_inicio DATE,
    fecha_fin    DATE CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT uq_ciclo_agricola UNIQUE (anio, temporada),
    created_at   TIMESTAMP DEFAULT NOW(),
    updated_at   TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 2. GERMOPLASMA (núcleo del sistema)
-- El germoplasma es el núcleo del sistema, representa la diversidad genética de maíz nativo que se cultiva en la región.
-- ============================================================
CREATE TABLE IF NOT EXISTS agronomico.germoplasma (
    id                  SERIAL PRIMARY KEY,
    codigo_accesion     VARCHAR(30) UNIQUE NOT NULL,  -- ej. HP-2025-001
    nombre_local        VARCHAR(200) NOT NULL,
    nombre_lengua_orig  VARCHAR(200),
    raza_id             INTEGER REFERENCES catalogo.raza_maiz(id) ON DELETE SET NULL ON UPDATE CASCADE,
    color_grano_id      INTEGER REFERENCES catalogo.color_grano(id) ON DELETE SET NULL ON UPDATE CASCADE,
    ciclo_vegetativo    VARCHAR(50) CHECK (ciclo_vegetativo IN ('precoz','intermedio','tardio')),
    duracion_dias       SMALLINT CHECK (duracion_dias > 0),
    estado_conservacion_id INTEGER REFERENCES catalogo.estado_conservacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    origen_muestra_id      INTEGER REFERENCES catalogo.origen_muestra(id) ON DELETE SET NULL ON UPDATE CASCADE,
    comunidad_id INTEGER  NOT NULL REFERENCES catalogo.comunidad(id) ON DELETE RESTRICT ON UPDATE CASCADE,    -- FK a catalogo.comunidad
    fecha_registro      DATE DEFAULT CURRENT_DATE,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 3. CULTIVO 
-- El cultivo es la instancia espacio-temporal de la siembra de un germoplasma específico en una parcela determinada. Es la entidad central para el análisis agronómico, ya que a partir de ella se pueden relacionar las prácticas de manejo, los rendimientos, los usos del maíz cosechado y la economía del cultivo.
-- ============================================================ 
CREATE TABLE IF NOT EXISTS agronomico.cultivo (
    id                  SERIAL PRIMARY KEY,
    fecha_siembra       DATE NOT NULL,
    fecha_cosecha       DATE CHECK (fecha_cosecha IS NULL OR fecha_cosecha >= fecha_siembra),
    sistema_manejo_id      INTEGER NOT NULL REFERENCES catalogo.sistema_manejo(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    rendimiento_kg_ha   DECIMAL(10,2) CHECK (rendimiento_kg_ha >= 0),
    observaciones       TEXT,
    germoplasma_id      INTEGER NOT NULL REFERENCES agronomico.germoplasma(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    parcela_id          INTEGER NOT NULL REFERENCES geografico.parcela(id) ON DELETE RESTRICT ON UPDATE CASCADE,   -- FK a geografico.parcela
    ciclo_agricola_id   INTEGER REFERENCES agronomico.ciclo_agricola(id) ON DELETE SET NULL ON UPDATE CASCADE,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 4. SISTEMA DE SEMILLA
-- El sistema de semilla documenta las prácticas de conservación, selección, almacenamiento y tratamiento de la semilla que los productores utilizan para mantener su germoplasma a lo largo del tiempo. Es fundamental para entender la dinámica de la diversidad genética y las estrategias de manejo que los productores emplean para conservar sus variedades de maíz nativo. 
-- ============================================================
CREATE TABLE IF NOT EXISTS agronomico.sistema_semilla (
    id                          SERIAL PRIMARY KEY,
    productor_id                INTEGER NOT NULL REFERENCES social.productor(id) ON DELETE RESTRICT ON UPDATE CASCADE,   -- FK a social.productor
    germoplasma_id              INTEGER NOT NULL REFERENCES agronomico.germoplasma(id) ON DELETE RESTRICT ON UPDATE CASCADE,
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

-- ============================================================
-- 5. USOS DEL MAÍZ COSECHADO
-- Esta tabla documenta los diferentes usos que los productores le dan al maíz cosechado, incluyendo la distribución porcentual entre autoconsumo, venta, semilla, forraje u otros destinos, así como la motivación detrás de cada uso, los alimentos elaborados a partir del maíz cosechado, el sistema de cultivo utilizado y los canales de comercialización. Esta información es clave para entender la importancia socioeconómica del maíz nativo en la región y para diseñar estrategias de apoyo a los productores que promuevan la conservación y el uso sostenible de su germoplasma.
-- ============================================================
CREATE TABLE IF NOT EXISTS agronomico.uso_maiz (
    id                      SERIAL PRIMARY KEY,
    cultivo_id              INTEGER NOT NULL REFERENCES agronomico.cultivo(id) ON DELETE CASCADE ON UPDATE CASCADE,
    -- Distribución porcentual
    pct_autoconsumo         SMALLINT CHECK (pct_autoconsumo BETWEEN 0 AND 100),
    pct_venta               SMALLINT CHECK (pct_venta BETWEEN 0 AND 100),
    pct_semilla             SMALLINT CHECK (pct_semilla BETWEEN 0 AND 100),
    pct_forraje             SMALLINT CHECK (pct_forraje BETWEEN 0 AND 100),
    pct_otro                SMALLINT CHECK (pct_otro BETWEEN 0 AND 100),
    uso_otro_descripcion    VARCHAR(200),
    CONSTRAINT chk_uso_maiz_pct_sum CHECK ((COALESCE(pct_autoconsumo,0) + COALESCE(pct_venta,0) + COALESCE(pct_semilla,0) + COALESCE(pct_forraje,0) + COALESCE(pct_otro,0)) <= 100),
    -- Motivación para sembrar
    motivo_autoconsumo      BOOLEAN DEFAULT FALSE,
    motivo_venta            BOOLEAN DEFAULT FALSE,
    motivo_tradicion        BOOLEAN DEFAULT FALSE,
    motivo_forraje          BOOLEAN DEFAULT FALSE,
    motivo_semilla          BOOLEAN DEFAULT FALSE,
    motivo_otro             VARCHAR(150),
    -- Alimentos elaborados
    elabora_tortilla        BOOLEAN DEFAULT FALSE,
    elabora_tamales         BOOLEAN DEFAULT FALSE,
    elabora_atole           BOOLEAN DEFAULT FALSE,
    elabora_pozole          BOOLEAN DEFAULT FALSE,
    elabora_otros           VARCHAR(200),
    -- Sistema de cultivo
    sistema_cultivo_id      INTEGER REFERENCES catalogo.sistema_cultivo(id) ON DELETE SET NULL ON UPDATE CASCADE,
    -- Comercialización
    canal_tienda_local      BOOLEAN DEFAULT FALSE,
    canal_mercado_tianguis  BOOLEAN DEFAULT FALSE,
    canal_tortilleria       BOOLEAN DEFAULT FALSE,
    canal_central_abastos   BOOLEAN DEFAULT FALSE,
    canal_venta_directa     BOOLEAN DEFAULT FALSE,
    canal_intermediario     BOOLEAN DEFAULT FALSE,
    canal_otro              VARCHAR(100),
    precio_kg               DECIMAL(8,2),
    epoca_venta             VARCHAR(100),
    produccion_total_kg     DECIMAL(10,2) CHECK (produccion_total_kg >= 0),
    fecha_registro          DATE DEFAULT CURRENT_DATE,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- 6. ECONOMÍA DEL CULTIVO
-- Esta tabla documenta los costos e ingresos asociados a cada cultivo, así como las prácticas de manejo implementadas y los problemas de producción enfrentados. Esta información es crucial para realizar análisis económicos que permitan entender la rentabilidad de los cultivos de maíz nativo y para identificar las principales limitaciones y oportunidades que enfrentan los productores en la región. 
-- ============================================================
CREATE TABLE IF NOT EXISTS agronomico.economia_cultivo (
    id                          SERIAL PRIMARY KEY,
    cultivo_id                  INTEGER NOT NULL REFERENCES agronomico.cultivo(id) ON DELETE CASCADE ON UPDATE CASCADE,
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
    ciclo_agricola_id           INTEGER REFERENCES agronomico.ciclo_agricola(id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha_registro              DATE DEFAULT CURRENT_DATE,
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);