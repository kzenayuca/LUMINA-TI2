package dao;

import util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import java.sql.Time;
import java.util.HashMap;
import java.util.Map;
import com.google.gson.annotations.SerializedName;

public class EstudianteDAO {

    public static class Estudiante {
        public String cui;
        public int idUsuario;
        public String apellidosNombres;
        public String correoInstitucional;
        public int numeroMatricula;
    }
    
    public static class Horario {
        public int id_horario;
        public int id_matricula;
        public int grupo_id;
        public String codigo_curso;
        public String nombre_curso;
        public String letra_grupo;
        public String tipo_clase;
        public String ciclo;
        public int anio;
        public String semestre;
        public String dia_semana;
        public String hora_inicio; // formato esperado HH:MM:SS o HH:MM
        public String hora_fin;
        public String numero_salon;
        public String docente_nombre;
        public String estado;
    }

    // Devuelve lista de estudiantes (puedes ampliar para filtrar por curso)
    public List<Estudiante> obtenerTodos() throws SQLException {
        List<Estudiante> lista = new ArrayList<>();
        String sql = "SELECT e.cui, e.id_usuario, e.apellidos_nombres, e.numero_matricula, u.correo_institucional "
                   + "FROM estudiantes e "
                   + "INNER JOIN usuarios u ON e.id_usuario = u.id_usuario "
                   + "WHERE u.estado_cuenta = 'ACTIVO' "
                   + "ORDER BY e.apellidos_nombres";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Estudiante e = new Estudiante();
                e.cui = rs.getString("cui");
                e.idUsuario = rs.getInt("id_usuario");
                e.apellidosNombres = rs.getString("apellidos_nombres");
                e.numeroMatricula = rs.getInt("numero_matricula");
                e.correoInstitucional = rs.getString("correo_institucional");
                lista.add(e);
            }
        }
        return lista;
    }
    
    // dentro de dao/EstudianteDAO.java (añadir al final de la clase)
    public Estudiante obtenerPorCorreo(String correo) throws SQLException {
        String sql = "SELECT e.cui, e.id_usuario, e.apellidos_nombres, e.numero_matricula, u.correo_institucional "
                + "FROM estudiantes e "
                + "INNER JOIN usuarios u ON e.id_usuario = u.id_usuario "
                + "WHERE u.estado_cuenta = 'ACTIVO' AND u.correo_institucional = ?";

        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, correo);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Estudiante e = new Estudiante();
                    e.cui = rs.getString("cui");
                    e.idUsuario = rs.getInt("id_usuario");
                    e.apellidosNombres = rs.getString("apellidos_nombres");
                    e.numeroMatricula = rs.getInt("numero_matricula");
                    e.correoInstitucional = rs.getString("correo_institucional");
                    return e;
                } else {
                    return null;
                }
            }
        }
    }
    
    public List<Horario> obtenerHorariosPorIdUsuario(int idUsuario) throws SQLException {
        List<Horario> lista = new ArrayList<>();
        String call = "{CALL sp_horarios_estudiante(?)}";
        // Primero obtenemos el CUI interno: el procedimiento ya lo hace vía id_usuario, así que sólo pasamos idUsuario.
        try (Connection conn = DBUtil.getConnection();
             CallableStatement cs = conn.prepareCall(call)) {

            cs.setInt(1, idUsuario);
            boolean hasRs = cs.execute();
            if (!hasRs) {
                return lista;
            }
            try (ResultSet rs = cs.getResultSet()) {
                while (rs.next()) {
                    // Si el procedimiento devolviera el mensaje de "Estudiante no encontrado", la primera columna sería 'mensaje'
                    // Detectamos y salimos si vemos esa columna llamada 'mensaje'
                    ResultSetMetaData md = rs.getMetaData();
                    boolean hasMensaje = false;
                    for (int i = 1; i <= md.getColumnCount(); i++) {
                        if ("mensaje".equalsIgnoreCase(md.getColumnName(i))) {
                            hasMensaje = true;
                            break;
                        }
                    }
                    if (hasMensaje) {
                        // No hay horarios; rompemos (la lista queda vacía)
                        break;
                    }

                    Horario h = new Horario();
                    h.id_horario = rs.getInt("id_horario");
                    h.id_matricula = rs.getInt("id_matricula");
                    h.grupo_id = rs.getInt("grupo_id");
                    h.codigo_curso = rs.getString("codigo_curso");
                    h.nombre_curso = rs.getString("nombre_curso");
                    h.letra_grupo = rs.getString("letra_grupo");
                    h.tipo_clase = rs.getString("tipo_clase");
                    h.ciclo = rs.getString("ciclo");
                    // si tus columnas son anio/semestre distintas, usa rs.getInt / getString conforme corresponda
                    try { h.anio = rs.getInt("anio"); } catch (SQLException ex) { h.anio = 0; }
                    try { h.semestre = rs.getString("semestre"); } catch (SQLException ex) { h.semestre = ""; }
                    h.dia_semana = rs.getString("dia_semana");
                    h.hora_inicio = rs.getString("hora_inicio");
                    h.hora_fin = rs.getString("hora_fin");
                    h.numero_salon = rs.getString("numero_salon");
                    h.docente_nombre = rs.getString("docente_nombre");
                    h.estado = rs.getString("estado");
                    lista.add(h);
                }
            }
        }
        return lista;
    }

}
