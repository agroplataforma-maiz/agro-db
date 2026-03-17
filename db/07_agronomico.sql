-- ============================================================
-- ESQUEMA: agronomico
-- Germoplasma, cultivos, ciclos, sistema de semillas,
-- usos del maíz, economía del cultivo
-- ============================================================

SET search_path TO agronomico, public;

-- Ciclo agrícola
CREATE TABLE agronomico.ciclo_agricola (
    id           SERIAL PRIMARY KEY,
    año          SMALLINT NOT NULL,
    temporada    VARCHAR(30) CHECK (temporada IN ('Primavera-Verano','Otoño-Invierno')),
    fecha_inicio DATE,
    fecha_fin    DATE,
    CONSTRAINT uq_ciclo_agricola UNIQUE (año, temporada),
    created_at   TIMESTAMP DEFAULT NOW()
);

-- Germoplasma (núcleo del sistema)
CREATE TABLE agronomico.germoplasma (
    id                  SERIAL PRIMARY KEY,
    codigo_accesion     VARCHAR(30) UNIQUE NOT NULL,  -- ej. HP-2025-001
    nombre_local        VARCHAR(200) NOT NULL,
    nombre_lengua_orig  VARCHAR(200),
    raza                VARCHAR(100),
    color_grano         VARCHAR(100),
    ciclo_vegetativo    VARCHAR(50) CHECK (ciclo_vegetativo IN ('precoz','intermedio','tardio')),
    duracion_dias       SMALLINT,
    estado_conservacion VARCHAR(50) CHECK (estado_conservacion IN (
                            'activo','en_riesgo','semilla_guardada','extinto_local')),
    origen_muestra      VARCHAR(50) CHECK (origen_muestra IN (
                            'campo','hornilla','almacen','mercado','intercambio')),
    comunidad_id INTEGER REFERENCES catalogo.comunidad(id),    -- FK a catalogo.comunidad
    fecha_registro      DATE DEFAULT CURRENT_DATE,
    created_at          TIMESTAMP DEFAULT NOW()
);

ALTER TABLE cultural.nombre_lengua_originaria
ADD CONSTRAINT fk_nombre_germoplasma
FOREIGN KEY (germoplasma_id)
REFERENCES agronomico.germoplasma(id);

-- Cultivo (instancia espacio-temporal central)
CREATE TABLE agronomico.cultivo (
    id                  SERIAL PRIMARY KEY,
    fecha_siembra       DATE,
    fecha_cosecha       DATE,
    sistema_manejo      VARCHAR(50) CHECK (sistema_manejo IN (
                            'tradicional','mixto','convencional','agroecologico')),
    rendimiento_kg_ha   DECIMAL(10,2),
    observaciones       TEXT,
    germoplasma_id      INTEGER REFERENCES agronomico.germoplasma(id),
    parcela_id          INTEGER REFERENCES geografico.parcela(id),   -- FK a geografico.parcela
    ciclo_agricola_id   INTEGER REFERENCES agronomico.ciclo_agricola(id),
    created_at          TIMESTAMP DEFAULT NOW()
);

-- Sistema de semillas
CREATE TABLE agronomico.sistema_semilla (
    id                          SERIAL PRIMARY KEY,
    productor_id                INTEGER REFERENCES social.productor(id),   -- FK a social.productor
    germoplasma_id              INTEGER REFERENCES agronomico.germoplasma(id),
    -- Origen
    origen                      VARCHAR(50) CHECK (origen IN (
                                    'herencia_familiar','intercambio_vecino',
                                    'intercambio_compadre','regalo','compra',
                                    'banco_comunitario','organizacion','otro')),
    origen_detalle              VARCHAR(200),
    años_conservando_semilla    SMALLINT,
    años_antes_renovar          SMALLINT,
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
    metodo_almacenamiento       VARCHAR(50) CHECK (metodo_almacenamiento IN (
                                    'costal_yute','bote_metalico','troje',
                                    'silo_hermetico','tinaco','olla_barro',
                                    'hornilla','otro')),
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
    created_at                  TIMESTAMP DEFAULT NOW()
);

-- Usos y destino del maíz cosechado
CREATE TABLE agronomico.uso_maiz (
    id                      SERIAL PRIMARY KEY,
    cultivo_id              INTEGER REFERENCES agronomico.cultivo(id),
    -- Distribución porcentual
    pct_autoconsumo         SMALLINT CHECK (pct_autoconsumo BETWEEN 0 AND 100),
    pct_venta               SMALLINT CHECK (pct_venta BETWEEN 0 AND 100),
    pct_semilla             SMALLINT CHECK (pct_semilla BETWEEN 0 AND 100),
    pct_forraje             SMALLINT CHECK (pct_forraje BETWEEN 0 AND 100),
    pct_otro                SMALLINT CHECK (pct_otro BETWEEN 0 AND 100),
    uso_otro_descripcion    VARCHAR(200),
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
    sistema_cultivo         VARCHAR(50) CHECK (sistema_cultivo IN (
                                'monocultivo','milpa','asociacion_frijol',
                                'policultivo','otro')),
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
    produccion_total_kg     DECIMAL(10,2),
    rendimiento_kg_ha       DECIMAL(10,2),
    fecha_registro          DATE DEFAULT CURRENT_DATE,
    created_at              TIMESTAMP DEFAULT NOW()
);

-- Economía del cultivo (costos e ingresos por ciclo)
CREATE TABLE agronomico.economia_cultivo (
    id                          SERIAL PRIMARY KEY,
    cultivo_id                  INTEGER REFERENCES agronomico.cultivo(id),
    -- Costos (pesos MXN)
    costo_semilla               DECIMAL(10,2),
    costo_fertilizantes         DECIMAL(10,2),
    costo_plaguicidas           DECIMAL(10,2),
    costo_mano_obra             DECIMAL(10,2),
    costo_transporte            DECIMAL(10,2),
    costo_riego                 DECIMAL(10,2),
    costo_otros                 DECIMAL(10,2),
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
    ciclo_agricola_id           INTEGER REFERENCES agronomico.ciclo_agricola(id),
    fecha_registro              DATE DEFAULT CURRENT_DATE,
    created_at                  TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- INDICES AGRONOMICOS
-- ============================================================

CREATE INDEX idx_cultivo_germoplasma ON agronomico.cultivo(germoplasma_id);

CREATE INDEX idx_cultivo_ciclo ON agronomico.cultivo(ciclo_agricola_id);

CREATE INDEX idx_sistema_semilla_productor ON agronomico.sistema_semilla(productor_id);

CREATE INDEX idx_sistema_semilla_germoplasma ON agronomico.sistema_semilla(germoplasma_id);

CREATE INDEX idx_uso_maiz_cultivo ON agronomico.uso_maiz(cultivo_id);

CREATE INDEX idx_economia_cultivo ON agronomico.economia_cultivo(cultivo_id);

-- ============================================================
-- VISTAS AGRONOMICAS
-- ============================================================

-- Vista integrada: germoplasma y cultivos registrados
CREATE VIEW agronomico.v_germoplasma_cultivo AS
SELECT
    g.id AS germoplasma_id,
    g.codigo_accesion,
    g.nombre_local,
    g.raza,
    g.color_grano,
    g.ciclo_vegetativo,
    g.estado_conservacion,
    com.nombre AS comunidad,
    mun.nombre AS municipio,
    c.id AS cultivo_id,
    c.fecha_siembra,
    c.fecha_cosecha,
    c.sistema_manejo,
    c.rendimiento_kg_ha
FROM agronomico.germoplasma g
LEFT JOIN catalogo.comunidad com ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun ON mun.id = com.municipio_id
LEFT JOIN agronomico.cultivo c ON c.germoplasma_id = g.id;

-- Vista: sistema de semillas y productores
CREATE VIEW agronomico.v_sistema_semilla AS
SELECT
    ss.id,
    p.id AS productor_id,
    p.nombres AS productor,
    g.codigo_accesion,
    g.nombre_local,
    ss.origen,
    ss.años_conservando_semilla,
    ss.metodo_almacenamiento,
    ss.aplica_tratamiento,
    ss.tiene_semilla_resguardo,
    ss.cantidad_resguardo_kg,
    ss.ventaja_alto_rendimiento,
    ss.ventaja_resistencia_sequia,
    ss.ventaja_resistencia_plagas
FROM agronomico.sistema_semilla ss
LEFT JOIN social.productor p ON p.id = ss.productor_id
LEFT JOIN agronomico.germoplasma g ON g.id = ss.germoplasma_id;

-- Vista: destino de la producción de maíz
CREATE VIEW agronomico.v_destino_produccion AS
SELECT
    u.id,
    u.cultivo_id,
    u.pct_autoconsumo,
    u.pct_venta,
    u.pct_semilla,
    u.pct_forraje,
    u.produccion_total_kg,
    u.rendimiento_kg_ha,
    u.precio_kg,
    u.sistema_cultivo,
    u.canal_mercado_tianguis,
    u.canal_tienda_local,
    u.canal_venta_directa
FROM agronomico.uso_maiz u;

-- Vista: análisis económico del cultivo
CREATE VIEW agronomico.v_economia_cultivo AS
SELECT
    e.id,
    e.cultivo_id,
    e.costo_total,
    e.ingreso_venta_maiz,
    e.ingreso_otros,
    (COALESCE(e.ingreso_venta_maiz,0) + COALESCE(e.ingreso_otros,0) - COALESCE(e.costo_total,0)) AS utilidad_neta,
    e.problema_clima,
    e.problema_sequia,
    e.problema_plagas,
    e.problema_precio
FROM agronomico.economia_cultivo e;

-- Vista integrada para análisis territorial del cultivo
CREATE VIEW agronomico.v_cultivo_integrado AS
SELECT
    c.id AS cultivo_id,
    g.codigo_accesion,
    g.nombre_local,
    g.raza,
    com.nombre AS comunidad,
    mun.nombre AS municipio,
    c.fecha_siembra,
    c.fecha_cosecha,
    c.sistema_manejo,
    c.rendimiento_kg_ha,
    u.produccion_total_kg,
    e.costo_total,
    e.ingreso_venta_maiz
FROM agronomico.cultivo c
LEFT JOIN agronomico.germoplasma g ON g.id = c.germoplasma_id
LEFT JOIN catalogo.comunidad com ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun ON mun.id = com.municipio_id
LEFT JOIN agronomico.uso_maiz u ON u.cultivo_id = c.id
LEFT JOIN agronomico.economia_cultivo e ON e.cultivo_id = c.id;
