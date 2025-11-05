
-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS PARA ACTUALIZAR REPORTES
-- =====================================================

-- Procedimiento para actualizar reporte estudiante-curso
DELIMITER //
CREATE PROCEDURE sp_actualizar_reporte_estudiante_curso(
    IN p_cui VARCHAR(20),
    IN p_grupo_id INT
)
BEGIN
    DECLARE v_codigo_curso VARCHAR(20);
    DECLARE v_id_ciclo INT;
    DECLARE v_total_clases INT;
    DECLARE v_asistencias INT;
    DECLARE v_faltas INT;
    
    -- Obtener datos del grupo
    SELECT gc.codigo_curso, gc.id_ciclo
    INTO v_codigo_curso, v_id_ciclo
    FROM grupos_curso gc
    WHERE gc.grupo_id = p_grupo_id;
    
    -- Contar asistencias
    SELECT 
        COUNT(*),
        SUM(CASE WHEN ae.estado_asistencia = 'PRESENTE' THEN 1 ELSE 0 END),
        SUM(CASE WHEN ae.estado_asistencia = 'FALTA' THEN 1 ELSE 0 END)
    INTO v_total_clases, v_asistencias, v_faltas
    FROM asistencias_estudiante ae
    INNER JOIN matriculas m ON ae.id_matricula = m.id_matricula
    INNER JOIN horarios h ON ae.id_horario = h.id_horario
    WHERE m.cui = p_cui 
    AND h.grupo_id = p_grupo_id;
    
    -- Insertar o actualizar reporte
    INSERT INTO reporte_estudiante_curso (
        cui, codigo_curso, id_ciclo, grupo_id,
        total_clases, asistencias, faltas, porcentaje_asistencia
    ) VALUES (
        p_cui, v_codigo_curso, v_id_ciclo, p_grupo_id,
        COALESCE(v_total_clases, 0),
        COALESCE(v_asistencias, 0),
        COALESCE(v_faltas, 0),
        CASE WHEN v_total_clases > 0 THEN (v_asistencias * 100.0 / v_total_clases) ELSE 0 END
    )
    ON DUPLICATE KEY UPDATE
        total_clases = VALUES(total_clases),
        asistencias = VALUES(asistencias),
        faltas = VALUES(faltas),
        porcentaje_asistencia = VALUES(porcentaje_asistencia);
END //

-- Procedimiento para actualizar notas en reporte estudiante-curso
CREATE PROCEDURE sp_actualizar_notas_reporte(
    IN p_id_matricula INT
)
BEGIN
    DECLARE v_cui VARCHAR(20);
    DECLARE v_grupo_id INT;
    DECLARE v_nota_p1 DECIMAL(5,2);
    DECLARE v_nota_p2 DECIMAL(5,2);
    DECLARE v_nota_final DECIMAL(5,2);
    DECLARE v_promedio DECIMAL(5,2);
    
    -- Obtener datos de matrícula
    SELECT cui, grupo_id INTO v_cui, v_grupo_id
    FROM matriculas WHERE id_matricula = p_id_matricula;
    
    -- Obtener notas (asumiendo códigos P1, P2, EF)
    SELECT n.calificacion INTO v_nota_p1
    FROM notas n
    INNER JOIN tipos_evaluacion te ON n.tipo_eval_id = te.tipo_eval_id
    WHERE n.id_matricula = p_id_matricula AND te.codigo = 'P1';
    
    SELECT n.calificacion INTO v_nota_p2
    FROM notas n
    INNER JOIN tipos_evaluacion te ON n.tipo_eval_id = te.tipo_eval_id
    WHERE n.id_matricula = p_id_matricula AND te.codigo = 'P2';
    
    SELECT n.calificacion INTO v_nota_final
    FROM notas n
    INNER JOIN tipos_evaluacion te ON n.tipo_eval_id = te.tipo_eval_id
    WHERE n.id_matricula = p_id_matricula AND te.codigo = 'EF';
    
    -- Calcular promedio (ajustar según sistema de evaluación)
    SET v_promedio = (COALESCE(v_nota_p1, 0) + COALESCE(v_nota_p2, 0) + COALESCE(v_nota_final, 0)) / 3;
    
    -- Actualizar reporte
    UPDATE reporte_estudiante_curso
    SET nota_parcial_1 = v_nota_p1,
        nota_parcial_2 = v_nota_p2,
        nota_final = v_nota_final,
        nota_promedio_final = v_promedio,
        estado_aprobacion = CASE 
            WHEN v_promedio >= 10.5 THEN 'APROBADO'
            WHEN v_nota_final IS NOT NULL THEN 'DESAPROBADO'
            ELSE 'EN_CURSO'
        END
    WHERE cui = v_cui AND grupo_id = v_grupo_id;
END //

-- Procedimiento para actualizar rendimiento general del estudiante
CREATE PROCEDURE sp_actualizar_rendimiento_estudiante(
    IN p_cui VARCHAR(20),
    IN p_id_ciclo INT
)
BEGIN
    DECLARE v_total_cursos INT;
    DECLARE v_aprobados INT;
    DECLARE v_desaprobados INT;
    DECLARE v_promedio DECIMAL(5,2);
    DECLARE v_promedio_asistencia DECIMAL(5,2);
    
    -- Contar cursos
    SELECT 
        COUNT(*),
        SUM(CASE WHEN estado_aprobacion = 'APROBADO' THEN 1 ELSE 0 END),
        SUM(CASE WHEN estado_aprobacion = 'DESAPROBADO' THEN 1 ELSE 0 END),
        AVG(nota_promedio_final),
        AVG(porcentaje_asistencia)
    INTO v_total_cursos, v_aprobados, v_desaprobados, v_promedio, v_promedio_asistencia
    FROM reporte_estudiante_curso
    WHERE cui = p_cui AND id_ciclo = p_id_ciclo;
    
    -- Insertar o actualizar
    INSERT INTO reporte_rendimiento_estudiante (
        cui, id_ciclo, total_cursos_matriculados,
        cursos_aprobados, cursos_desaprobados,
        cursos_en_curso, promedio_ponderado, promedio_asistencia,
        estado_academico
    ) VALUES (
        p_cui, p_id_ciclo, COALESCE(v_total_cursos, 0),
        COALESCE(v_aprobados, 0), COALESCE(v_desaprobados, 0),
        v_total_cursos - v_aprobados - v_desaprobados,
        COALESCE(v_promedio, 0), COALESCE(v_promedio_asistencia, 0),
        CASE 
            WHEN v_promedio < 10.5 THEN 'RIESGO'
            WHEN v_promedio_asistencia < 70 THEN 'OBSERVADO'
            ELSE 'REGULAR'
        END
    )
    ON DUPLICATE KEY UPDATE
        total_cursos_matriculados = VALUES(total_cursos_matriculados),
        cursos_aprobados = VALUES(cursos_aprobados),
        cursos_desaprobados = VALUES(cursos_desaprobados),
        cursos_en_curso = VALUES(cursos_en_curso),
        promedio_ponderado = VALUES(promedio_ponderado),
        promedio_asistencia = VALUES(promedio_asistencia),
        estado_academico = VALUES(estado_academico);
END //

-- Procedimiento para actualizar reporte docente
CREATE PROCEDURE sp_actualizar_reporte_docente(
    IN p_id_docente INT,
    IN p_grupo_id INT
)
BEGIN
    DECLARE v_codigo_curso VARCHAR(20);
    DECLARE v_id_ciclo INT;
    DECLARE v_clases_programadas INT;
    DECLARE v_clases_dictadas INT;
    DECLARE v_total_temas INT;
    DECLARE v_temas_completados INT;
    
    -- Obtener datos del grupo
    SELECT gc.codigo_curso, gc.id_ciclo
    INTO v_codigo_curso, v_id_ciclo
    FROM grupos_curso gc
    WHERE gc.grupo_id = p_grupo_id;
    
    -- Contar clases del docente
    SELECT 
        COUNT(DISTINCT h.id_horario),
        COUNT(DISTINCT CASE WHEN ad.presente = TRUE THEN ad.id_asistencia_docente END)
    INTO v_clases_programadas, v_clases_dictadas
    FROM horarios h
    LEFT JOIN asistencias_docente ad ON h.id_horario = ad.id_horario
    WHERE h.grupo_id = p_grupo_id AND h.id_docente = p_id_docente;
    
    -- Contar temas (si existe sílabo)
    SELECT 
        COUNT(*),
        SUM(CASE WHEN t.estado = 'COMPLETADO' THEN 1 ELSE 0 END)
    INTO v_total_temas, v_temas_completados
    FROM temas t
    INNER JOIN unidades u ON t.unidad_id = u.unidad_id
    INNER JOIN silabos s ON u.id_silabo = s.id_silabo
    WHERE s.codigo_curso = v_codigo_curso 
    AND s.id_ciclo = v_id_ciclo
    AND s.id_docente = p_id_docente;
    
    -- Insertar o actualizar
    INSERT INTO reporte_docente_curso (
        id_docente, codigo_curso, id_ciclo, grupo_id,
        clases_programadas, clases_dictadas,
        porcentaje_asistencia_docente,
        total_temas, temas_completados,
        porcentaje_avance
    ) VALUES (
        p_id_docente, v_codigo_curso, v_id_ciclo, p_grupo_id,
        COALESCE(v_clases_programadas, 0),
        COALESCE(v_clases_dictadas, 0),
        CASE WHEN v_clases_programadas > 0 
            THEN (v_clases_dictadas * 100.0 / v_clases_programadas) 
            ELSE 0 END,
        COALESCE(v_total_temas, 0),
        COALESCE(v_temas_completados, 0),
        CASE WHEN v_total_temas > 0 
            THEN (v_temas_completados * 100.0 / v_total_temas) 
            ELSE 0 END
    )
    ON DUPLICATE KEY UPDATE
        clases_programadas = VALUES(clases_programadas),
        clases_dictadas = VALUES(clases_dictadas),
        porcentaje_asistencia_docente = VALUES(porcentaje_asistencia_docente),
        total_temas = VALUES(total_temas),
        temas_completados = VALUES(temas_completados),
        porcentaje_avance = VALUES(porcentaje_avance);
END //

-- Procedimiento para actualizar reporte académico completo
CREATE PROCEDURE sp_actualizar_reporte_completo(
    IN p_grupo_id INT
)
BEGIN
    DECLARE v_codigo_curso VARCHAR(20);
    DECLARE v_id_ciclo INT;
    DECLARE v_id_docente INT;
    DECLARE v_total_estudiantes INT;
    DECLARE v_promedio_grupo DECIMAL(5,2);
    DECLARE v_promedio_asistencia DECIMAL(5,2);
    
    -- Obtener datos del grupo
    SELECT gc.codigo_curso, gc.id_ciclo, h.id_docente
    INTO v_codigo_curso, v_id_ciclo, v_id_docente
    FROM grupos_curso gc
    INNER JOIN horarios h ON gc.grupo_id = h.grupo_id
    WHERE gc.grupo_id = p_grupo_id
    LIMIT 1;
    
    -- Contar estudiantes
    SELECT COUNT(*)
    INTO v_total_estudiantes
    FROM matriculas m
    WHERE m.grupo_id = p_grupo_id AND m.estado_matricula = 'ACTIVO';
    
    -- Calcular promedios del grupo
    SELECT 
        AVG(rec.nota_promedio_final),
        AVG(rec.porcentaje_asistencia)
    INTO v_promedio_grupo, v_promedio_asistencia
    FROM reporte_estudiante_curso rec
    WHERE rec.grupo_id = p_grupo_id;
    
    -- Insertar o actualizar reporte completo
    INSERT INTO reporte_academico_completo (
        id_ciclo, codigo_curso, grupo_id, id_docente,
        nombre_curso, letra_grupo, tipo_clase,
        total_estudiantes, promedio_grupo, promedio_asistencia_grupo
    )
    SELECT 
        gc.id_ciclo, gc.codigo_curso, gc.grupo_id, v_id_docente,
        c.nombre_curso, gc.letra_grupo, gc.tipo_clase,
        v_total_estudiantes,
        COALESCE(v_promedio_grupo, 0),
        COALESCE(v_promedio_asistencia, 0)
    FROM grupos_curso gc
    INNER JOIN cursos c ON gc.codigo_curso = c.codigo_curso
    WHERE gc.grupo_id = p_grupo_id
    ON DUPLICATE KEY UPDATE
        total_estudiantes = VALUES(total_estudiantes),
        promedio_grupo = VALUES(promedio_grupo),
        promedio_asistencia_grupo = VALUES(promedio_asistencia_grupo);
END //

DELIMITER ;

-- =====================================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA
-- =====================================================

-- Trigger: Actualizar reporte al registrar asistencia de estudiante
DELIMITER //
CREATE TRIGGER tr_after_insert_asistencia_estudiante
AFTER INSERT ON asistencias_estudiante
FOR EACH ROW
BEGIN
    DECLARE v_cui VARCHAR(20);
    DECLARE v_grupo_id INT;
    
    SELECT m.cui, h.grupo_id 
    INTO v_cui, v_grupo_id
    FROM matriculas m
    INNER JOIN horarios h ON h.id_horario = NEW.id_horario
    WHERE m.id_matricula = NEW.id_matricula;
    
    CALL sp_actualizar_reporte_estudiante_curso(v_cui, v_grupo_id);
    CALL sp_actualizar_reporte_completo(v_grupo_id);
END //

-- Trigger: Actualizar reporte al registrar notas
CREATE TRIGGER tr_after_insert_nota
AFTER INSERT ON notas
FOR EACH ROW
BEGIN
    DECLARE v_cui VARCHAR(20);
    DECLARE v_id_ciclo INT;
    DECLARE v_grupo_id INT;
    
    SELECT m.cui, gc.id_ciclo, m.grupo_id
    INTO v_cui, v_id_ciclo, v_grupo_id
    FROM matriculas m
    INNER JOIN grupos_curso gc ON m.grupo_id = gc.grupo_id
    WHERE m.id_matricula = NEW.id_matricula;
    
    CALL sp_actualizar_notas_reporte(NEW.id_matricula);
    CALL sp_actualizar_rendimiento_estudiante(v_cui, v_id_ciclo);
    CALL sp_actualizar_reporte_completo(v_grupo_id);
END //

CREATE TRIGGER tr_after_update_nota
AFTER UPDATE ON notas
FOR EACH ROW
BEGIN
    DECLARE v_cui VARCHAR(20);
    DECLARE v_id_ciclo INT;
    DECLARE v_grupo_id INT;
    
    SELECT m.cui, gc.id_ciclo, m.grupo_id
    INTO v_cui, v_id_ciclo, v_grupo_id
    FROM matriculas m
    INNER JOIN grupos_curso gc ON m.grupo_id = gc.grupo_id
    WHERE m.id_matricula = NEW.id_matricula;
    
    CALL sp_actualizar_notas_reporte(NEW.id_matricula);
    CALL sp_actualizar_rendimiento_estudiante(v_cui, v_id_ciclo);
    CALL sp_actualizar_reporte_completo(v_grupo_id);
END //

-- Trigger: Actualizar reporte docente al registrar asistencia
CREATE TRIGGER tr_after_insert_asistencia_docente
AFTER INSERT ON asistencias_docente
FOR EACH ROW
BEGIN
    DECLARE v_grupo_id INT;
    
    SELECT h.grupo_id INTO v_grupo_id
    FROM horarios h
    WHERE h.id_horario = NEW.id_horario;
    
    CALL sp_actualizar_reporte_docente(NEW.id_docente, v_grupo_id);
    CALL sp_actualizar_reporte_completo(v_grupo_id);
END //

-- Trigger: Actualizar al completar tema
CREATE TRIGGER tr_after_update_tema
AFTER UPDATE ON temas
FOR EACH ROW
BEGIN
    DECLARE v_id_docente INT;
    DECLARE v_codigo_curso VARCHAR(20);
    DECLARE v_id_ciclo INT;
    DECLARE v_grupo_id INT;
    
    IF NEW.estado = 'COMPLETADO' AND OLD.estado != 'COMPLETADO' THEN
        SELECT s.id_docente, s.codigo_curso, s.id_ciclo
        INTO v_id_docente, v_codigo_curso, v_id_ciclo
        FROM silabos s
        INNER JOIN unidades u ON s.id_silabo = u.id_silabo
        WHERE u.unidad_id = NEW.unidad_id;
        
        -- Buscar grupo_id del docente en este curso
        SELECT h.grupo_id INTO v_grupo_id
        FROM horarios h
        INNER JOIN grupos_curso gc ON h.grupo_id = gc.grupo_id
        WHERE gc.codigo_curso = v_codigo_curso 
        AND gc.id_ciclo = v_id_ciclo
        AND h.id_docente = v_id_docente
        LIMIT 1;
        
        IF v_grupo_id IS NOT NULL THEN
            CALL sp_actualizar_reporte_docente(v_id_docente, v_grupo_id);
            CALL sp_actualizar_reporte_completo(v_grupo_id);
        END IF;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- =====================================================

CREATE INDEX idx_reporte_ec_ciclo ON reporte_estudiante_curso(id_ciclo, porcentaje_asistencia);
CREATE INDEX idx_reporte_re_promedio ON reporte_rendimiento_estudiante(promedio_ponderado DESC);
CREATE INDEX idx_reporte_dc_avance ON reporte_docente_curso(porcentaje_avance, porcentaje_asistencia_docente);
CREATE INDEX idx_reporte_ac_estado ON reporte_academico_completo(estado_curso, promedio_grupo);

-- =====================================================
-- FIN DE SCRIPT
-- =====