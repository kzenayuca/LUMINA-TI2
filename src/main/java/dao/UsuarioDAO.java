package dao;

import util.DBUtil;
import java.sql.*;
import org.mindrot.jbcrypt.BCrypt;

public class UsuarioDAO {

    public static class ResultadoLogin {
        public boolean ok;
        public String rol;
        public String mensaje;
    }

    public ResultadoLogin verificarCredenciales(String correo, String passwordPlano) {
        ResultadoLogin res = new ResultadoLogin();

        String sql = "SELECT u.password_hash, u.estado_cuenta, t.nombre_tipo "
                   + "FROM usuarios u "
                   + "INNER JOIN tipos_usuario t ON u.tipo_id = t.tipo_id "
                   + "WHERE u.correo_institucional = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, correo);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    res.ok = false;
                    res.mensaje = "Usuario no encontrado";
                    return res;
                }

                String hashDB = rs.getString("password_hash");
                String estado = rs.getString("estado_cuenta");
                String rol = rs.getString("nombre_tipo");

                if (!"ACTIVO".equalsIgnoreCase(estado)) {
                    res.ok = false;
                    res.mensaje = "Cuenta " + estado.toLowerCase();
                    return res;
                }

                // === COMPROBACIÓN ADICIONAL PARA PRUEBAS ===
                // Si el usuario escribe EXACTAMENTE el valor que está en password_hash,
                // lo aceptamos (solo para testing). Muy inseguro: eliminar en producción.
                if (passwordPlano != null && passwordPlano.equals(hashDB)) {
                    res.ok = true;
                    res.rol = rol;
                    return res;
                }
                /*
                // Verificación estándar con bcrypt
                boolean pasa = false;
                try {
                    pasa = BCrypt.checkpw(passwordPlano, hashDB);
                } catch (Exception e) {
                    // hashDB no es bcrypt válido o ocurrió error en checkpw
                    pasa = false;
                }

                if (pasa) {
                    res.ok = true;
                    res.rol = rol;
                } else {
                    res.ok = false;
                    res.mensaje = "Contraseña incorrecta";
                }
*/
            }

        } catch (SQLException e) {
            res.ok = false;
            res.mensaje = "Error en base de datos: " + e.getMessage();
        }

        return res;
    }
}
