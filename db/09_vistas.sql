-- ============================================================
-- VISTAS INTEGRADAS
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Version: 3.0 - Actualizada para catalogo.*
-- ============================================================

-- ============================================================
-- VISTA MAESTRA: germoplasma con todos los ejes
-- ============================================================
CREATE VIEW public.v_germoplasma_completo AS
SELECT
    g.codigo_accesion,
    g.nombre_local,
    g.nombre_lengua_orig,
    g.raza,
    g.color_grano,
    g.ciclo_vegetativo,
    g.estado_conservacion,
    g.origen_muestra,
    -- Eje social
    p.nombres || ' ' || COALESCE(p.apellido_paterno,'') AS productor,
    p.tipo_manejo,
    p.años_experiencia,
    -- Eje territorial (desde catalogo.*)
    mun.nombre          AS municipio,
    loc.nombre          AS localidad,
    -- Eje geográfico
    u.latitud,
    u.longitud,
    u.altitud_m,
    u.zona_agroecologica,
    u.tipo_suelo,
    -- Eje ambiental (ultimo NDVI)
    iv.ndvi             AS ndvi_reciente,
    iv.fecha_calculo    AS fecha_ndvi,
    iv.estado_vegetacion,
    -- Seguridad alimentaria
    sa.nivel_inseguridad,
    sa.elcsa_puntaje_total,
    -- Vulnerabilidad
    vc.se_siente_vulnerable,
    vc.afecta_sequia,
    vc.afecta_heladas
FROM agronomico.germoplasma g
LEFT JOIN agronomico.cultivo c              ON c.germoplasma_id = g.id
LEFT JOIN geografico.parcela par            ON par.id = c.parcela_id
LEFT JOIN social.productor p               ON p.id = par.productor_id
LEFT JOIN catalogo.municipio mun           ON mun.id = p.municipio_id
LEFT JOIN catalogo.localidad loc           ON loc.id = p.localidad_id
LEFT JOIN geografico.ubicacion u           ON u.id = par.ubicacion_id
LEFT JOIN LATERAL (
    SELECT ndvi, fecha_calculo, estado_vegetacion
    FROM ambiental.indice_vegetacion iv2
    WHERE iv2.parcela_id = par.id
    ORDER BY fecha_calculo DESC LIMIT 1
) iv ON TRUE
LEFT JOIN social.seguridad_alimentaria sa  ON sa.productor_id = p.id
LEFT JOIN social.vulnerabilidad_climatica vc ON vc.productor_id = p.id;

-- ============================================================
-- VISTA: resumen por municipio
-- ============================================================
CREATE VIEW public.v_resumen_municipio AS
SELECT
    mun.nombre                              AS municipio,
    COUNT(DISTINCT p.id)                    AS total_productores,
    COUNT(DISTINCT g.id)                    AS total_germoplasmas,
    COUNT(DISTINCT par.id)                  AS total_parcelas,
    COUNT(DISTINCT ef.id)                   AS total_evaluaciones,
    ROUND(AVG(sa.elcsa_puntaje_total),2)    AS elcsa_promedio,
    SUM(CASE WHEN vc.se_siente_vulnerable THEN 1 ELSE 0 END) AS productores_vulnerables,
    ROUND(AVG(iv.ndvi),4)                   AS ndvi_promedio
FROM catalogo.municipio mun
LEFT JOIN social.productor p               ON p.municipio_id = mun.id
LEFT JOIN geografico.parcela par           ON par.productor_id = p.id
LEFT JOIN agronomico.cultivo c             ON c.parcela_id = par.id
LEFT JOIN agronomico.germoplasma g         ON g.id = c.germoplasma_id
LEFT JOIN fenotipico.evaluacion_fenotipica ef ON ef.cultivo_id = c.id
LEFT JOIN social.seguridad_alimentaria sa  ON sa.productor_id = p.id
LEFT JOIN social.vulnerabilidad_climatica vc ON vc.productor_id = p.id
LEFT JOIN ambiental.indice_vegetacion iv   ON iv.parcela_id = par.id
GROUP BY mun.id, mun.nombre
ORDER BY total_germoplasmas DESC;

-- ============================================================
-- VISTA: amenazas activas
-- ============================================================
CREATE VIEW public.v_amenazas_activas AS
SELECT
    a.tipo,
    a.nivel_riesgo,
    a.descripcion,
    mun.nombre AS municipio,
    a.fecha_deteccion,
    a.area_afectada_ha,
    a.fuente_deteccion,
    COUNT(DISTINCT par.id)  AS parcelas_en_riesgo,
    COUNT(DISTINCT p.id)    AS productores_afectados,
    COUNT(DISTINCT g.id)    AS germoplasmas_en_riesgo
FROM ambiental.amenaza a
LEFT JOIN catalogo.municipio mun   ON mun.id = a.municipio_id
LEFT JOIN geografico.parcela par   ON ST_Within(par.poligono, a.poligono)
LEFT JOIN social.productor p       ON p.id = par.productor_id
LEFT JOIN agronomico.cultivo c     ON c.parcela_id = par.id
LEFT JOIN agronomico.germoplasma g ON g.id = c.germoplasma_id
WHERE a.esta_activa = TRUE
GROUP BY a.id, a.tipo, a.nivel_riesgo, a.descripcion,
         mun.nombre, a.fecha_deteccion, a.area_afectada_ha, a.fuente_deteccion
ORDER BY
    CASE a.nivel_riesgo
        WHEN 'critico' THEN 1
        WHEN 'alto'    THEN 2
        WHEN 'medio'   THEN 3
        ELSE 4
    END;

-- ============================================================
-- VISTA: seguimiento fenologico por parcela (serie NDVI)
-- ============================================================
CREATE VIEW public.v_fenologia_parcela AS
SELECT
    par.id              AS parcela_id,
    par.nombre          AS parcela,
    mun.nombre          AS municipio,
    g.codigo_accesion,
    g.nombre_local,
    sn.fecha,
    sn.ndvi_promedio,
    sn.ndvi_max,
    sn.ndvi_min,
    LAG(sn.ndvi_promedio) OVER (PARTITION BY par.id ORDER BY sn.fecha) AS ndvi_anterior,
    sn.ndvi_promedio -
        LAG(sn.ndvi_promedio) OVER (PARTITION BY par.id ORDER BY sn.fecha) AS cambio_ndvi
FROM ambiental.serie_ndvi sn
JOIN geografico.parcela par             ON par.id = sn.parcela_id
LEFT JOIN social.productor p           ON p.id = par.productor_id
LEFT JOIN catalogo.municipio mun       ON mun.id = p.municipio_id
LEFT JOIN agronomico.cultivo c         ON c.parcela_id = par.id
LEFT JOIN agronomico.germoplasma g     ON g.id = c.germoplasma_id
ORDER BY par.id, sn.fecha;

-- ============================================================
-- VISTA: perfil nutrimental por germoplasma
-- ============================================================
CREATE VIEW public.v_nutrimental AS
SELECT
    g.codigo_accesion,
    g.nombre_local,
    g.raza,
    g.color_grano,
    mun.nombre          AS municipio,
    mn.codigo_muestra,
    mn.fecha_analisis,
    rn.proteina_pct,
    rn.grasa_pct,
    rn.carbohidratos_pct,
    rn.fibra_dietetica_total_pct,
    rn.energia_kcal,
    rn.hierro_mg,
    rn.zinc_mg,
    rn.calcio_mg,
    rn.antocianinas_mg,
    rn.carotenoides_mg,
    rn.capacidad_antioxidante
FROM fenotipico.muestra_nutrimental mn
JOIN fenotipico.resultado_nutrimental rn ON rn.muestra_id = mn.id
JOIN agronomico.germoplasma g            ON g.id = mn.germoplasma_id
LEFT JOIN geografico.parcela par         ON par.id = mn.parcela_id
LEFT JOIN social.productor p            ON p.id = par.productor_id
LEFT JOIN catalogo.municipio mun        ON mun.id = p.municipio_id
ORDER BY rn.proteina_pct DESC;

-- ============================================================
-- VISTA: agroecosistema integral del maíz nativo
-- Integra clima, NDVI, suelo, productor y germoplasma
-- ============================================================
CREATE VIEW public.v_agroecosistema_maiz AS
SELECT
    g.id                        AS germoplasma_id,
    g.codigo_accesion,
    g.nombre_local,
    g.raza,
    g.color_grano,
    g.ciclo_vegetativo,

    -- Productor
    p.id                        AS productor_id,
    p.nombres || ' ' || COALESCE(p.apellido_paterno,'') AS productor,
    p.tipo_manejo,
    p.años_experiencia,

    -- Ubicación territorial
    mun.nombre                  AS municipio,
    loc.nombre                  AS localidad,
    par.id                      AS parcela_id,
    par.nombre                  AS parcela,
    u.latitud,
    u.longitud,
    u.altitud_m,
    u.zona_agroecologica,

    -- Suelo
    ce.tipo_suelo,
    ce.textura,
    ce.ph,
    ce.materia_organica_pct,
    ce.nitrogeno_ppm,
    ce.fosforo_ppm,
    ce.potasio_ppm,

    -- NDVI reciente
    iv.ndvi                     AS ndvi_reciente,
    iv.estado_vegetacion,
    iv.fecha_calculo            AS fecha_ndvi,

    -- Evaluación fenotípica
    ef.fecha_evaluacion,
    ef.altura_planta_cm,
    ef.dias_floracion_masculina,
    ef.dias_floracion_femenina,
    ef.asincronia_floral,
    --ef.dias_madurez,
    ef.rendimiento_estimado_kg,

    -- Seguridad alimentaria
    sa.elcsa_puntaje_total,
    sa.nivel_inseguridad,

    -- Vulnerabilidad climática
    vc.se_siente_vulnerable,
    vc.afecta_sequia,
    vc.afecta_heladas

FROM agronomico.germoplasma g
LEFT JOIN agronomico.cultivo c              ON c.germoplasma_id = g.id
LEFT JOIN geografico.parcela par            ON par.id = c.parcela_id
LEFT JOIN social.productor p                ON p.id = par.productor_id
LEFT JOIN catalogo.municipio mun            ON mun.id = p.municipio_id
LEFT JOIN catalogo.localidad loc            ON loc.id = p.localidad_id
LEFT JOIN geografico.ubicacion u            ON u.id = par.ubicacion_id

-- Suelo
LEFT JOIN ambiental.condicion_edafica ce    ON ce.parcela_id = par.id

-- NDVI más reciente
LEFT JOIN LATERAL (
    SELECT ndvi, estado_vegetacion, fecha_calculo
    FROM ambiental.indice_vegetacion iv2
    WHERE iv2.parcela_id = par.id
    ORDER BY fecha_calculo DESC
    LIMIT 1
) iv ON TRUE

-- Fenotipo más reciente
LEFT JOIN LATERAL (
    SELECT *
    FROM fenotipico.evaluacion_fenotipica ef2
    WHERE ef2.cultivo_id = c.id
    ORDER BY fecha_evaluacion DESC
    LIMIT 1
) ef ON TRUE

LEFT JOIN social.seguridad_alimentaria sa   ON sa.productor_id = p.id
LEFT JOIN social.vulnerabilidad_climatica vc ON vc.productor_id = p.id;

-- ============================================================
-- VISTA: diversidad de maíz nativo por municipio
-- ============================================================
CREATE VIEW public.v_diversidad_maiz_municipio AS
SELECT
    mun.nombre                                   AS municipio,
    COUNT(DISTINCT g.id)                         AS total_germoplasmas,
    COUNT(DISTINCT g.raza)                       AS total_razas,
    COUNT(DISTINCT g.color_grano)                AS diversidad_colores,
    COUNT(DISTINCT par.id)                       AS total_parcelas,
    COUNT(DISTINCT p.id)                         AS total_productores,
    ROUND(AVG(iv.ndvi),4)                        AS ndvi_promedio
FROM catalogo.municipio mun
LEFT JOIN social.productor p           ON p.municipio_id = mun.id
LEFT JOIN geografico.parcela par       ON par.productor_id = p.id
LEFT JOIN agronomico.cultivo c         ON c.parcela_id = par.id
LEFT JOIN agronomico.germoplasma g     ON g.id = c.germoplasma_id
LEFT JOIN ambiental.indice_vegetacion iv ON iv.parcela_id = par.id
GROUP BY mun.id, mun.nombre
ORDER BY total_germoplasmas DESC;


-- ============================================================
-- VISTA: índice simple de resiliencia agroecosistémica
-- ============================================================
CREATE VIEW public.v_indice_resiliencia_agroecosistema AS
SELECT
    par.id                        AS parcela_id,
    par.nombre                    AS parcela,
    mun.nombre                    AS municipio,
    g.codigo_accesion,
    g.raza,
    iv.ndvi                       AS ndvi_reciente,
    ce.materia_organica_pct,
    sa.nivel_inseguridad,
    vc.se_siente_vulnerable,

    (
        COALESCE(iv.ndvi,0) * 0.4 +
        COALESCE(ce.materia_organica_pct,0)/10 * 0.3 +
        CASE WHEN vc.se_siente_vulnerable THEN 0 ELSE 0.2 END +
        CASE WHEN sa.nivel_inseguridad = 'severa' THEN 0
             WHEN sa.nivel_inseguridad = 'moderada' THEN 0.05
             ELSE 0.1
        END
    ) AS indice_resiliencia

FROM agronomico.cultivo c
JOIN agronomico.germoplasma g          ON g.id = c.germoplasma_id
JOIN geografico.parcela par            ON par.id = c.parcela_id
LEFT JOIN social.productor p           ON p.id = par.productor_id
LEFT JOIN catalogo.municipio mun       ON mun.id = p.municipio_id

LEFT JOIN LATERAL (
    SELECT ndvi
    FROM ambiental.indice_vegetacion iv2
    WHERE iv2.parcela_id = par.id
    ORDER BY fecha_calculo DESC
    LIMIT 1
) iv ON TRUE

LEFT JOIN ambiental.condicion_edafica ce  ON ce.parcela_id = par.id
LEFT JOIN social.seguridad_alimentaria sa ON sa.productor_id = p.id
LEFT JOIN social.vulnerabilidad_climatica vc ON vc.productor_id = p.id;


-- ============================================================
-- VISTA: hotspots de conservación de maíz nativo
-- ============================================================
CREATE VIEW public.v_hotspots_maiz_nativo AS
SELECT
    mun.nombre                          AS municipio,
    COUNT(DISTINCT g.id)                AS germoplasmas,
    COUNT(DISTINCT g.raza)              AS razas,
    COUNT(DISTINCT p.id)                AS productores,
    COUNT(DISTINCT par.id)              AS parcelas,

    CASE
        WHEN COUNT(DISTINCT g.raza) >= 10 THEN 'muy_alto'
        WHEN COUNT(DISTINCT g.raza) >= 6 THEN 'alto'
        WHEN COUNT(DISTINCT g.raza) >= 3 THEN 'medio'
        ELSE 'bajo'
    END AS nivel_prioridad_conservacion

FROM agronomico.germoplasma g
JOIN agronomico.cultivo c         ON c.germoplasma_id = g.id
JOIN geografico.parcela par       ON par.id = c.parcela_id
JOIN social.productor p           ON p.id = par.productor_id
JOIN catalogo.municipio mun       ON mun.id = p.municipio_id
GROUP BY mun.id, mun.nombre
ORDER BY razas DESC;