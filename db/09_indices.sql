-- =========================
-- INDICES: CATALOGO
-- =========================

-- ============================================================
-- 1. ESTADO
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_estado_nombre ON catalogo.estado USING gin(to_tsvector('spanish', nombre));

-- ============================================================
-- 2. MUNICIPIO
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_municipio_clave ON catalogo.municipio(clave_completa);
CREATE INDEX IF NOT EXISTS idx_municipio_nombre ON catalogo.municipio USING gin(to_tsvector('spanish', nombre));
CREATE INDEX IF NOT EXISTS idx_municipio_estado ON catalogo.municipio(estado_id);

-- ============================================================
-- 3. COMUNIDAD
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_comunidad_municipio ON catalogo.comunidad(municipio_id);

CREATE INDEX IF NOT EXISTS idx_comunidad_nombre
ON catalogo.comunidad USING gin(to_tsvector('spanish', nombre));

-- ============================================================
-- 4. LOCALIDAD
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_localidad_municipio ON catalogo.localidad(municipio_id);

CREATE INDEX IF NOT EXISTS idx_localidad_comunidad ON catalogo.localidad(comunidad_id);

CREATE INDEX IF NOT EXISTS idx_localidad_clave ON catalogo.localidad(clave_inegi);

CREATE INDEX IF NOT EXISTS idx_localidad_nombre ON catalogo.localidad
    USING gin(to_tsvector('spanish', nombre));

CREATE INDEX IF NOT EXISTS idx_localidad_tipo ON catalogo.localidad(tipo);

CREATE INDEX IF NOT EXISTS idx_localidad_coordenadas ON catalogo.localidad(latitud, longitud);

-- ============================================================
-- 5. COLONIA / BARRIO / SECCION
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_colonia_localidad ON catalogo.colonia(localidad_id);
CREATE INDEX IF NOT EXISTS idx_colonia_cp ON catalogo.colonia(codigo_postal);

-- ============================================================
-- 6. LENGUA ORIGINARIA
-- ============================================================

-- ============================================================
-- 7. PUEBLO ORIGINARIO
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_pueblo_lengua ON catalogo.pueblo_originario(lengua_id);



-- ----------------------------
-- Índices analíticos
-- ----------------------------

CREATE INDEX IF NOT EXISTS idx_localidad_marginacion
ON catalogo.localidad(grado_marginacion);

CREATE INDEX IF NOT EXISTS idx_localidad_indigena
ON catalogo.localidad(indigena);

-- ----------------------------
-- (OPCIONAL) Índices espaciales
-- ----------------------------

-- Solo si agregas columna geom
-- ALTER TABLE catalogo.localidad ADD COLUMN geom GEOMETRY(Point, 4326);

-- CREATE INDEX IF NOT EXISTS idx_localidad_geom
-- ON catalogo.localidad USING GIST (geom);

-- =========================
-- INDICES: GEOGRAFICO
-- =========================

-- ============================================================
-- 1. UBICACIÓN
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_ubicacion_geom ON geografico.ubicacion USING GIST (geom);

-- ============================================================
-- 2. PARCELA
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_parcela_poligono ON geografico.parcela USING GIST (poligono);

CREATE INDEX IF NOT EXISTS idx_parcela_productor ON geografico.parcela(productor_id);
CREATE INDEX IF NOT EXISTS idx_parcela_ubicacion ON geografico.parcela(ubicacion_id);

-- ============================================================
-- 3. HISTORIAL DE USO DE LA PARCELA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_historial_parcela ON geografico.historial_parcela(parcela_id);

-- ============================================================
-- 4. IMAGEN SATELITAL
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_imagen_satelital_geom ON geografico.imagen_satelital USING GIST (extent_geom);

-- ============================================================
-- 5. VUELO DE DRON
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_vuelo_dron_geom ON geografico.vuelo_dron USING GIST (area_vuelo);

-- ============================================================
-- 6. PRODUCTO PROCESADO DEL VUELO DE DRON
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_producto_dron_extent ON geografico.producto_dron USING GIST (extent_geom);

-- ============================================================
-- 7. CAPAS SIG TEMÁTICAS
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_capa_sig_nombre ON geografico.capa_sig(nombre);

-- ============================================================
-- 8. ZONA PRIORITARIA DE CONSERVACIÓN
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_zona_prioritaria_geom ON geografico.zona_prioritaria USING GIST (poligono);

-- ============================================================
-- 9. CAMBIO DE USO DE SUELO (multitemporal)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_cambio_uso_suelo_geom ON geografico.cambio_uso_suelo USING GIST (poligono);
CREATE INDEX IF NOT EXISTS idx_cambio_uso_suelo_municipio ON geografico.cambio_uso_suelo(municipio_id);
CREATE INDEX IF NOT EXISTS idx_cambio_uso_suelo_clase_inicial ON geografico.cambio_uso_suelo(clase_inicial);
CREATE INDEX IF NOT EXISTS idx_cambio_uso_suelo_clase_final ON geografico.cambio_uso_suelo(clase_final);

-- ============================================================
-- 10. VISITA DE CAMPO
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_visita_campo_punto ON geografico.visita_campo USING GIST (punto_inicio);
CREATE INDEX IF NOT EXISTS idx_visita_campo_localidad ON geografico.visita_campo(localidad_id);

-- ============================================================
-- 11. OBSERVACIÓN AMBIENTAL EN CAMPO
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_obs_campo_parcela   ON geografico.observacion_campo(parcela_id);
CREATE INDEX IF NOT EXISTS idx_obs_campo_ubicacion ON geografico.observacion_campo(ubicacion_id);

-- ============================================================
-- 12. MEDIO PARCELA
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_medio_parcela_parcela ON geografico.medio_parcela(parcela_id);


-- =========================
-- INDICES: SOCIAL
-- =========================

-- =============================================================
-- 1. PRÁCTICA AGRÍCOLA
-- =============================================================

-- ============================================================
-- 2. PRODUCTOR / CUSTODIO
-- ============================================================

-- ============================================================
-- 3. PRODUCTOR - PRÁCTICA AGRÍCOLA (N:M)
-- ============================================================

-- ============================================================
-- 3. PRODUCTOR - LENGUA (N:M)
-- ============================================================

-- ============================================================
-- 4. CONSENTIMIENTO INFORMADO
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_consentimiento_productor ON social.consentimiento(productor_id);

-- ============================================================
-- 5. PERFIL SOCIOECONOMICO
-- ============================================================

-- ============================================================
-- 6. SEGURIDAD ALIMENTARIA (Escala ELCSA)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_seguridad_productor ON social.seguridad_alimentaria(productor_id);

-- ============================================================
-- 7. RED DE INTERCAMBIO Y CAPITAL SOCIAL
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_red_productor ON social.red_intercambio(productor_id);

-- ============================================================
-- 8. VULNERABILIDAD CLIMATICA PERCIBIDA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_vulnerabilidad_productor ON social.vulnerabilidad_climatica(productor_id);

-- ============================================================
-- 9. GEOLOCALIZACIÓN DE PRODUCTORES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_geo_productor ON social.geolocalizacion_productor(productor_id);

-- Índice espacial simple para consultas por zona
-- Índice GIST espacial si se usa PostGIS
CREATE INDEX idx_geo_location
    ON social.geolocalizacion_productor
    USING GIST (
        ST_SetSRID(
            ST_MakePoint(longitud, latitud),
            4326
        )
    );

-- =========================
-- INDICES: AGRONOMICO
-- =========================

-- ============================================================
-- 1. CICLO AGRÍCOLA
-- ============================================================

-- ============================================================
-- 2. GERMOPLASMA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_germoplasma_nombre ON agronomico.germoplasma USING gin(to_tsvector('spanish', nombre_local));

CREATE INDEX IF NOT EXISTS idx_germoplasma_comunidad ON agronomico.germoplasma(comunidad_id);

CREATE INDEX IF NOT EXISTS idx_germoplasma_raza ON agronomico.germoplasma(raza_id);

CREATE INDEX IF NOT EXISTS idx_germoplasma_color ON agronomico.germoplasma(color_grano_id);

-- ============================================================
-- 3. CULTIVO
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_cultivo_parcela ON agronomico.cultivo(parcela_id);

CREATE INDEX IF NOT EXISTS idx_cultivo_germoplasma ON agronomico.cultivo(germoplasma_id);

CREATE INDEX IF NOT EXISTS idx_cultivo_ciclo ON agronomico.cultivo(ciclo_agricola_id);

CREATE INDEX IF NOT EXISTS idx_cultivo_parcela_fecha ON agronomico.cultivo(parcela_id, fecha_siembra);

CREATE INDEX IF NOT EXISTS idx_cultivo_fecha ON agronomico.cultivo(fecha_siembra);

-- ============================================================
-- 4. SISTEMA DE SEMILLA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_sistema_semilla_productor ON agronomico.sistema_semilla(productor_id);

CREATE INDEX IF NOT EXISTS idx_sistema_semilla_germoplasma ON agronomico.sistema_semilla(germoplasma_id);

-- ============================================================
-- 5. USOS DEL MAÍZ COSECHADO
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_uso_maiz_cultivo ON agronomico.uso_maiz(cultivo_id);

-- ============================================================
-- 6. ECONOMÍA DEL CULTIVO
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_economia_cultivo ON agronomico.economia_cultivo(cultivo_id);

-- =========================
-- INDICES: CULTURAL
-- =========================

-- ============================================================
-- 1. SABER TRADICIONAL DE CULTIVO
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_saber_comunidad ON cultural.saber_tradicional(comunidad_id);

CREATE INDEX IF NOT EXISTS idx_saber_productor ON cultural.saber_tradicional(productor_id);

-- ============================================================
-- 2. RITUAL Y CEREMONIA AGRÍCOLA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_ritual_comunidad ON cultural.ritual_agricola(comunidad_id);

-- ============================================================
-- 3. NARRATIVA ORAL
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_narrativa_comunidad ON cultural.narrativa_oral(comunidad_id);

CREATE INDEX IF NOT EXISTS idx_narrativa_productor ON cultural.narrativa_oral(productor_id);

-- ============================================================
-- 4. GASTRONOMÍA TRADICIONAL
-- ============================================================

-- ============================================================
-- 5. TRANSMISIÓN INTERGENERACIONAL
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_transmision_productor ON cultural.transmision_conocimiento(productor_id);

-- ============================================================
-- 6. IDENTIDAD CULTURAL
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_identidad_productor ON cultural.identidad_cultural(productor_id);

-- ============================================================
-- 7. NOMBRE EN LENGUA ORIGINARIA 
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_nombre_lengua_germoplasma ON cultural.nombre_lengua_originaria(germoplasma_id);

-- ============================================================
-- 8. MEDIO CULTURAL
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_medio_entidad ON cultural.medio_cultural(entidad_tipo, entidad_id);
CREATE INDEX IF NOT EXISTS idx_medio_productor ON cultural.medio_cultural(productor_id);
CREATE INDEX IF NOT EXISTS idx_medio_tipo ON cultural.medio_cultural(tipo_medio);

-- ============================================================
-- 9. SESIÓN DE ENTREVISTA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_sesion_productor ON cultural.sesion_entrevista(productor_id);
CREATE INDEX IF NOT EXISTS idx_sesion_municipio ON cultural.sesion_entrevista(municipio_id);
CREATE INDEX IF NOT EXISTS idx_sesion_lat_lon ON cultural.sesion_entrevista(latitud, longitud);

-- =========================
-- INDICES: FENOTIPICO
-- =========================

-- ============================================================
-- 1. EVALUACION FENOTIPICA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_eval_cultivo ON fenotipico.evaluacion_fenotipica(cultivo_id);
CREATE INDEX IF NOT EXISTS idx_eval_comunidad ON fenotipico.evaluacion_fenotipica(comunidad_id);
CREATE INDEX IF NOT EXISTS idx_evidencia_evaluacion ON fenotipico.evidencia(evaluacion_id);

-- ============================================================
-- 2. EVIDENCIA MULTIMEDIA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_evidencia_eval ON fenotipico.evidencia(evaluacion_id);

-- ============================================================
-- 3. MUESTRA NUTRIMENTAL
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_muestra_germoplasma ON fenotipico.muestra_nutrimental(germoplasma_id);

-- ============================================================
-- 4. RESULTADO NUTRIMENTAL
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_resultado_muestra ON fenotipico.resultado_nutrimental(muestra_id);

-- =========================
-- INDICES: AMBIENTAL
-- =========================

-- ============================================================
-- 1. ESTACIÓN METEROLÓGICA
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_estacion_activa ON ambiental.estacion_meteorologica(activa);

-- ============================================================
-- 2. MEDICIÓN AMBIENTAL
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_medicion_fecha ON ambiental.medicion_ambiental(fecha_medicion);

CREATE INDEX IF NOT EXISTS idx_medicion_ubicacion ON ambiental.medicion_ambiental(ubicacion_id);

CREATE INDEX IF NOT EXISTS idx_medicion_estacion ON ambiental.medicion_ambiental(estacion_id);

CREATE INDEX IF NOT EXISTS idx_medicion_ubicacion_fecha ON ambiental.medicion_ambiental(ubicacion_id, fecha_medicion);
-- ============================================================
-- 3. INDICE VEGETACIÓN
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_indice_parcela ON ambiental.indice_vegetacion(parcela_id);

CREATE INDEX IF NOT EXISTS idx_indice_fecha ON ambiental.indice_vegetacion(fecha_calculo);

CREATE INDEX IF NOT EXISTS idx_indice_parcela_fecha ON ambiental.indice_vegetacion(parcela_id, fecha_calculo);
-- ============================================================
-- 4. SERIE NDVI
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_serie_ndvi_parcela ON ambiental.serie_ndvi(parcela_id);
-- ============================================================
-- 5. CONDICION EDAFICA
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_suelo_parcela ON ambiental.condicion_edafica(parcela_id);

-- ============================================================
-- 6. AMENAZA
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_amenaza_geom ON ambiental.amenaza USING GIST (poligono);

CREATE INDEX IF NOT EXISTS idx_amenaza_municipio ON ambiental.amenaza(municipio_id);

-- =========================
-- INDICES PARA CONSULTAS TEMPORALES (si tienes fechas)
-- =========================

CREATE INDEX IF NOT EXISTS idx_amenaza_fecha
ON ambiental.amenaza(fecha_deteccion);