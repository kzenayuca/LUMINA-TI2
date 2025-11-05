USE lumina_bd;

DELIMITER $$

-- USUARIOS
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    correo_institucional VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(100),
    tipo_id INT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)$$

-- RESERVAS DE SALONES
CREATE TABLE IF NOT EXISTS reservas_salon (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    salon_id INT NOT NULL,
    docente_id INT NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL
)$$

-- CONTROL DE ASISTENCIA
CREATE TABLE IF NOT EXISTS control_asistencia (
    id_control INT AUTO_INCREMENT PRIMARY KEY,
    id_horario INT NOT NULL,
    fecha DATE NOT NULL,
    hora_apertura TIME,
    hora_cierre TIME,
    estado ENUM('ABIERTA', 'CERRADA') DEFAULT 'ABIERTA'
)$$

-- LOG DE ACCIONES
CREATE TABLE IF NOT EXISTS log_acciones (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)$$

-- REGISTRAR ESTUDIANTE
DROP PROCEDURE IF EXISTS registrar_docente$$
CREATE PROCEDURE registrar_docente(
    IN p_correo VARCHAR(150),
    IN p_password VARCHAR(255),
    IN p_tipo_id INT,
    IN p_departamento VARCHAR(100)
)
BEGIN
    -- Declarar variables primero
    DECLARE v_usuario_id INT;

    -- Insertar usuario primero
    INSERT INTO usuarios (correo_institucional, password_hash, tipo_id)
    VALUES (p_correo, p_password, p_tipo_id);

    -- Obtener el ID del usuario recién creado
    SET v_usuario_id = LAST_INSERT_ID();

    -- Insertar docente asociado al usuario
    INSERT INTO docentes (usuario_id, departamento, fecha_registro)
    VALUES (v_usuario_id, p_departamento, NOW());
END$$


-- VER ESTUDIANTES
DROP PROCEDURE IF EXISTS ver_estudiantes$$
CREATE PROCEDURE ver_estudiantes()
BEGIN
    SELECT 
        e.id_estudiante,
        u.correo_institucional,
        e.student_code,
        e.career,
        e.fecha_creacion
    FROM estudiantes e
    INNER JOIN usuarios u ON e.usuario_id = u.id_usuario;
END$$

-- ELIMINAR ESTUDIANTE
DROP PROCEDURE IF EXISTS eliminar_estudiante$$
CREATE PROCEDURE eliminar_estudiante(IN p_estudiante_id INT)
BEGIN
    DECLARE v_usuario_id INT;
    SELECT usuario_id INTO v_usuario_id FROM estudiantes WHERE id_estudiante = p_estudiante_id;

    DELETE FROM estudiantes WHERE id_estudiante = p_estudiante_id;
    DELETE FROM usuarios WHERE id_usuario = v_usuario_id;
END$$

-- REGISTRAR CICLO ACADÉMICO
DROP PROCEDURE IF EXISTS registrar_ciclo$$
CREATE PROCEDURE registrar_ciclo(IN p_nombre_ciclo VARCHAR(10), IN p_anio INT)
BEGIN
    INSERT INTO ciclos_academicos (nombre_ciclo, anio, fecha_creacion)
    VALUES (p_nombre_ciclo, p_anio, NOW());
END$$

-- VER CICLOS ACADÉMICOS
DROP PROCEDURE IF EXISTS ver_ciclos$$
CREATE PROCEDURE ver_ciclos()
BEGIN
    SELECT id_ciclo, nombre_ciclo, anio, fecha_creacion
    FROM ciclos_academicos;
END$$

-- ACTUALIZAR CICLO ACADÉMICO
DROP PROCEDURE IF EXISTS actualizar_ciclo$$
CREATE PROCEDURE actualizar_ciclo(
    IN p_id_ciclo INT,
    IN p_nuevo_nombre VARCHAR(10),
    IN p_nuevo_anio INT
)
BEGIN
    UPDATE ciclos_academicos
    SET nombre_ciclo = p_nuevo_nombre,
        anio = p_nuevo_anio
    WHERE id_ciclo = p_id_ciclo;
END$$

-- ELIMINAR CICLO ACADÉMICO
DROP PROCEDURE IF EXISTS eliminar_ciclo$$
CREATE PROCEDURE eliminar_ciclo(IN p_id_ciclo INT)
BEGIN
    DELETE FROM ciclos_academicos WHERE id_ciclo = p_id_ciclo;
END$$

-- REGISTRAR MATRÍCULA
DROP PROCEDURE IF EXISTS registrar_matricula$$
CREATE PROCEDURE registrar_matricula(
    IN p_id_estudiante INT,
    IN p_id_ciclo INT
)
BEGIN
    INSERT INTO matriculas (id_estudiante, id_ciclo, fecha_matricula)
    VALUES (p_id_estudiante, p_id_ciclo, NOW());
END$$

-- VER MATRÍCULAS
DROP PROCEDURE IF EXISTS ver_matriculas$$
CREATE PROCEDURE ver_matriculas()
BEGIN
    SELECT 
        m.id_matricula,
        e.student_code,
        u.correo_institucional,
        c.nombre_ciclo,
        m.fecha_matricula
    FROM matriculas m
    INNER JOIN estudiantes e ON m.id_estudiante = e.id_estudiante
    INNER JOIN usuarios u ON e.usuario_id = u.id_usuario
    INNER JOIN ciclos_academicos c ON m.id_ciclo = c.id_ciclo;
END$$

-- REGISTRAR DOCENTE
DROP PROCEDURE IF EXISTS registrar_docente$$
CREATE PROCEDURE registrar_docente(
    IN p_correo VARCHAR(150),
    IN p_password VARCHAR(255),
    IN p_tipo_id INT,
    IN p_departamento VARCHAR(100)
)
BEGIN
    -- Declaración de variables al inicio
    DECLARE v_usuario_id INT;

    -- Insertar usuario
    INSERT INTO usuarios (correo_institucional, password_hash, tipo_id)
    VALUES (p_correo, p_password, p_tipo_id);

    -- Obtener el ID del usuario recién creado
    SET v_usuario_id = LAST_INSERT_ID();

    -- Insertar docente asociado
    INSERT INTO docentes (usuario_id, departamento, fecha_registro)
    VALUES (v_usuario_id, p_departamento, NOW());
END$$


-- VER DOCENTES
DROP PROCEDURE IF EXISTS ver_docentes$$
CREATE PROCEDURE ver_docentes()
BEGIN
    SELECT 
        d.id_docente,
        u.correo_institucional,
        d.departamento,
        d.fecha_registro
    FROM docentes d
    INNER JOIN usuarios u ON d.usuario_id = u.id_usuario;
END$$

-- REGISTRAR ASISTENCIA DOCENTE
DROP PROCEDURE IF EXISTS registrar_asistencia_docente$$
CREATE PROCEDURE registrar_asistencia_docente(
    IN p_docente_id INT,
    IN p_curso_id INT,
    IN p_fecha DATE,
    IN p_estado ENUM('PRESENTE','FALTA')
)
BEGIN
    INSERT INTO asistencias_docente (docente_id, curso_id, fecha, estado)
    VALUES (p_docente_id, p_curso_id, p_fecha, p_estado);
END$$

-- REGISTRAR NOTA
DROP PROCEDURE IF EXISTS registrar_nota$$
CREATE PROCEDURE registrar_nota(
    IN p_id_matricula INT,
    IN p_tipo_eval_id INT,
    IN p_calificacion DECIMAL(5,2),
    IN p_docente_id INT
)
BEGIN
    INSERT INTO notas (id_matricula, tipo_eval_id, calificacion, docente_registro_id)
    VALUES (p_id_matricula, p_tipo_eval_id, p_calificacion, p_docente_id);
END$$

-- VER NOTAS DE ESTUDIANTE
DROP PROCEDURE IF EXISTS ver_notas_estudiante$$
CREATE PROCEDURE ver_notas_estudiante(IN p_id_estudiante INT)
BEGIN
    SELECT 
        n.id_nota,
        n.calificacion,
        t.nombre_tipo_eval,
        c.nombre_curso,
        n.fecha_registro
    FROM notas n
    INNER JOIN matriculas m ON n.id_matricula = m.id_matricula
    INNER JOIN tipos_evaluacion t ON n.tipo_eval_id = t.tipo_eval_id
    INNER JOIN cursos c ON m.id_curso = c.id_curso
    WHERE m.id_estudiante = p_id_estudiante;
END$$

-- LOG INSERT ESTUDIANTE

-- Trigger para registrar acción al insertar un estudiante
DROP TRIGGER IF EXISTS trg_log_insert_estudiante$$
CREATE TRIGGER trg_log_insert_estudiante
AFTER INSERT ON estudiantes
FOR EACH ROW
BEGIN
    INSERT INTO log_acciones (descripcion)
    VALUES (CONCAT('Se registró un nuevo estudiante con ID de usuario ', NEW.id_usuario));
END$$


-- LOG INSERT MATRÍCULA


DROP TRIGGER IF EXISTS trg_actualizar_fecha_usuario$$
CREATE TRIGGER trg_actualizar_fecha_usuario
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

DELIMITER ;


