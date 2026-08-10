-- ============================================================
-- AGROPLATAFORMA DIGITAL - MAIZ NATIVO HUASTECA POTOSINA
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Script maestro de inicializacion
-- Version: 1.0 
-- ============================================================
SET client_encoding = 'UTF8';

COMMENT ON DATABASE postgres IS 
'Agroplataforma digital para la conservación del maíz nativo en la Huasteca Potosina - Proyecto PEE-2025-G-369';

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =========================
-- ESQUEMAS
-- =========================
CREATE SCHEMA IF NOT EXISTS sistema;     -- para tablas de usuarios, roles, autenticación
CREATE SCHEMA IF NOT EXISTS catalogo;    -- para tablas de catálogo (estado, municipio, comunidad, localidad, colonia, lengua)
CREATE SCHEMA IF NOT EXISTS trazabilidad; -- para tablas de archivos multimedia, evidencias, evaluaciones, mediciones, etc. que requieren trazabilidad detallada (quién, cuándo, fuente, uuid_envio, etc.)
CREATE SCHEMA IF NOT EXISTS core;       -- para tablas centrales que cruzan dominios, como investigador, ciclo, práctica, estación
--CREATE SCHEMA IF NOT EXISTS geo;  -- para tablas de ubicacion, parcela, capas SIG, imagenes, dron
--CREATE SCHEMA IF NOT EXISTS social;      -- para tablas de productor, consentimiento, seguridad alimentaria
--CREATE SCHEMA IF NOT EXISTS cultural;    -- para tablas de saberes, rituales, narrativas, gastronomia, identidad
--CREATE SCHEMA IF NOT EXISTS agro; -- para tablas de germoplasma, cultivo, semillas, economia
--CREATE SCHEMA IF NOT EXISTS fenotipico;  -- para tablas de evaluaciones, evidencias, nutrimental    
--CREATE SCHEMA IF NOT EXISTS amb;   -- para tablas de mediciones, indices NDVI, amenazas
--CREATE SCHEMA IF NOT EXISTS indices;     -- para índices compuestos para análisis (ej. indice de diversidad de cultivos)


-- =========================
-- ORDEN DE EJECUCIÓN
-- =========================

-- Orden de ejecucion:
-- 1. sistema     → roles y usuarios iniciales
-- 2. catalogo     → estado, municipio, comunidad, localidad, colonia, lengua
-- 3. core         → investigador, ciclo, práctica, estación
-- 4. social       → productor, consentimiento, seguridad alimentaria
-- 5. geografico   → ubicacion, parcela, capas SIG, imagenes, dron
-- 6. agronomico   → germoplasma, cultivo, semillas, economia
-- 7. cultural     → saberes, rituales, narrativas, gastronomia, identidad
-- 8. fenotipico   → evaluaciones, evidencias, nutrimental
-- 9. ambiental    → mediciones, indices NDVI, amenazas
-- 10. indices      → índices compuestos para análisis (ej. indice de diversidad de cultivos)
-- 11. triggers 
-- 12. vistas       → vistas integradas que cruzan todos los esquemas
-- 13. datos_base   → datos iniciales (ciclos, practicas, estaciones)
-- 14. localidades → localidades y colonias desde API INEGI
-- =========================================
-- TRANSACCIÓN PRINCIPAL
-- =========================================

\i /docker-entrypoint-initdb.d/01_sistema.sql
\i /docker-entrypoint-initdb.d/02_catalogo.sql
\i /docker-entrypoint-initdb.d/03_trazabilidad.sql
\i /docker-entrypoint-initdb.d/04_core.sql
--\i /docker-entrypoint-initdb.d/05_geografico.sql
--\i /docker-entrypoint-initdb.d/06_social.sql
--\i /docker-entrypoint-initdb.d/07_cultural.sql
--\i /docker-entrypoint-initdb.d/08_agronomico.sql
--\i /docker-entrypoint-initdb.d/09_fenotipico.sql
--\i /docker-entrypoint-initdb.d/10_ambiental.sql
--\i /docker-entrypoint-initdb.d/11_indices.sql
--\i /docker-entrypoint-initdb.d/12_triggers.sql
--\i /docker-entrypoint-initdb.d/13_vistas.sql
--\i /docker-entrypoint-initdb.d/14_datos_base.sql
--\i /docker-entrypoint-initdb.d/15_localidades_colonias.sql