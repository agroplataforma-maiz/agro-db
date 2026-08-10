-- ============================================================
-- VISTAS INTEGRADAS
-- PEE-2025-G-369 | TecNM Ciudad Valles
-- Vista: jerárquica completa municipio -> comunidad -> localidad
-- Descripción: Relaciona municipios, comunidades y localidades, mostrando jerarquía territorial y atributos clave de cada nivel.
-- ============================================================


-- ============================================================
-- VISTAS DEL CATÁLOGO
-- ============================================================

-- Vista jerárquica completa: municipio -> comunidad -> localidad
CREATE OR REPLACE VIEW catalogo.v_territorial AS
SELECT
    m.clave_completa        AS clave_municipio,
    m.nombre                AS municipio,
    m.region,
    m.created_at            AS municipio_created_at,
    m.updated_at            AS municipio_updated_at,
    c.nombre                AS comunidad,
    c.tipo                  AS tipo_comunidad,
    c.created_at            AS comunidad_created_at,
    c.updated_at            AS comunidad_updated_at,
    l.clave_inegi           AS clave_localidad,
    l.nombre                AS localidad,
    l.tipo                  AS tipo_localidad,
    l.categoria,
    l.poblacion_total,
    l.grado_marginacion,
    l.indigena,
    l.latitud,
    l.longitud,
    l.altitud_m,
    l.created_at            AS localidad_created_at,
    l.updated_at            AS localidad_updated_at
    -- Catálogos adicionales terminan aquí
FROM catalogo.municipio m
LEFT JOIN catalogo.comunidad c  ON c.municipio_id = m.id
LEFT JOIN catalogo.localidad l  ON l.comunidad_id = c.id
LEFT JOIN catalogo.comunidad comcat ON comcat.id = c.id
LEFT JOIN catalogo.localidad loccat ON loccat.id = l.id
ORDER BY m.nombre, c.nombre, l.nombre;

-- Vista resumen por municipio
CREATE VIEW catalogo.v_resumen_municipio AS
SELECT
    m.nombre                AS municipio,
    m.cabecera,
    m.region                AS region,
    COUNT(DISTINCT c.id)    AS total_comunidades,
    COUNT(DISTINCT l.id)    AS total_localidades,
    SUM(l.poblacion_total)  AS poblacion_total,
    SUM(CASE WHEN l.indigena THEN 1 ELSE 0 END) AS localidades_indigenas
FROM catalogo.municipio m
LEFT JOIN catalogo.comunidad c  ON c.municipio_id = m.id
LEFT JOIN catalogo.localidad l  ON l.municipio_id = m.id
LEFT JOIN catalogo.comunidad comcat ON comcat.id = c.id
GROUP BY m.id, m.nombre, m.cabecera
ORDER BY m.nombre;

-- ============================================================
-- VISTAS DE GEORREFERENCIACIÓN
-- ============================================================

-- Inventario de productos por vuelo
CREATE VIEW geografico.v_inventario_dron AS
SELECT
    vd.id               AS vuelo_id,
    vd.fecha_vuelo,
    vd.modelo_dron,
    vd.tipo_sensor,
    vd.area_cubierta_ha,
    vd.resolucion_cm_px,
    vd.num_imagenes,
    par.nombre          AS parcela,
    mun.nombre          AS municipio,
    COUNT(pd.id)        AS total_productos,
    STRING_AGG(CAST(pd.tipo_producto_dron_id AS TEXT), ', ' ORDER BY pd.tipo_producto_dron_id) AS productos_generados,
    SUM(pd.tamanio_mb)   AS tamanio_total_mb,
    SUM(CASE WHEN pd.validado THEN 1 ELSE 0 END) AS productos_validados
-- NOTA: No se puede determinar el tipo de producto por nombre, solo por ID. Si necesitas los nombres, haz un JOIN con catalogo.tipo_producto_dron.
-- Las siguientes columnas quedan comentadas porque no hay equivalentes directos:
-- BOOL_OR(pd.tipo_producto_dron_id = <id_ndvi>)                AS tiene_ndvi,
-- BOOL_OR(pd.tipo_producto_dron_id = <id_ndwi>)                AS tiene_ndwi,
-- BOOL_OR(pd.tipo_producto_dron_id = <id_gndvi>)               AS tiene_gndvi,
-- BOOL_OR(pd.tipo_producto_dron_id = <id_dem>)                 AS tiene_dem,
-- BOOL_OR(pd.tipo_producto_dron_id = <id_ortomosaico_rgb>)     AS tiene_ortomosaico_rgb,
-- BOOL_OR(pd.tipo_producto_dron_id = <id_ortomosaico_ms>)      AS tiene_ortomosaico_ms
FROM geografico.vuelo_dron vd
LEFT JOIN geografico.producto_dron pd   ON pd.vuelo_id = vd.id
LEFT JOIN geografico.parcela par        ON par.id = vd.parcela_id
LEFT JOIN social.productor p            ON p.id = par.productor_id
LEFT JOIN catalogo.comunidad com        ON com.id = p.localidad_id
LEFT JOIN catalogo.municipio mun        ON mun.id = com.municipio_id
LEFT JOIN catalogo.comunidad comcat     ON comcat.id = com.id
GROUP BY vd.id, vd.fecha_vuelo, vd.modelo_dron, vd.tipo_sensor,
         vd.area_cubierta_ha, vd.resolucion_cm_px, vd.num_imagenes,
         par.nombre, mun.nombre
ORDER BY vd.fecha_vuelo DESC;

-- ============================================================
-- VISTAS AGRONOMICAS
-- ============================================================

-- Vista integrada: germoplasma y cultivos registrados
CREATE VIEW agronomico.v_germoplasma_cultivo AS
SELECT
    g.id AS germoplasma_id,
    g.codigo_accesion,
    g.nombre_local,
    rm.nombre AS raza,
    rm.descripcion AS raza_descripcion,
    rm.region_origen,
    rm.tipo_ciclo,
    rm.es_nativa,
    cg.nombre AS color_grano,
    cg.descripcion AS color_grano_descripcion,
    cg.es_nativo,
    g.ciclo_vegetativo,
    g.estado_conservacion_id,
    ec.nombre AS estado_conservacion_nombre,
    ec.nivel_riesgo AS estado_conservacion_riesgo,
    com.nombre AS comunidad,
    mun.nombre AS municipio,
    c.id AS cultivo_id,
    c.fecha_siembra,
-- Vista: sistema de semillas y productores
-- Descripción: Relaciona productores, germoplasma y prácticas de conservación y almacenamiento de semilla.
    c.sistema_manejo_id,
    c.rendimiento_kg_ha
    , rm.region_origen AS raza_region_origen
    , rm.tipo_ciclo AS raza_tipo_ciclo
    , rm.es_nativa AS raza_es_nativa
    , cg.es_nativo AS color_grano_es_nativo
    , ec.nivel_riesgo AS estado_conservacion_nivel_riesgo
FROM agronomico.germoplasma g
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
LEFT JOIN catalogo.estado_conservacion ec ON ec.id = g.estado_conservacion_id
LEFT JOIN catalogo.comunidad com ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun ON mun.id = com.municipio_id
LEFT JOIN agronomico.cultivo c ON c.germoplasma_id = g.id;

-- Vista: sistema de semillas y productores
CREATE VIEW social.v_sistema_semilla AS
SELECT
    ss.id,
    p.id AS productor_id,
    p.nombres AS productor,
    g.codigo_accesion,
    g.nombre_local,
    ss.origen_semilla_id,
    ss.anios_conservando_semilla,
    ss.metodo_almacenamiento_id,
    ss.aplica_tratamiento,
    ss.tiene_semilla_resguardo,
    ss.cantidad_resguardo_kg,
    ss.ventaja_alto_rendimiento,
    ss.ventaja_resistencia_sequia,
    ss.ventaja_resistencia_plagas
FROM social.sistema_semilla ss
LEFT JOIN social.productor p ON p.id = ss.productor_id
LEFT JOIN agronomico.germoplasma g ON g.id = ss.germoplasma_id;

CREATE VIEW agronomico.v_destino_produccion AS
SELECT
    u.id,
    u.cultivo_id,
    u.pct_autoconsumo,
    u.pct_venta,
    u.pct_semilla,
    u.pct_forraje,
    u.produccion_total_kg,
    c.rendimiento_kg_ha,
    u.precio_kg,
    u.sistema_cultivo_id,
    u.canal_mercado_tianguis,
    u.canal_tienda_local,
    u.canal_venta_directa,
    rm.nombre AS raza,
    cg.nombre AS color_grano
FROM cultural.uso_maiz u
LEFT JOIN agronomico.cultivo c ON c.id = u.cultivo_id
LEFT JOIN agronomico.germoplasma g ON g.id = c.germoplasma_id
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id;

CREATE VIEW social.v_economia_cultivo AS
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
    e.problema_precio,
    rm.nombre AS raza,
    cg.nombre AS color_grano
FROM social.economia_cultivo e
LEFT JOIN agronomico.cultivo c ON c.id = e.cultivo_id
LEFT JOIN agronomico.germoplasma g ON g.id = c.germoplasma_id
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id;

CREATE VIEW agronomico.v_cultivo_integrado AS
SELECT
    c.id AS cultivo_id,
    g.codigo_accesion,
    g.nombre_local,
    rm.nombre AS raza,
    rm.region_origen AS raza_region_origen,
    rm.tipo_ciclo AS raza_tipo_ciclo,
    rm.es_nativa AS raza_es_nativa,
    cg.nombre AS color_grano,
    cg.es_nativo AS color_grano_es_nativo,
    ec.nombre AS estado_conservacion_nombre,
    ec.nivel_riesgo AS estado_conservacion_riesgo,
    com.nombre AS comunidad,
    mun.nombre AS municipio,
    c.fecha_siembra,
    c.fecha_cosecha,
    c.sistema_manejo_id,
    c.rendimiento_kg_ha,
    u.produccion_total_kg,
    e.costo_total,
    e.ingreso_venta_maiz
FROM agronomico.cultivo c
LEFT JOIN agronomico.germoplasma g ON g.id = c.germoplasma_id
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
LEFT JOIN catalogo.estado_conservacion ec ON ec.id = g.estado_conservacion_id
LEFT JOIN catalogo.comunidad com ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun ON mun.id = com.municipio_id
LEFT JOIN cultural.uso_maiz u ON u.cultivo_id = c.id
LEFT JOIN social.economia_cultivo e ON e.cultivo_id = c.id;

-- ============================================================
-- VISTA MAESTRA: germoplasma con todos los ejes
-- ============================================================
CREATE VIEW public.v_germoplasma_completo AS
SELECT
    g.codigo_accesion,
    g.nombre_local,
    g.nombre_lengua_orig,
    rm.nombre AS raza,
    rm.descripcion AS raza_descripcion,
    rm.region_origen,
    rm.tipo_ciclo,
    rm.es_nativa,
    cg.nombre AS color_grano,
    cg.descripcion AS color_grano_descripcion,
    cg.es_nativo,
    g.ciclo_vegetativo,
    g.estado_conservacion_id,
    ec.nombre AS estado_conservacion_nombre,
    ec.nivel_riesgo AS estado_conservacion_riesgo,
    g.origen_muestra_id,
    -- Eje social
    p.nombres || ' ' || COALESCE(p.apellido_paterno,'') AS productor,
    rm.region_origen AS raza_region_origen,
    rm.tipo_ciclo AS raza_tipo_ciclo,
    rm.es_nativa AS raza_es_nativa,
    cg.es_nativo AS color_grano_es_nativo,
    -- (eliminado duplicado)
    p.anios_experiencia,
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
    vc.afecta_heladas,
    ec.nivel_riesgo AS estado_conservacion_nivel_riesgo
FROM agronomico.germoplasma g
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
LEFT JOIN catalogo.estado_conservacion ec ON ec.id = g.estado_conservacion_id
LEFT JOIN agronomico.cultivo c              ON c.germoplasma_id = g.id
LEFT JOIN geografico.parcela par            ON par.id = c.parcela_id
LEFT JOIN social.productor p               ON p.id = par.productor_id
LEFT JOIN catalogo.comunidad com           ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun           ON mun.id = com.municipio_id
LEFT JOIN catalogo.localidad loc           ON loc.comunidad_id = com.id
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
LEFT JOIN catalogo.comunidad com           ON com.municipio_id = mun.id
    LEFT JOIN catalogo.localidad l             ON l.comunidad_id = com.id
    LEFT JOIN social.productor p               ON p.localidad_id = l.id
LEFT JOIN geografico.parcela par           ON par.productor_id = p.id
LEFT JOIN agronomico.cultivo c             ON c.parcela_id = par.id
LEFT JOIN agronomico.germoplasma g         ON g.id = c.germoplasma_id
LEFT JOIN fenotipico.evaluacion_fenotipica ef ON ef.cultivo_id = c.id
LEFT JOIN social.seguridad_alimentaria sa  ON sa.productor_id = p.id
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
LEFT JOIN social.vulnerabilidad_climatica vc ON vc.productor_id = p.id
LEFT JOIN ambiental.indice_vegetacion iv   ON iv.parcela_id = par.id
GROUP BY mun.id, mun.nombre
ORDER BY total_germoplasmas DESC;

-- ============================================================
-- VISTA: amenazas activas
-- ============================================================
CREATE VIEW public.v_amenazas_activas AS
SELECT
    ta.nombre AS tipo_amenaza,
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
LEFT JOIN catalogo.tipo_amenaza ta ON ta.id = a.tipo_amenaza_id
LEFT JOIN catalogo.municipio mun   ON mun.id = a.municipio_id
LEFT JOIN geografico.parcela par   ON ST_Within(par.poligono, a.poligono)
LEFT JOIN social.productor p       ON p.id = par.productor_id
LEFT JOIN agronomico.cultivo c     ON c.parcela_id = par.id
LEFT JOIN agronomico.germoplasma g ON g.id = c.germoplasma_id
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
WHERE a.esta_activa = TRUE
GROUP BY a.id, ta.nombre, a.nivel_riesgo, a.descripcion,
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
LEFT JOIN agronomico.cultivo c         ON c.parcela_id = par.id
LEFT JOIN agronomico.germoplasma g     ON g.id = c.germoplasma_id
LEFT JOIN catalogo.raza_maiz rm        ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg      ON cg.id = g.color_grano_id
LEFT JOIN catalogo.comunidad com       ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun       ON mun.id = com.municipio_id
ORDER BY par.id, sn.fecha;

-- ============================================================
-- VISTA: perfil nutrimental por germoplasma
-- ============================================================
CREATE VIEW public.v_nutrimental AS
SELECT
    g.codigo_accesion,
    g.nombre_local,
    rm.nombre AS raza,
    cg.nombre AS color_grano,
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
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
LEFT JOIN geografico.parcela par         ON par.id = mn.parcela_id
LEFT JOIN catalogo.estado_conservacion ec ON ec.id = g.estado_conservacion_id
LEFT JOIN social.productor p            ON p.id = par.productor_id
LEFT JOIN catalogo.comunidad com        ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun        ON mun.id = com.municipio_id
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
    rm.nombre AS raza,
    cg.nombre AS color_grano,
    g.ciclo_vegetativo,

    -- Productor
    p.id                        AS productor_id,
    p.nombres || ' ' || COALESCE(p.apellido_paterno,'') AS productor,
    p.anios_experiencia,

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
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
LEFT JOIN agronomico.cultivo c              ON c.germoplasma_id = g.id
LEFT JOIN geografico.parcela par            ON par.id = c.parcela_id
LEFT JOIN social.productor p                ON p.id = par.productor_id
LEFT JOIN catalogo.comunidad com           ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun            ON mun.id = com.municipio_id
LEFT JOIN catalogo.localidad loc            ON loc.comunidad_id = com.id
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
    COUNT(DISTINCT rm.nombre)                    AS total_razas,
    COUNT(DISTINCT cg.nombre)                    AS diversidad_colores,
    COUNT(DISTINCT par.id)                       AS total_parcelas,
    COUNT(DISTINCT p.id)                         AS total_productores,
    ROUND(AVG(iv.ndvi),4)                        AS ndvi_promedio
FROM catalogo.municipio mun
LEFT JOIN catalogo.comunidad com       ON com.municipio_id = mun.id
LEFT JOIN catalogo.localidad l        ON l.comunidad_id = com.id
LEFT JOIN social.productor p          ON p.localidad_id = l.id
LEFT JOIN geografico.parcela par      ON par.productor_id = p.id
LEFT JOIN agronomico.cultivo c        ON c.parcela_id = par.id
LEFT JOIN agronomico.germoplasma g    ON g.id = c.germoplasma_id
LEFT JOIN catalogo.raza_maiz rm       ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg     ON cg.id = g.color_grano_id
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
    rm.nombre AS raza,
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
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
JOIN geografico.parcela par            ON par.id = c.parcela_id
LEFT JOIN social.productor p           ON p.id = par.productor_id
LEFT JOIN catalogo.comunidad com       ON com.id = g.comunidad_id
LEFT JOIN catalogo.municipio mun       ON mun.id = com.municipio_id

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
    COUNT(DISTINCT rm.nombre)           AS razas,
    COUNT(DISTINCT p.id)                AS productores,
    COUNT(DISTINCT par.id)              AS parcelas,

    CASE
        WHEN COUNT(DISTINCT rm.nombre) >= 10 THEN 'muy_alto'
        WHEN COUNT(DISTINCT rm.nombre) >= 6 THEN 'alto'
        WHEN COUNT(DISTINCT rm.nombre) >= 3 THEN 'medio'
        ELSE 'bajo'
    END AS nivel_prioridad_conservacion

FROM agronomico.germoplasma g
LEFT JOIN catalogo.raza_maiz rm ON rm.id = g.raza_id
    LEFT JOIN catalogo.color_grano cg ON cg.id = g.color_grano_id
JOIN agronomico.cultivo c         ON c.germoplasma_id = g.id
JOIN geografico.parcela par       ON par.id = c.parcela_id
JOIN social.productor p           ON p.id = par.productor_id
JOIN catalogo.comunidad com       ON com.id = g.comunidad_id
JOIN catalogo.municipio mun       ON mun.id = com.municipio_id
GROUP BY mun.id, mun.nombre
ORDER BY razas DESC;

-- ============================================================
-- VISTAS DEL EJE CULTURAL
-- ============================================================

-- Vista: mapa de saberes por comunidad
CREATE VIEW cultural.v_saberes_comunidad AS
SELECT
    mun.nombre          AS municipio,
    com.nombre          AS comunidad,
    com.tipo            AS tipo_comunidad,
    COUNT(DISTINCT st.id)                                AS total_saberes,
    COUNT(DISTINCT ra.id)                                AS total_rituales,
    COUNT(DISTINCT no.id)                                AS total_narrativas,
    COUNT(DISTINCT gt.id)                                AS total_platillos,
    SUM(CASE WHEN st.esta_vigente THEN 1 ELSE 0 END)     AS saberes_vigentes,
    SUM(CASE WHEN NOT st.esta_vigente THEN 1 ELSE 0 END) AS saberes_en_riesgo,
    SUM(CASE WHEN ra.esta_vigente THEN 1 ELSE 0 END)     AS rituales_vigentes
FROM catalogo.comunidad com
JOIN catalogo.municipio mun                         ON mun.id = com.municipio_id
LEFT JOIN catalogo.comunidad comcat                 ON comcat.id = com.id
LEFT JOIN cultural.saber_tradicional st             ON st.comunidad_id = com.id
LEFT JOIN cultural.ritual_agricola ra               ON ra.comunidad_id = com.id
LEFT JOIN cultural.narrativa_oral no                ON no.comunidad_id = com.id
LEFT JOIN cultural.gastronomia_tradicional gt       ON gt.comunidad_id = com.id
-- Catálogos adicionales
-- comcat.tipo_comunidad, comcat.region
GROUP BY mun.nombre, com.nombre, com.tipo
ORDER BY total_saberes DESC;

-- Vista: riesgo de pérdida cultural por productor
CREATE VIEW cultural.v_riesgo_perdida_cultural AS
SELECT
    p.nombres || ' ' || COALESCE(p.apellido_paterno,'') AS productor,
    mun.nombre      AS municipio,
    ic.se_identifica_etnia,
    ic.etnia_nombre,
    ic.habla_lengua_originaria,
    ic.maiz_es_parte_identidad,
    ic.se_siente_guardian_semillas,
    ic.percibe_perdida_cultura_maiz,
    tc.percibe_riesgo_perdida,
    tc.nivel_riesgo_percibido,
    tc.hay_barreras,
    tc.barrera_migracion_jovenes,
    tc.barrera_perdida_lengua,
    tc.transmite_a_hijos,
    tc.transmite_a_jovenes,
    (CASE WHEN ic.percibe_perdida_cultura_maiz THEN 2 ELSE 0 END +
     CASE WHEN tc.percibe_riesgo_perdida THEN 2 ELSE 0 END +
     CASE WHEN tc.barrera_migracion_jovenes THEN 1 ELSE 0 END +
     CASE WHEN tc.barrera_perdida_lengua THEN 1 ELSE 0 END +
     CASE WHEN NOT ic.habla_lengua_originaria THEN 1 ELSE 0 END +
     CASE WHEN NOT tc.transmite_a_hijos THEN 1 ELSE 0 END
    ) AS score_riesgo_cultural
FROM social.productor p
LEFT JOIN catalogo.localidad l             ON l.id = p.localidad_id
LEFT JOIN catalogo.comunidad com           ON com.id = l.comunidad_id
LEFT JOIN catalogo.municipio mun           ON mun.id = com.municipio_id
LEFT JOIN cultural.identidad_cultural ic            ON ic.productor_id = p.id
LEFT JOIN cultural.transmision_conocimiento tc      ON tc.productor_id = p.id
    LEFT JOIN catalogo.comunidad comcat        ON comcat.id = com.id
    -- Catálogos adicionales: comcat.tipo_comunidad, comcat.region
ORDER BY score_riesgo_cultural DESC;

-- Vista: patrimonio gastronómico por variedad de maíz
CREATE VIEW cultural.v_gastronomia_variedad AS
SELECT
    gt.variedad_maiz_preferida,
    gt.color_grano_preferido,
    COUNT(DISTINCT gt.id)           AS total_platillos,
    COUNT(DISTINCT gt.comunidad_id) AS comunidades_que_lo_usan,
    STRING_AGG(DISTINCT gt.nombre_platillo, ', ') AS platillos,
    SUM(CASE WHEN gt.vinculo_ritual THEN 1 ELSE 0 END) AS platillos_rituales,
    SUM(CASE WHEN gt.esta_vigente THEN 1 ELSE 0 END)   AS platillos_vigentes
FROM cultural.gastronomia_tradicional gt
WHERE gt.variedad_maiz_preferida IS NOT NULL
GROUP BY gt.variedad_maiz_preferida, gt.color_grano_preferido
ORDER BY total_platillos DESC;

-- Vista integrada: germoplasma con su riqueza cultural
CREATE VIEW cultural.v_germoplasma_cultural AS
SELECT
    nlo.germoplasma_id,
    l.nombre            AS lengua,
    nlo.nombre          AS nombre_originario,
    nlo.significado_literal,
    nlo.significado_cultural,
    com.nombre          AS comunidad_origen,
    mun.nombre          AS municipio,
    g.nombre_local      AS variedad_local,
    rm.nombre           AS raza,
    rm.region_origen    AS raza_region_origen,
    rm.tipo_ciclo       AS raza_tipo_ciclo,
    rm.es_nativa        AS raza_es_nativa,
    cg.nombre           AS color_grano,
    cg.es_nativo        AS color_grano_es_nativo,
    (SELECT COUNT(*) FROM cultural.gastronomia_tradicional gt
     WHERE gt.variedad_maiz_preferida ILIKE '%' || nlo.nombre || '%') AS platillos_asociados
FROM cultural.nombre_lengua_originaria nlo
JOIN catalogo.lengua l              ON l.id = nlo.lengua_id
LEFT JOIN catalogo.comunidad com    ON com.id = nlo.comunidad_id
LEFT JOIN catalogo.municipio mun    ON mun.id = com.municipio_id
LEFT JOIN agronomico.germoplasma g  ON g.id = nlo.germoplasma_id
LEFT JOIN catalogo.raza_maiz rm     ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg   ON cg.id = g.color_grano_id;

-- ============================================================
-- VISTA: inventario multimedia por comunidad
-- ============================================================

CREATE VIEW cultural.v_inventario_medios AS
SELECT
    com.nombre                          AS comunidad,
    mun.nombre                          AS municipio,
    mc.entidad_tipo,
    mc.tipo_medio,
    COUNT(*)                            AS total_archivos,
    COUNT(*) FILTER (WHERE mc.consentimiento_verificado) AS con_consentimiento
FROM cultural.medio_cultural mc
LEFT JOIN social.productor p        ON p.id = mc.productor_id
LEFT JOIN catalogo.localidad l      ON l.id = p.localidad_id
LEFT JOIN catalogo.comunidad com    ON com.id = l.comunidad_id
LEFT JOIN catalogo.municipio mun    ON mun.id = com.municipio_id
GROUP BY com.nombre, mun.nombre, mc.entidad_tipo, mc.tipo_medio
ORDER BY mun.nombre, com.nombre, mc.entidad_tipo;


CREATE VIEW fenotipico.v_fenotipo_territorial AS
SELECT
    ef.id                     AS evaluacion_id,
    ef.fecha_evaluacion,

    g.id                      AS germoplasma_id,
    g.nombre_local            AS variedad_local,
    rm.nombre                 AS raza,
    rm.region_origen          AS raza_region_origen,
    rm.tipo_ciclo             AS raza_tipo_ciclo,
    rm.es_nativa              AS raza_es_nativa,
    cg.nombre                 AS color_grano,
    cg.es_nativo              AS color_grano_es_nativo,

    com.nombre                AS comunidad,
    mun.nombre                AS municipio,
    ef.altura_planta_cm,
    ef.altura_mazorca_cm,
    ef.indice_apl_amz,

    ef.tamanio_mazorca_cm,
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
LEFT JOIN catalogo.raza_maiz rm    ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg  ON cg.id = g.color_grano_id
LEFT JOIN catalogo.comunidad com   ON com.id = ef.comunidad_id
LEFT JOIN catalogo.municipio mun   ON mun.id = com.municipio_id;

-- Vista integrada: nutrición del maíz nativo por territorio
CREATE VIEW fenotipico.v_nutricion_maiz AS
SELECT
    mn.codigo_muestra,
    mn.fecha_colecta,

    g.id                   AS germoplasma_id,
    g.nombre_local         AS variedad_local,
    rm.nombre              AS raza,
    rm.region_origen       AS raza_region_origen,
    rm.tipo_ciclo          AS raza_tipo_ciclo,
    rm.es_nativa           AS raza_es_nativa,
    cg.nombre              AS color_grano,
    cg.es_nativo           AS color_grano_es_nativo,

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
LEFT JOIN catalogo.raza_maiz rm    ON rm.id = g.raza_id
LEFT JOIN catalogo.color_grano cg  ON cg.id = g.color_grano_id
LEFT JOIN fenotipico.resultado_nutrimental rn
       ON rn.muestra_id = mn.id
LEFT JOIN catalogo.comunidad com   ON com.id = mn.comunidad_id
LEFT JOIN catalogo.municipio mun   ON mun.id = com.municipio_id;


-- ============================================================
-- VISTAS AMBIENTALES PARA ANALISIS AGROECOLOGICO
-- ============================================================

-- Vista: clima por ubicación/parcela
-- Descripción: Proporciona datos climáticos agregados (temperatura, humedad, precipitación, radiación, viento) por ubicación/parcela y fecha, a partir de mediciones ambientales.
CREATE VIEW ambiental.v_clima_ubicacion AS
SELECT
    ma.ubicacion_id,
    u.latitud,
    u.longitud,
    DATE(ma.fecha_medicion) AS fecha,
    AVG(ma.temperatura_c)      AS temperatura_promedio,
    AVG(ma.humedad_pct)        AS humedad_promedio,
    SUM(ma.precipitacion_mm)   AS precipitacion_total,
    AVG(ma.radiacion_solar)    AS radiacion_promedio,
    AVG(ma.velocidad_viento)   AS viento_promedio
FROM ambiental.medicion_ambiental ma
JOIN geografico.ubicacion u
    ON u.id = ma.ubicacion_id
GROUP BY ma.ubicacion_id, u.latitud, u.longitud, DATE(ma.fecha_medicion);


-- Vista: índices de vegetación por parcela
-- Descripción: Muestra los principales índices de vegetación (NDVI, NDWI, GNDVI, etc.) calculados para cada parcela, junto con información de localización y comunidad.
CREATE VIEW ambiental.v_ndvi_parcela AS
SELECT
    iv.parcela_id,
    p.nombre            AS parcela,
    com.nombre          AS comunidad,
    mun.nombre          AS municipio,
    iv.fecha_calculo,
    iv.ndvi,
    iv.ndwi,
    iv.gndvi,
    iv.ndmi,
    iv.evi,
    iv.lai,
    iv.estado_vegetacion,
    iv.estres_hidrico,
    iv.estres_termico
FROM ambiental.indice_vegetacion iv
JOIN geografico.parcela p
    ON p.id = iv.parcela_id
LEFT JOIN geografico.ubicacion u ON u.id = p.ubicacion_id
LEFT JOIN catalogo.comunidad com ON com.id = u.comunidad_id
LEFT JOIN catalogo.municipio mun ON mun.id = com.municipio_id;


-- Vista: condiciones de suelo por parcela
-- Descripción: Presenta las condiciones edáficas (tipo de suelo, textura, pH, nutrientes, materia orgánica, etc.) de cada parcela, asociando comunidad y municipio.
CREATE VIEW ambiental.v_suelo_parcela AS
SELECT
    ce.parcela_id,
    p.nombre            AS parcela,
    com.nombre          AS comunidad,
    mun.nombre          AS municipio,
    ce.tipo_suelo,
    ce.textura,
    ce.ph,
    ce.materia_organica_pct,
    ce.nitrogeno_ppm,
    ce.fosforo_ppm,
    ce.potasio_ppm,
    ce.capacidad_campo_pct,
    ce.fecha_muestreo
FROM ambiental.condicion_edafica ce
JOIN geografico.parcela p
    ON p.id = ce.parcela_id
LEFT JOIN geografico.ubicacion u
    ON u.id = p.ubicacion_id
LEFT JOIN catalogo.comunidad com
    ON com.id = u.comunidad_id
LEFT JOIN catalogo.municipio mun
    ON mun.id = com.municipio_id;
SELECT
    ce.parcela_id,
    p.nombre            AS parcela,
    com.nombre          AS comunidad,
    mun.nombre          AS municipio,
    ce.tipo_suelo,
    ce.textura,
    ce.ph,
    ce.materia_organica_pct,
    ce.nitrogeno_ppm,
    ce.fosforo_ppm,
    ce.potasio_ppm,
    ce.capacidad_campo_pct,
    ce.fecha_muestreo
FROM ambiental.condicion_edafica ce
JOIN geografico.parcela p
    ON p.id = ce.parcela_id
LEFT JOIN geografico.ubicacion u
    ON u.id = p.ubicacion_id
LEFT JOIN catalogo.comunidad com
    ON com.id = u.comunidad_id
LEFT JOIN catalogo.municipio mun
    ON mun.id = com.municipio_id;


-- Vista: amenazas socioambientales territoriales
-- Descripción: Lista amenazas ambientales detectadas (tipo, nivel de riesgo, área afectada, estado) vinculadas a la ubicación, comunidad y municipio.
CREATE VIEW ambiental.v_riesgo_ambiental AS
SELECT
    a.id,
    ta.nombre AS tipo_amenaza,
    a.nivel_riesgo,
    a.fecha_deteccion,
    a.area_afectada_ha,
    a.esta_activa,
    com.nombre      AS comunidad,
    mun.nombre      AS municipio,
    a.descripcion
FROM ambiental.amenaza a
LEFT JOIN catalogo.tipo_amenaza ta ON ta.id = a.tipo_amenaza_id
LEFT JOIN geografico.ubicacion u ON u.id = a.ubicacion_id
LEFT JOIN catalogo.comunidad com ON com.id = u.comunidad_id
LEFT JOIN catalogo.municipio mun ON mun.id = a.municipio_id;


-- Vista: perfil completo de parcela
-- Descripción: Integra información geográfica, ambiental, de manejo y observaciones de campo para cada parcela, facilitando un análisis integral de su contexto y estado.

CREATE VIEW ambiental.v_perfil_parcela AS
SELECT
    par.id                          AS parcela_id,
    par.nombre                      AS parcela,
    par.superficie_ha,
    par.tenencia,
    sm.nombre                       AS sistema_manejo,
    par.topografia,
    mun.nombre                      AS municipio,
    com.nombre                      AS comunidad,
    -- Ubicación
    ub.latitud,
    ub.longitud,
    ub.altitud_m,
    ub.zona_agroecologica,
    fi.nombre AS fuente_captura,
    -- Observación campo
    oc.textura_suelo,
    oc.condicion_humedad,
    oc.presencia_erosion,
    oc.pendiente_estimada_pct,
    oc.cobertura_vegetal_pct,
    oc.hay_fuente_agua_cercana,
    -- Historial
    hp.anios_cultivando,
    hp.siempre_maiz_nativo,
    -- Mediciones de laboratorio/sensor (si existen)
    ce.ph,
    ce.materia_organica_pct,
    ce.textura                      AS textura_laboratorio,
    -- Índice NDVI más reciente
    (SELECT ndvi FROM ambiental.indice_vegetacion iv
     WHERE iv.parcela_id = par.id
     ORDER BY iv.fecha_calculo DESC LIMIT 1) AS ndvi_reciente,
    -- Conteo de fotos
    (SELECT COUNT(*) FROM geografico.medio_parcela mp
     WHERE mp.parcela_id = par.id)  AS total_fotos
FROM geografico.parcela par
LEFT JOIN catalogo.sistema_manejo sm     ON sm.id = par.sistema_manejo_id
LEFT JOIN geografico.ubicacion          ub  ON ub.id  = par.ubicacion_id
LEFT JOIN catalogo.fuente_informacion   fi  ON fi.id = ub.fuente_captura_id
LEFT JOIN catalogo.comunidad            com ON com.id = ub.comunidad_id
LEFT JOIN catalogo.municipio            mun ON mun.id = com.municipio_id
LEFT JOIN geografico.observacion_campo  oc  ON oc.parcela_id = par.id
LEFT JOIN geografico.historial_parcela  hp  ON hp.parcela_id = par.id
LEFT JOIN ambiental.condicion_edafica   ce  ON ce.parcela_id = par.id
ORDER BY mun.nombre, com.nombre, par.nombre;

-- ═══════════════════════════════════════════════════════
--  VISTAS Y FUNCIONES ÚTILES
-- ═══════════════════════════════════════════════════════

-- Vista: resumen completo por variedad (une fenotípico + agronómico)
CREATE OR REPLACE VIEW v_variedades_resumen AS
SELECT
    v.id,
    v.nombre,
    v.tipo_variedad,
    v.obtentor,
    -- fenotípico
    ef.id           AS eval_feno_id,
    ef.ciclo_eval,
    ef.año_eval,
    ef.completitud_pct,
    ef.localidad,
    -- agronómico
    ra.id           AS reg_agron_id,
    ra.dias_floracion_masc,
    ra.dias_floracion_fem,
    ra.intervalo_ase,
    ra.zona_adapt_ppal,
    ra.regimen_hid,
    -- espacial: coordenadas del primer punto registrado
    ST_Y(pe.ubicacion::geometry)  AS latitud,
    ST_X(pe.ubicacion::geometry)  AS longitud,
    pe.municipio,
    pe.altitud_msnm
FROM variedades v
LEFT JOIN evaluaciones_fenotipicas ef ON ef.variedad_id = v.id
LEFT JOIN registros_agronomicos    ra ON ra.variedad_id = v.id
LEFT JOIN LATERAL (
    SELECT * FROM parcelas_evaluacion
    WHERE registro_agron_id = ra.id
    LIMIT 1
) pe ON TRUE
WHERE v.activo = TRUE;


-- Vista: valores fenotípicos en formato tabular ancho (pivot)
-- (útil para exportar / comparar variedades)
CREATE OR REPLACE VIEW v_evaluacion_detalle AS
SELECT
    ef.id AS evaluacion_id,
    v.nombre,
    ef.ciclo_eval,
    ef.año_eval,
    dc.id           AS descriptor_id,
    dc.modulo,
    dc.etapa_bbch,
    dc.label_es,
    dc.tipo_desc,
    vf.valor_texto,
    vf.valor_numerico,
    vf.valor_codigo
FROM evaluaciones_fenotipicas ef
JOIN variedades v               ON v.id = ef.variedad_id
JOIN valores_fenotipicos vf     ON vf.evaluacion_id = ef.id
JOIN descriptores_catalogo dc   ON dc.id = vf.descriptor_id
ORDER BY ef.id, dc.id;


-- Función PostGIS: variedades evaluadas en radio de X km desde un punto
CREATE OR REPLACE FUNCTION variedades_en_radio(
    lat      DOUBLE PRECISION,
    lng      DOUBLE PRECISION,
    radio_km DOUBLE PRECISION
) RETURNS TABLE(
    variedad_id  INT,
    nombre       TEXT,
    distancia_km NUMERIC,
    municipio    TEXT
) AS $$
SELECT DISTINCT ON(v.id)
    v.id,
    v.nombre,
    ROUND(ST_Distance(
        pe.ubicacion,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    ) / 1000.0, 2),
    pe.municipio
FROM parcelas_evaluacion pe
JOIN registros_agronomicos ra ON ra.id = pe.registro_agron_id
JOIN variedades v             ON v.id = ra.variedad_id
WHERE
    ST_DWithin(
        pe.ubicacion,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
        radio_km * 1000
    )
    AND v.activo = TRUE
ORDER BY v.id, distancia_km;
$$ LANGUAGE SQL STABLE;

-- Uso: SELECT * FROM variedades_en_radio(21.85, -98.95, 50);