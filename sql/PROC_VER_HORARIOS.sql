-- VER HORARIOS PROCEDIMIENTOS ESTUDIANTE Y DOCENTE

USE lumina_bd;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_horarios_docente$$
CREATE PROCEDURE sp_horarios_docente(IN p_id_usuario INT)
BEGIN
  DECLARE v_id_docente INT;

  -- obtener id_docente (puede ser NULL si no existe)
  SET v_id_docente = (SELECT id_docente FROM docentes WHERE id_usuario = p_id_usuario LIMIT 1);

  IF v_id_docente IS NULL THEN
    SELECT CONCAT('Docente no encontrado para id_usuario = ', COALESCE(p_id_usuario,'NULL')) AS mensaje;
  ELSE
    SELECT
      h.id_horario,
      g.grupo_id,
      g.codigo_curso,
      cu.nombre_curso,
      g.letra_grupo,
      g.tipo_clase,
      ca.nombre_ciclo AS ciclo,
      ca.anio,
      ca.semestre,
      h.dia_semana,
      h.hora_inicio,
      h.hora_fin,
      h.numero_salon,
      IFNULL(s.capacidad,'-') AS capacidad_salon,
      d.apellidos_nombres AS docente_nombre,
      h.estado
    FROM horarios h
    JOIN grupos_curso g ON h.grupo_id = g.grupo_id
    JOIN cursos cu ON g.codigo_curso = cu.codigo_curso
    LEFT JOIN salones s ON h.numero_salon = s.numero_salon
    JOIN docentes d ON h.id_docente = d.id_docente
    JOIN ciclos_academicos ca ON g.id_ciclo = ca.id_ciclo
    WHERE h.id_docente = v_id_docente
    ORDER BY FIELD(h.dia_semana,'LUNES','MARTES','MIERCOLES','JUEVES','VIERNES'), h.hora_inicio;
  END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_horarios_estudiante$$
CREATE PROCEDURE sp_horarios_estudiante(IN p_id_usuario INT)
BEGIN
  DECLARE v_cui VARCHAR(20);

  -- obtener cui del estudiante (puede ser NULL si no existe)
  SET v_cui = (SELECT cui FROM estudiantes WHERE id_usuario = p_id_usuario LIMIT 1);

  IF v_cui IS NULL THEN
    SELECT CONCAT('Estudiante no encontrado para id_usuario = ', COALESCE(p_id_usuario,'NULL')) AS mensaje;
  ELSE
    SELECT
      h.id_horario,
      m.id_matricula,
      g.grupo_id,
      g.codigo_curso,
      cu.nombre_curso,
      g.letra_grupo,
      g.tipo_clase,
      ca.nombre_ciclo AS ciclo,
      ca.anio,
      ca.semestre,
      h.dia_semana,
      h.hora_inicio,
      h.hora_fin,
      h.numero_salon,
      IFNULL(d.apellidos_nombres,'-') AS docente_nombre,
      h.estado
    FROM matriculas m
    JOIN grupos_curso g ON m.grupo_id = g.grupo_id
    JOIN horarios h ON h.grupo_id = g.grupo_id
    JOIN cursos cu ON g.codigo_curso = cu.codigo_curso
    LEFT JOIN docentes d ON h.id_docente = d.id_docente
    JOIN ciclos_academicos ca ON g.id_ciclo = ca.id_ciclo
    WHERE m.cui = v_cui
      AND m.estado_matricula = 'ACTIVO'
    ORDER BY FIELD(h.dia_semana,'LUNES','MARTES','MIERCOLES','JUEVES','VIERNES'), h.hora_inicio;
  END IF;
END$$

DELIMITER ;
CALL sp_horarios_docente(2001);
CALL sp_horarios_estudiante(1005);


