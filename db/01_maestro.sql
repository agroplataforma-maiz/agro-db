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
CREATE SCHEMA IF NOT EXISTS catalogo;    -- base territorial, va primero
CREATE SCHEMA IF NOT EXISTS geografico;
CREATE SCHEMA IF NOT EXISTS social;
CREATE SCHEMA IF NOT EXISTS agronomico;
CREATE SCHEMA IF NOT EXISTS cultural;
CREATE SCHEMA IF NOT EXISTS fenotipico;
CREATE SCHEMA IF NOT EXISTS ambiental;
CREATE SCHEMA IF NOT EXISTS auditoria;

-- =========================
-- ORDEN DE EJECUCIÓN
-- =========================

-- Orden de ejecucion:
-- 1. catalogo     → estado, municipio, comunidad, localidad, colonia, lengua
-- 2. social       → productor, consentimiento, seguridad alimentaria
-- 3. geografico   → ubicacion, parcela, capas SIG, imagenes, dron
-- 4. agronomico   → germoplasma, cultivo, semillas, economia
-- 5. cultural     → saberes, rituales, narrativas, gastronomia, identidad
-- 6. fenotipico   → evaluaciones, evidencias, nutrimental
-- 7. ambiental    → mediciones, indices NDVI, amenazas
-- 8. indices      → índices compuestos para análisis (ej. indice de diversidad de cultivos)
-- 9. triggers 
-- 10. vistas       → vistas integradas que cruzan todos los esquemas
-- 11. datos_base   → datos iniciales (ciclos, practicas, estaciones)
-- 12. localidades → localidades y colonias desde API INEGI

-- =========================================
-- TRANSACCIÓN PRINCIPAL
-- =========================================


\i /docker-entrypoint-initdb.d/02_catalogo.sql
\i /docker-entrypoint-initdb.d/03_social.sql
\i /docker-entrypoint-initdb.d/04_geografico.sql
\i /docker-entrypoint-initdb.d/05_agronomico.sql
\i /docker-entrypoint-initdb.d/06_cultural.sql
\i /docker-entrypoint-initdb.d/07_fenotipico.sql
\i /docker-entrypoint-initdb.d/08_ambiental.sql
\i /docker-entrypoint-initdb.d/09_indices.sql
\i /docker-entrypoint-initdb.d/10_triggers.sql
\i /docker-entrypoint-initdb.d/11_vistas.sql
\i /docker-entrypoint-initdb.d/12_datos_base.sql
\i /docker-entrypoint-initdb.d/13_localidades_colonias.sql
