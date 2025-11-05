-- DATOS INICIALES DEL SISTEMA

-- tipos de usuario
INSERT INTO tipos_usuario (nombre_tipo, descripcion) VALUES
('ESTUDIANTE', 'Usuario estudiante - Ver horarios, notas, asistencia'),
('DOCENTE', 'Usuario docente - Tomar asistencia, subir notas, sílabos'),
('SECRETARIA', 'Personal de secretaría - Matrículas, reportes'),
('ADMINISTRADOR', 'Administrador del sistema - Gestión completa');

-- tipos de aula
INSERT INTO tipos_aula (nombre_tipo, descripcion) VALUES
('AULA', 'Aula tradicional para clases teóricas - Capacidad 40'),
('LABORATORIO', 'Laboratorio de computación - Capacidad 20');

-- tipos de evaluación
INSERT INTO tipos_evaluacion (codigo, nombre, tipo) VALUES
('EP1', 'Evaluación Parcial 1', 'PARCIAL'),
('EP2', 'Evaluación Parcial 2', 'PARCIAL'),
('EP3', 'Evaluación Parcial 3', 'PARCIAL'),
('EC1', 'Evaluación Continua 1', 'CONTINUA'),
('EC2', 'Evaluación Continua 2', 'CONTINUA'),
('EC3', 'Evaluación Continua 3', 'CONTINUA');

-- ciclo académico activo
INSERT INTO ciclos_academicos (
    nombre_ciclo, anio, semestre, 
    fecha_inicio, fecha_fin,
    fecha_inicio_clases, fecha_fin_clases,
    estado
) VALUES (
    '2025B', 2025, 'B',
    '2025-08-25', '2025-12-19',
    '2025-09-01', '2025-12-12',
    'ACTIVO'
);

-- cursos de ejemplo
INSERT INTO cursos (codigo_curso, nombre_curso, tiene_laboratorio, numero_grupos_teoria, numero_grupos_laboratorio) VALUES
('MAT101', 'Matemática Aplicada la Computación', TRUE, 2, 2),
('ING102', 'Inglés I', FALSE, 2, 0),
('CC201', 'Ciencia de la Computación I', TRUE, 2, 3);

-- salones de ejemplo
INSERT INTO salones (numero_salon, tipo_aula_id, capacidad) VALUES
('101', 1, 40), ('102', 1, 40), ('103', 2, 20),
('201', 1, 40), ('202', 1, 40), ('203', 2, 20),
('204', 2, 20), ('301', 2, 20);

-- grupos de curso con capacidades específicas CORREGIDAS
INSERT INTO grupos_curso (codigo_curso, id_ciclo, letra_grupo, tipo_clase, capacidad_maxima) VALUES
('MAT101', 1, 'A', 'TEORIA', 40),
('MAT101', 1, 'A', 'LABORATORIO', 20),
('MAT101', 1, 'B', 'TEORIA', 40),
('MAT101', 1, 'B', 'LABORATORIO', 20),

('ING102', 1, 'A', 'TEORIA', 40),
('ING102', 1, 'B', 'TEORIA', 40),

('CC201', 1, 'A', 'TEORIA', 40),
('CC201', 1, 'A', 'LABORATORIO', 20),
('CC201', 1, 'B', 'TEORIA', 40),
('CC201', 1, 'B', 'LABORATORIO', 20),
('CC201', 1, 'C', 'LABORATORIO', 20);  -- Grupo extra de laboratorio

-- porcentajes de evaluación para MAT101
INSERT INTO porcentajes_evaluacion (codigo_curso, id_ciclo, tipo_eval_id, porcentaje) 
SELECT 'MAT101', 1, tipo_eval_id, 
    CASE codigo 
        WHEN 'EP1' THEN 12.00
        WHEN 'EP2' THEN 12.00
        WHEN 'EP3' THEN 16.00
        WHEN 'EC1' THEN 18.00
        WHEN 'EC2' THEN 18.00
        WHEN 'EC3' THEN 24.00
    END
FROM tipos_evaluacion;


