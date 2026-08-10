-- ============================================================
-- 1. CORE: UBICACIÓN
--    Latitud, longitud, altitud y metadatos geoespaciales
--    Ubicación geoespacial con PostGIS
-- ============================================================

CREATE TABLE IF NOT EXISTS core.ubicacion (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre              VARCHAR(100),
    tipo_ubicacion      VARCHAR(50),
    descripcion         TEXT,
    latitud             DECIMAL(10,7) NOT NULL,
    longitud            DECIMAL(10,7) NOT NULL,
    altitud_m           DECIMAL(8,2),
    altitud_fuente      VARCHAR(50),
    precision_gps       DECIMAL(6,2),
    municipio_id        INTEGER REFERENCES catalogo.municipio(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    sistema_referencia  VARCHAR(20) DEFAULT 'WGS84',
    fuente_captura_id   INTEGER REFERENCES trazabilidad.fuente(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    tags                TEXT[],
    activo              BOOLEAN DEFAULT TRUE,
    geom                GEOMETRY(Point, 4326) NOT NULL,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now(),
    CHECK (latitud BETWEEN -90 AND 90),
    CHECK (longitud BETWEEN -180 AND 180)
);

CREATE INDEX IF NOT EXISTS idx_ubicacion_geom ON core.ubicacion USING GIST (geom);

-- ============================================================
-- 2. CORE: COMUNIDAD
--    Agrupación sociocultural o administrativa de localidades
--    Ej: ejidos, rancherías, zonas indígenas
-- ============================================================

CREATE TABLE IF NOT EXISTS core.comunidad (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre              VARCHAR(200) NOT NULL,
    nombre_lengua_orig  VARCHAR(200), -- nombre en lengua originaria
    tipo                VARCHAR(50),
    municipio_id        INTEGER NOT NULL REFERENCES catalogo.municipio(id) 
                        ON DELETE RESTRICT 
                        ON UPDATE CASCADE,
    ubicacion_id        UUID REFERENCES core.ubicacion(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    -- Criterios muestreo intencional (Patton, 2014)
    presencia_maiz_nativo       BOOLEAN DEFAULT false,
    presencia_historica_maiz    BOOLEAN DEFAULT false,
    diversidad_ecologica_score  SMALLINT,
    riqueza_cultural_score      SMALLINT,
    prioridad_muestreo          VARCHAR(20) DEFAULT 'media',
    -- Estadísticas básicas
    poblacion_total     INTEGER,
    num_localidades     SMALLINT,
    -- Fuente del dato
    fuente              VARCHAR(100) DEFAULT 'INEGI 2020',
    activo              BOOLEAN DEFAULT TRUE,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now(),

    UNIQUE (nombre, municipio_id),
    CHECK (tipo IN (
              'indigena',
              'campesina',
              'ejidal',
              'mestiza',
              'mixta',
              'urbana',
              'rancheria',
              'otro'
          )),
    CHECK (diversidad_ecologica_score BETWEEN 1 AND 5),
    CHECK (riqueza_cultural_score BETWEEN 1 AND 5),
    CHECK (prioridad_muestreo IN ('alta','media','baja'))
);

CREATE INDEX IF NOT EXISTS idx_comunidad_municipio ON core.comunidad(municipio_id);

CREATE INDEX IF NOT EXISTS idx_comunidad_nombre
ON core.comunidad USING gin(to_tsvector('spanish', nombre));

-- ============================================================
-- 2. CORE: PRODUCTOR / CUSTODIO
-- Referencia catalogo.municipio, catalogo.localidad
-- y core.comunidad en lugar de catalogo.comunidad
-- ============================================================

CREATE TABLE IF NOT EXISTS core.productor (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Identificador único del productor
    nombres             VARCHAR(150) NOT NULL, -- Nombres del productor
    apellido_paterno    VARCHAR(100), -- Apellido paterno
    apellido_materno    VARCHAR(100), -- Apellido materno
    fecha_nacimiento    DATE DEFAULT NULL, -- Fecha de nacimiento
    genero              VARCHAR(30), -- Género del productor
    estado_civil        VARCHAR(30), -- Estado civil
    anios_experiencia   SMALLINT, -- Años de experiencia en la actividad
    telefono            VARCHAR(20), -- Teléfono de contacto
    correo_electronico  VARCHAR(150) DEFAULT NULL, -- Correo electrónico (opcional)
    tipo_productor_id   INTEGER REFERENCES catalogo.tipo_productor(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE, -- FK tipo de productor
    comunidad_id        UUID REFERENCES core.comunidad(id)  
                        ON DELETE SET NULL
                        ON UPDATE CASCADE, -- FK a core.comunidad
    municipio_id        INTEGER REFERENCES catalogo.municipio(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE, -- FK municipio
    localidad_id        INTEGER REFERENCES catalogo.localidad(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE, -- FK localidad
    ubicacion_id        UUID REFERENCES core.ubicacion(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE, -- FK ubicación geoespacial
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now(),

    CHECK (genero IN (
              'masculino','femenino','no_binario','prefiere_no_decir'
          )),
    CHECK (estado_civil IN (
              'soltero','casado','union_libre','divorciado','viudo','otro'
          ))
);

-- ============================================================
-- 3. CORE: GERMOPLASMA (núcleo del sistema)
-- El germoplasma es el núcleo del sistema, representa la diversidad genética de maíz nativo que se cultiva en la región.
-- ============================================================
CREATE TABLE IF NOT EXISTS core.germoplasma (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    codigo_accesion     VARCHAR(30) UNIQUE NOT NULL,  -- ej. HP-2025-001
    nombre_local        VARCHAR(200) NOT NULL,
    nombre_lengua_orig  VARCHAR(200),
    raza_id             INTEGER REFERENCES catalogo.raza_maiz(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    color_grano_id      INTEGER REFERENCES catalogo.color_grano(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    ciclo_vegetativo    VARCHAR(50),
    duracion_dias       SMALLINT,
    estado_conservacion_id INTEGER REFERENCES catalogo.estado_conservacion(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    origen_muestra_id   INTEGER REFERENCES 
                        trazabilidad.origen_material_agricola(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    comunidad_id        UUID  NOT NULL REFERENCES core.comunidad(id) 
                        ON DELETE RESTRICT 
                        ON UPDATE CASCADE,    -- FK a core.comunidad
    ubicacion_id        UUID REFERENCES core.ubicacion(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE, -- FK ubicación geoespacial
    colector_id         UUID REFERENCES sistema.usuario(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE, -- técnico de campo que colecta
    notas               TEXT,
    fecha_registro      DATE DEFAULT CURRENT_DATE,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now(),

    CHECK (ciclo_vegetativo IN ('precoz','intermedio','tardio')),
    CHECK (duracion_dias > 0)
);

CREATE INDEX IF NOT EXISTS idx_germoplasma_nombre ON core.germoplasma USING gin(to_tsvector('spanish', nombre_local));
CREATE INDEX IF NOT EXISTS idx_germoplasma_comunidad ON core.germoplasma(comunidad_id);
CREATE INDEX IF NOT EXISTS idx_germoplasma_raza ON core.germoplasma(raza_id);
CREATE INDEX IF NOT EXISTS idx_germoplasma_color ON core.germoplasma(color_grano_id);

-- ============================================================
-- 4. CORE: PARCELA
--    Información geoespacial de las parcelas agrícolas
--    Polígono de la parcela, sistema de manejo, tenencia, topografía
-- ============================================================
CREATE TABLE IF NOT EXISTS core.parcela (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre              VARCHAR(150),
    superficie_ha       DECIMAL(8,4),
    sistema_manejo_id   INTEGER REFERENCES catalogo.sistema_manejo(id) 
                        ON DELETE SET NULL 
                        ON UPDATE CASCADE,
    tenencia            VARCHAR(50),
    topografia          VARCHAR(30),
    productor_id        UUID NOT NULL REFERENCES core.productor(id) 
                        ON DELETE RESTRICT 
                        ON UPDATE CASCADE,
    ubicacion_id        UUID REFERENCES core.ubicacion(id) ON DELETE SET NULL ON UPDATE CASCADE,
    poligono            GEOMETRY(Polygon, 4326) NOT NULL,
    densidad_plantas_ha INTEGER,
    observaciones_sitio TEXT,
    creado_en           TIMESTAMPTZ DEFAULT now(),
    actualizado_en      TIMESTAMPTZ DEFAULT now(),

    CHECK (superficie_ha > 0),
    CHECK (tenencia IN ('ejidal','privada','comunal','rentada','prestada','desconocida')),
    CHECK (topografia IN ('plana','ondulada','ladera','terraza','barranco')),
    CHECK (densidad_plantas_ha > 0)
);

CREATE INDEX IF NOT EXISTS idx_parcela_poligono ON core.parcela USING GIST (poligono);
CREATE INDEX IF NOT EXISTS idx_parcela_productor ON core.parcela(productor_id);
CREATE INDEX IF NOT EXISTS idx_parcela_ubicacion ON core.parcela(ubicacion_id);

-- ============================================================
-- 5. CORE: PRODUCTOR-GERMOPLASMA
-- Tabla intermedia para relacionar productores con los germoplasmas que cultivan o custodian 
-- ============================================================
CREATE TABLE core.productor_germoplasma (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    productor_id        UUID NOT NULL REFERENCES core.productor(id)
                        ON DELETE CASCADE,
    germoplasma_id      UUID NOT NULL REFERENCES core.germoplasma(id)
                        ON DELETE CASCADE,
    anio_siembra        SMALLINT,
    superficie_ha       DECIMAL(8,4),
    activo              BOOLEAN DEFAULT TRUE,

    UNIQUE (productor_id, germoplasma_id)
);


--- ============================================================
-- 6. CORE: SIEMBRA
-- Información detallada de cada ciclo de cultivo en una parcela específica, incluyendo el germoplasma sembrado, fechas de siembra y cosecha, rendimiento, etc.
-- ============================================================
CREATE TABLE core.siembra (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parcela_id          UUID NOT NULL REFERENCES core.parcela(id)
                        ON DELETE CASCADE,
    germoplasma_id      UUID NOT NULL REFERENCES core.germoplasma(id)
                        ON DELETE CASCADE,
    fecha_siembra       DATE,
    fecha_cosecha       DATE,
    densidad            REAL,
    rendimiento_kg_ha   REAL,
    ciclo_agricola      VARCHAR(20), -- ej. PV, OI
    UNIQUE (parcela_id, germoplasma_id, fecha_siembra)
);