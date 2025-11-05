DELIMITER $$

DROP PROCEDURE IF EXISTS notas_estudiante $$
CREATE PROCEDURE notas_estudiante(IN p_cui VARCHAR(20))
BEGIN
    /*
      Devuelve:
       - nombre_curso
       - codigo_curso
       - docente_del_curso (puede ser varios, concatenados)
       - tipo_evaluacion (nombre del tipo)
       - nota (calificacion)
       - porcentaje (porcentaje del tipo de evaluación para ese curso y ciclo)
       - fecha_registro (de la nota)
    */

    SELECT
        c.nombre_curso AS nombre_curso,
        c.codigo_curso AS codigo_curso,
        -- Si hay varios horarios/docentes para ese grupo los concatenamos (evita duplicados)
        TRIM(BOTH '; ' FROM GROUP_CONCAT(DISTINCT d.apellidos_nombres SEPARATOR '; ')) AS docente_del_curso,
        te.nombre AS tipo_evaluacion,
        n.calificacion AS nota,
        COALESCE(pe.porcentaje, 0) AS porcentaje,
        n.fecha_registro AS fecha_registro
    FROM notas n
    INNER JOIN matriculas m ON n.id_matricula = m.id_matricula
    INNER JOIN grupos_curso g ON m.grupo_id = g.grupo_id
    INNER JOIN cursos c ON g.codigo_curso = c.codigo_curso
    LEFT JOIN porcentajes_evaluacion pe 
        ON pe.codigo_curso = c.codigo_curso
       AND pe.id_ciclo = g.id_ciclo
       AND pe.tipo_eval_id = n.tipo_eval_id
    LEFT JOIN tipos_evaluacion te ON n.tipo_eval_id = te.tipo_eval_id
    -- Unimos horarios y docentes para obtener el/los docentes que imparten ese grupo
    LEFT JOIN horarios h ON h.grupo_id = g.grupo_id
    LEFT JOIN docentes d ON h.id_docente = d.id_docente
    WHERE m.cui = p_cui
    GROUP BY
        n.id_nota,       -- agrupar por nota (clave primaria)
        c.nombre_curso,
        c.codigo_curso,
        te.nombre,
        n.calificacion,
        pe.porcentaje,
        n.fecha_registro
    ORDER BY n.fecha_registro DESC;
END $$
DELIMITER ;

CALL notas_estudiante('CUI2025005');  -- sustituye '20001234' por el CUI real del estudiante

