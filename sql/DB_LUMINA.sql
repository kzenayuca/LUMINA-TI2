-- BASE DE DATOS LUMINA 

DROP DATABASE IF EXISTS lumina_bd;
CREATE DATABASE lumina_bd CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lumina_bd;

-- TABLA1 CICLOS ACADÉMICOS
CREATE TABLE ciclos_academicos (
    id_ciclo INT AUTO_INCREMENT PRIMARY KEY,
    nombre_ciclo VARCHAR(10) NOT NULL UNIQUE, -- '2025B'
    anio INT NOT NULL,
    semestre CHAR(1) NOT NULL, -- A o B
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_inicio_clases DATE NOT NULL, -- 1ra clase
    fecha_fin_clases DATE NOT NULL,-- última clase
    fecha_inicio_examenes DATE NULL,
    fecha_fin_examenes DATE NULL,
    estado ENUM('ACTIVO', 'INACTIVO', 'PLANIFICADO') DEFAULT 'PLANIFICADO',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_ciclo (anio, semestre),
    INDEX idx_activo (estado),
    INDEX idx_fechas (fecha_inicio, fecha_fin)
) ENGINE=InnoDB;

-- TABLA2 USUARIOS 
CREATE TABLE tipos_usuario (
    tipo_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_tipo ENUM('ESTUDIANTE', 'DOCENTE', 'SECRETARIA', 'ADMINISTRADOR') NOT NULL,
    descripcion TEXT,
    permisos JSON
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    correo_institucional VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- contraseña encriptada
    salt VARCHAR(100) NOT NULL, -- seguridad
    tipo_id INT NOT NULL, -- rol 
    estado_cuenta ENUM('ACTIVO', 'BLOQUEADO', 'ELIMINADO') DEFAULT 'ACTIVO',
    primer_acceso BOOLEAN DEFAULT TRUE, -- cambio de contraseña
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_ultimo_acceso DATETIME NULL,
    ip_ultimo_acceso VARCHAR(45) NULL,
    FOREIGN KEY (tipo_id) REFERENCES tipos_usuario(tipo_id),
    INDEX idx_correo (correo_institucional),
    INDEX idx_tipo (tipo_id),
    INDEX idx_estado (estado_cuenta)
) ENGINE=InnoDB;

CREATE TABLE estudiantes (
    cui VARCHAR(20) PRIMARY KEY,
    id_usuario INT UNIQUE NOT NULL,
    apellidos_nombres VARCHAR(150) NOT NULL,
    numero_matricula INT NOT NULL,
    estado_estudiante ENUM('VIGENTE', 'RETIRADO', 'EGRESADO') DEFAULT 'VIGENTE',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    INDEX idx_estado (estado_estudiante)
) ENGINE=InnoDB;

CREATE TABLE docentes (
    id_docente INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNIQUE NOT NULL,
    apellidos_nombres VARCHAR(150) NOT NULL,
    departamento VARCHAR(100) NOT NULL,
    es_responsable_teoria BOOLEAN DEFAULT FALSE, 
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    INDEX idx_departamento (departamento)
) ENGINE=InnoDB;

-- Add Administrador y Secretaria
CREATE TABLE administrador (
    id_admin INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNIQUE NOT NULL,
    apellidos_nombres VARCHAR(150) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE secretaria (
    id_secr INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNIQUE NOT NULL,
    apellidos_nombres VARCHAR(150) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;


-- TABLA6 SESIONES 
CREATE TABLE sesiones (
    id_sesion INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    token_sesion VARCHAR(255) UNIQUE NOT NULL, -- JSON Web Tokens
    ip_sesion VARCHAR(45) NOT NULL,
    fecha_inicio DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion DATETIME NOT NULL,
    activo BOOLEAN DEFAULT TRUE, -- estado de sesión
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    INDEX idx_token (token_sesion),
    INDEX idx_usuario_activo (id_usuario, activo),
    INDEX idx_expiracion (fecha_expiracion)
) ENGINE=InnoDB;

-- TABLA7 ACADÉMICAS 
CREATE TABLE cursos (
    codigo_curso VARCHAR(20) PRIMARY KEY,
    nombre_curso VARCHAR(200) NOT NULL,
    tiene_laboratorio BOOLEAN DEFAULT FALSE,
    numero_grupos_teoria INT DEFAULT 2,
    numero_grupos_laboratorio INT DEFAULT 0,
    estado ENUM('ACTIVO', 'INACTIVO') DEFAULT 'ACTIVO',
    INDEX idx_nombre (nombre_curso),
    INDEX idx_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE tipos_evaluacion (
    tipo_eval_id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE, 
    nombre VARCHAR(50) NOT NULL,
    tipo ENUM('PARCIAL', 'CONTINUA') NOT NULL,
    INDEX idx_codigo (codigo)
) ENGINE=InnoDB;

CREATE TABLE porcentajes_evaluacion (
    id_porcentaje INT AUTO_INCREMENT PRIMARY KEY,
    codigo_curso VARCHAR(20) NOT NULL,
    id_ciclo INT NOT NULL,
    tipo_eval_id INT NOT NULL,
    porcentaje DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (codigo_curso) REFERENCES cursos(codigo_curso) ON DELETE CASCADE,
    FOREIGN KEY (id_ciclo) REFERENCES ciclos_academicos(id_ciclo) ON DELETE CASCADE,
    FOREIGN KEY (tipo_eval_id) REFERENCES tipos_evaluacion(tipo_eval_id),
    UNIQUE KEY uk_curso_ciclo_evaluacion (codigo_curso, id_ciclo, tipo_eval_id),
    INDEX idx_curso_ciclo (codigo_curso, id_ciclo)
) ENGINE=InnoDB;

-- TABLA10 SALONES Y HORARIOS 
CREATE TABLE tipos_aula (
    tipo_aula_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_tipo ENUM('AULA', 'LABORATORIO') NOT NULL,
    descripcion TEXT,
    INDEX idx_nombre (nombre_tipo)
) ENGINE=InnoDB;

CREATE TABLE salones (
    numero_salon VARCHAR(10) PRIMARY KEY,
    tipo_aula_id INT NOT NULL,
    capacidad INT NOT NULL,
    estado ENUM('DISPONIBLE', 'OCUPADA', 'MANTENIMIENTO') DEFAULT 'DISPONIBLE',
    FOREIGN KEY (tipo_aula_id) REFERENCES tipos_aula(tipo_aula_id),
    INDEX idx_tipo (tipo_aula_id),
    INDEX idx_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE grupos_curso (
    grupo_id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_curso VARCHAR(20) NOT NULL,
    id_ciclo INT NOT NULL,
    letra_grupo CHAR(1) NOT NULL, -- A,B
    tipo_clase ENUM('TEORIA', 'LABORATORIO') NOT NULL,
    capacidad_maxima INT NOT NULL,
    estado ENUM('ACTIVO', 'CERRADO') DEFAULT 'ACTIVO',
    FOREIGN KEY (codigo_curso) REFERENCES cursos(codigo_curso) ON DELETE CASCADE,
    FOREIGN KEY (id_ciclo) REFERENCES ciclos_academicos(id_ciclo) ON DELETE CASCADE,
    UNIQUE KEY uk_grupo_curso (codigo_curso, id_ciclo, letra_grupo, tipo_clase),
    INDEX idx_curso_ciclo (codigo_curso, id_ciclo),
    INDEX idx_tipo_clase (tipo_clase)
) ENGINE=InnoDB;

CREATE TABLE horarios (
    id_horario INT AUTO_INCREMENT PRIMARY KEY,
    grupo_id INT NOT NULL,
    numero_salon VARCHAR(10) NOT NULL,
    dia_semana ENUM('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES') NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    id_docente INT NOT NULL,
    estado ENUM('ACTIVO', 'SUSPENDIDO') DEFAULT 'ACTIVO',
    FOREIGN KEY (grupo_id) REFERENCES grupos_curso(grupo_id) ON DELETE CASCADE,
    FOREIGN KEY (numero_salon) REFERENCES salones(numero_salon),
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    INDEX idx_salon_dia (numero_salon, dia_semana),
    INDEX idx_docente_dia (id_docente, dia_semana),
    INDEX idx_dia_hora (dia_semana, hora_inicio)
) ENGINE=InnoDB;

-- TABLA14 MATRÍCULA 
CREATE TABLE matriculas (
    id_matricula INT AUTO_INCREMENT PRIMARY KEY,
    cui VARCHAR(20) NOT NULL,
    grupo_id INT NOT NULL,
    numero_matricula INT,
    prioridad_matricula BOOLEAN DEFAULT FALSE, -- evitar cruce
    estado_matricula ENUM('ACTIVO', 'RETIRADO', 'ABANDONADO') DEFAULT 'ACTIVO',
    fecha_matricula TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cui) REFERENCES estudiantes(cui) ON DELETE CASCADE,
    FOREIGN KEY (grupo_id) REFERENCES grupos_curso(grupo_id) ON DELETE CASCADE,
    UNIQUE KEY uk_estudiante_grupo (cui, grupo_id),
    INDEX idx_estado (estado_matricula),
    INDEX idx_grupo (grupo_id)
) ENGINE=InnoDB;

-- TABLA15 SÍLABO Y TEMARIO 
CREATE TABLE silabos (
    id_silabo INT AUTO_INCREMENT PRIMARY KEY,
    codigo_curso VARCHAR(20) NOT NULL,
    id_ciclo INT NOT NULL,
    grupo_teoria CHAR(1) NOT NULL,
    ruta_archivo VARCHAR(500) NOT NULL,
    id_docente INT NOT NULL,
    fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('PENDIENTE', 'APROBADO') DEFAULT 'PENDIENTE',
    FOREIGN KEY (codigo_curso) REFERENCES cursos(codigo_curso) ON DELETE CASCADE,
    FOREIGN KEY (id_ciclo) REFERENCES ciclos_academicos(id_ciclo) ON DELETE CASCADE,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    UNIQUE KEY uk_curso_ciclo_grupo (codigo_curso, id_ciclo, grupo_teoria),
    INDEX idx_docente (id_docente)
) ENGINE=InnoDB;

CREATE TABLE unidades (
    unidad_id INT AUTO_INCREMENT PRIMARY KEY,
    id_silabo INT NOT NULL,
    numero_unidad INT NOT NULL,
    nombre_unidad VARCHAR(200) NOT NULL,
    descripcion TEXT,
    FOREIGN KEY (id_silabo) REFERENCES silabos(id_silabo) ON DELETE CASCADE,
    INDEX idx_silabo_unidad (id_silabo, numero_unidad)
) ENGINE=InnoDB;

CREATE TABLE temas (
    id_tema INT AUTO_INCREMENT PRIMARY KEY,
    unidad_id INT NOT NULL,
    numero_tema INT NOT NULL,
    nombre_tema VARCHAR(300) NOT NULL,
    duracion_estimada INT,
    estado ENUM('PENDIENTE', 'EN_CURSO', 'COMPLETADO') DEFAULT 'PENDIENTE',
    fecha_completado DATE NULL,
    FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id) ON DELETE CASCADE,
    INDEX idx_unidad_numero (unidad_id, numero_tema)
) ENGINE=InnoDB;

-- TABLA18 ASISTENCIA 
CREATE TABLE control_asistencia (
    id_control INT AUTO_INCREMENT PRIMARY KEY,
    id_horario INT NOT NULL,
    fecha DATE NOT NULL,
    hora_apertura TIME NOT NULL,
    hora_cierre TIME NOT NULL,
    estado ENUM('ABIERTO', 'CERRADO') DEFAULT 'ABIERTO',
    FOREIGN KEY (id_horario) REFERENCES horarios(id_horario) ON DELETE CASCADE,
    UNIQUE KEY uk_horario_fecha (id_horario, fecha),
    INDEX idx_fecha_estado (fecha, estado)
) ENGINE=InnoDB;

CREATE TABLE asistencias_docente (
    id_asistencia_docente INT AUTO_INCREMENT PRIMARY KEY,
    id_horario INT NOT NULL,
    id_docente INT NOT NULL,
    fecha DATE NOT NULL,
    hora_registro TIME NOT NULL,
    ip_registro VARCHAR(45) NOT NULL,
    tipo_ubicacion ENUM('PRESENCIAL', 'VIRTUAL') NOT NULL,
    presente BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_horario) REFERENCES horarios(id_horario) ON DELETE CASCADE,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    UNIQUE KEY uk_docente_horario_fecha (id_docente, id_horario, fecha),
    INDEX idx_fecha_horario (fecha, id_horario)
) ENGINE=InnoDB;

CREATE TABLE asistencias_estudiante (
    id_asistencia INT AUTO_INCREMENT PRIMARY KEY,
    id_matricula INT NOT NULL,
    id_horario INT NOT NULL,
    fecha DATE NOT NULL,
    estado_asistencia ENUM('PRESENTE', 'FALTA') NOT NULL,
    registrado_por INT NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_matricula) REFERENCES matriculas(id_matricula) ON DELETE CASCADE,
    FOREIGN KEY (id_horario) REFERENCES horarios(id_horario) ON DELETE CASCADE,
    FOREIGN KEY (registrado_por) REFERENCES docentes(id_docente),
    UNIQUE KEY uk_matricula_horario_fecha (id_matricula, id_horario, fecha),
    INDEX idx_fecha_horario (fecha, id_horario)
) ENGINE=InnoDB;

-- TABLA21 NOTAS 
CREATE TABLE notas (
    id_nota INT AUTO_INCREMENT PRIMARY KEY,
    id_matricula INT NOT NULL,
    tipo_eval_id INT NOT NULL,
    calificacion DECIMAL(5,2) CHECK (calificacion >= 0 AND calificacion <= 20),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    docente_registro_id INT,
    FOREIGN KEY (id_matricula) REFERENCES matriculas(id_matricula) ON DELETE CASCADE,
    FOREIGN KEY (tipo_eval_id) REFERENCES tipos_evaluacion(tipo_eval_id),
    FOREIGN KEY (docente_registro_id) REFERENCES docentes(id_docente),
    UNIQUE KEY uk_matricula_evaluacion (id_matricula, tipo_eval_id),
    INDEX idx_matricula (id_matricula),
    INDEX idx_tipo_eval (tipo_eval_id)
) ENGINE=InnoDB;

-- TABLA22 RESERVAS
CREATE TABLE reservas_salon (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    numero_salon VARCHAR(10) NOT NULL,
    id_docente INT NOT NULL,
    dia_semana ENUM('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES') NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    fecha_reserva DATE NOT NULL,
    estado_reserva ENUM('PENDIENTE', 'CONFIRMADA', 'CANCELADA') DEFAULT 'PENDIENTE',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (numero_salon) REFERENCES salones(numero_salon),
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    INDEX idx_salon_fecha (numero_salon, fecha_reserva),
    INDEX idx_docente_fecha (id_docente, fecha_reserva),
    INDEX idx_estado (estado_reserva)
) ENGINE=InnoDB;

-- TABLA23 REPORTES Y LOGS
CREATE TABLE reportes_generados (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,
    tipo_reporte ENUM('ASISTENCIA_NOTAS', 'RENDIMIENTO', 'ACADEMICO_COMPLETO') NOT NULL,
    generado_por INT NOT NULL,
    tipo_usuario VARCHAR(20) NOT NULL,
    codigo_curso VARCHAR(20) NULL,
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ruta_archivo VARCHAR(500) NULL,
    FOREIGN KEY (generado_por) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (codigo_curso) REFERENCES cursos(codigo_curso) ON DELETE SET NULL,
    INDEX idx_fecha (fecha_generacion),
    INDEX idx_tipo (tipo_reporte)
) ENGINE=InnoDB;

CREATE TABLE log_actividades (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    accion VARCHAR(200) NOT NULL,
    tabla_afectada VARCHAR(100) NULL,
    descripcion TEXT NULL,
    ip_origen VARCHAR(45) NULL,
    fecha_accion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    INDEX idx_usuario_fecha (id_usuario, fecha_accion),
    INDEX idx_tabla (tabla_afectada),
    INDEX idx_fecha (fecha_accion)
) ENGINE=InnoDB;


-- NUEVAS TABLAS A NECESIDAD 04/11/2025

-- RELACION MUCHOS A MUCHOS
CREATE TABLE estudiante_horario(
	cui_est VARCHAR(20),
    id_horario INT,
    PRIMARY KEY (cui_est, id_horario),
    FOREIGN KEY (cui_est) REFERENCES estudiantes(cui),
    FOREIGN KEY (id_horario) REFERENCES horarios(id_horario)
);


