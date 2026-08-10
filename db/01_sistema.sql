-- 01_usuarios.sql
-- Esquema de usuarios y roles para la plataforma agro

-- ============================================================
-- 1. ROLES
-- Los roles definen los permisos y niveles de acceso de los usuarios en la plataforma.
-- ============================================================
CREATE TYPE sistema.rol AS ENUM (
    'administrador',
    'investigador',
    'tecnico_campo',
    'visualizador',
    'productor'
);

-- ============================================================
-- 2. USUARIOS
-- La tabla de usuarios almacena la información de las cuentas que pueden acceder a la plataforma.
-- ============================================================
CREATE TABLE IF NOT EXISTS sistema.usuario (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username         VARCHAR(50)  UNIQUE NOT NULL,
  email            VARCHAR(255) UNIQUE NOT NULL,
  hashed_password  VARCHAR(255) NOT NULL,
  nombre_completo  VARCHAR(200),
  rol              sistema.rol NOT NULL,
  activo           BOOLEAN DEFAULT TRUE,
  ultimo_acceso    TIMESTAMPTZ,
  creado_en        TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en   TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  CONSTRAINT chk_email 
  CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- ============================================================
-- 3. API KEYS
-- Para autenticación de servicios externos o integraciones API
-- ============================================================
CREATE TABLE IF NOT EXISTS sistema.api_key (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id      UUID REFERENCES sistema.usuario(id) 
                  ON DELETE CASCADE,
  nombre          VARCHAR(100),
  api_key         TEXT UNIQUE NOT NULL,
  activo          BOOLEAN DEFAULT TRUE,
  creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 4. BITÁCORA DE ACTIVIDADES
-- Para auditoría y seguimiento de acciones de los usuarios
-- ============================================================
CREATE TABLE IF NOT EXISTS sistema.bitacora (
  id              BIGSERIAL PRIMARY KEY,
  usuario_id      UUID REFERENCES sistema.usuario(id) 
                  ON DELETE SET NULL,
  accion          VARCHAR(50) NOT NULL,
  modulo          VARCHAR(50) NOT NULL,
  descripcion     TEXT,
  ip              VARCHAR(50),
  user_agent      TEXT,
  nivel           VARCHAR(10) DEFAULT 'INFO',
  fecha           TIMESTAMPTZ DEFAULT now(),

  CHECK (nivel IN ('INFO', 'WARNING', 'ERROR'))
);

-- ============================================================
-- 5. CONFIGURACIÓN GENERAL
-- Para parámetros globales de la plataforma
-- ============================================================
CREATE TABLE IF NOT EXISTS sistema.configuracion (
  clave           VARCHAR(100) PRIMARY KEY,
  valor           TEXT,
  descripcion     TEXT,
  creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 6. NOTIFICACIONES
-- Tabla para almacenar notificaciones dirigidas a los productores, que pueden ser generadas por el sistema o por administradores, y que pueden incluir información relevante sobre prácticas agrícolas, eventos climáticos, oportunidades de mercado, etc.
-- ============================================================
CREATE TABLE IF NOT EXISTS sistema.notificacion (
    id            SERIAL PRIMARY KEY,
    usuario_id    UUID REFERENCES sistema.usuario(id) 
                  ON DELETE CASCADE,
    titulo        VARCHAR(200) NOT NULL,
    mensaje       TEXT NOT NULL,
    tipo          VARCHAR(50) DEFAULT 'informacion',
    leida         BOOLEAN DEFAULT FALSE,
    fecha_envio   TIMESTAMP DEFAULT now(),
    created_at    TIMESTAMP DEFAULT now(),
    updated_at    TIMESTAMP DEFAULT now()
);

-- ============================================================
-- ÍNDICES
-- ============================================================
CREATE INDEX idx_usuario_rol ON sistema.usuario(rol);
CREATE INDEX idx_api_key_usuario_id ON sistema.api_key(usuario_id);
CREATE INDEX idx_bitacora_usuario_id ON sistema.bitacora(usuario_id);
CREATE INDEX idx_bitacora_fecha ON sistema.bitacora(fecha DESC);
CREATE INDEX idx_bitacora_usuario_fecha ON sistema.bitacora(usuario_id, fecha DESC);

-- Trigger para actualizar el campo actualizado_en en sistema.usuario
CREATE OR REPLACE FUNCTION sistema.fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW IS DISTINCT FROM OLD THEN
    NEW.actualizado_en = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuario_update
BEFORE UPDATE ON sistema.usuario
FOR EACH ROW EXECUTE FUNCTION sistema.fn_update_timestamp();


INSERT INTO sistema.configuracion (clave, valor, descripcion) VALUES
('plataforma.nombre', 'Agroplataforma Maíz Nativo', 'Nombre de la plataforma'),
('plataforma.version', '1.0', 'Versión actual del sistema'),
('soporte.email', 'soporte@agromaiz.mx', 'Correo de contacto para soporte'),
('seguridad.intentos_maximos', '5', 'Intentos máximos de login fallido antes de bloqueo'),
('ui.tema', 'claro', 'Tema visual por defecto (claro/oscuro)'),
('api.timeout', '30', 'Tiempo de espera para respuestas API en segundos'),
('notificaciones.habilitadas', 'true', 'Habilitar o deshabilitar notificaciones por email') ON CONFLICT (clave) DO NOTHING;

-- Parámetros de seguridad adicionales
INSERT INTO sistema.configuracion (clave, valor, descripcion) VALUES
('seguridad.longitud_minima_password', '8', 'Longitud mínima de contraseña'),
('seguridad.expiracion_password_dias', '180', 'Días para expiración de contraseña'),
('seguridad.bloqueo_inactividad_dias', '90', 'Bloqueo de usuario tras días de inactividad'),
('seguridad.nivel_auditoria', 'completo', 'Nivel de auditoría de acciones (básico/completo)'),
('seguridad.retencion_logs_dias', '365', 'Días de retención de logs de auditoría') ON CONFLICT (clave) DO NOTHING;

-- Parámetros de integración
INSERT INTO sistema.configuracion (clave, valor, descripcion) VALUES
('integracion.api_url', 'https://api.agromaiz.mx', 'URL base de la API externa'),
('integracion.notificaciones_url', 'https://notificaciones.agromaiz.mx', 'Endpoint de notificaciones'),
('integracion.api_key_prueba', 'demo-key-123', 'API Key de prueba para desarrollo') ON CONFLICT (clave) DO NOTHING;

-- Mensajes del sistema
INSERT INTO sistema.configuracion (clave, valor, descripcion) VALUES
('mensaje.bienvenida', 'Bienvenido a AgroPlataforma Maíz', 'Mensaje de bienvenida para usuarios'),
('mensaje.aviso_legal', 'El uso de la plataforma implica la aceptación de los términos y condiciones.', 'Aviso legal mostrado al ingresar'),
('mensaje.politica_privacidad', 'Tus datos serán tratados conforme a la política de privacidad disponible en el sitio.', 'Política de privacidad') ON CONFLICT (clave) DO NOTHING;

-- Usuario administrador inicial
INSERT INTO sistema.usuario (username, email, hashed_password, nombre_completo, rol)
VALUES ('admin', 'admin@tecvalles.mx', '$2b$12$WsKYjTfm4SPmvT42X7TtMO/gJw45KgocIqPjPoyKWX4vhoDie8PQu', 'Administrador', 'administrador'),
('invitado','invitado@tecvalles.mx', '$2b$12$J4Ky5UhIaScZp.RFrb9iaeEooFWAlHtxjOlHlw/DnRNSHmxTJRgDa','invitado', 'visualizador'),
('investigador1', 'investigador1@testing.com', '$2b$12$l7BvrSwwG/SVJ5kOJAavHu/tQcQVZ/c3ApfZAnynSusSn9Ba.a.Ei', 'Investigador 1 Demo', 'investigador'),
('tecnico1', 'tecnico1@testing.com', '$2b$12$QU16Fmovi/EOJnv2IZKoS.BFrZ1cdBHFO4iJ5WdAojt2r2IwHd2dm', 'Técnico 1 Demo', 'tecnico_campo'),
('consultor1', 'consultor1@testing.com', '$2b$12$VvU6CF7n/6ZMEkAyzbHp9u2dG9va9FCUlZVk2H/qAgcY7Hu6HoqXG', 'Visualizador Demo 1', 'visualizador'),
('productor1', 'productor1@testing.com', '$2b$12$CAFYQcezB0sh0D0CDDWgEuos/UusJjCE/N91Q1iO.H26Df7EmYTFi', 'Productor 1 Demo', 'productor');



