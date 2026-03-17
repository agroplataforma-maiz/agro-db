-- ============================================================
-- AGROPLATAFORMA DIGITAL - MAIZ NATIVO HUASTECA POTOSINA
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Script maestro de inicializacion
-- Version: 3.0 - Incluye esquema catalogo territorial
-- ============================================================
SET client_encoding = 'UTF8';

COMMENT ON DATABASE postgres IS 
'Agroplataforma digital para la conservación del maíz nativo en la Huasteca Potosina - Proyecto PEE-2025-G-369';

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Crear esquemas en orden de dependencias
CREATE SCHEMA IF NOT EXISTS catalogo;    -- base territorial, va primero
CREATE SCHEMA IF NOT EXISTS social;
CREATE SCHEMA IF NOT EXISTS cultural;
CREATE SCHEMA IF NOT EXISTS geografico;
CREATE SCHEMA IF NOT EXISTS ambiental;
CREATE SCHEMA IF NOT EXISTS agronomico;
CREATE SCHEMA IF NOT EXISTS fenotipico;

-- Orden de ejecucion:
-- 1. catalogo     → estado, municipio, comunidad, localidad, colonia, lengua
-- 2. social       → productor, consentimiento, seguridad alimentaria
-- 3. cultural     → saberes, rituales, narrativas, gastronomia, identidad
-- 4. geografico   → ubicacion, parcela, capas SIG, imagenes, dron
-- 5. ambiental    → mediciones, indices NDVI, amenazas
-- 6. agronomico   → germoplasma, cultivo, semillas, economia
-- 7. fenotipico   → evaluaciones, evidencias, nutrimental
-- 8. vistas       → vistas integradas que cruzan todos los esquemas
-- 9. datos_base   → datos iniciales (ciclos, practicas, estaciones)
-- 10. localidades → localidades y colonias desde API INEGI

\i /docker-entrypoint-initdb.d/02_catalogo.sql
\i /docker-entrypoint-initdb.d/03_social.sql
\i /docker-entrypoint-initdb.d/04_cultural.sql
\i /docker-entrypoint-initdb.d/05_geografico.sql
\i /docker-entrypoint-initdb.d/06_ambiental.sql
\i /docker-entrypoint-initdb.d/07_agronomico.sql
\i /docker-entrypoint-initdb.d/08_fenotipico.sql
\i /docker-entrypoint-initdb.d/09_vistas.sql
\i /docker-entrypoint-initdb.d/10_datos_base.sql
\i /docker-entrypoint-initdb.d/11_localidades_colonias.sql