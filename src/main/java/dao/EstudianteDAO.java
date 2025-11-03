package dao;

import util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class EstudianteDAO {

    public static class Estudiante {
        public String cui;
        public int idUsuario;
        public String apellidosNombres;
        public String correoInstitucional;
        public int numeroMatricula;
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

}
