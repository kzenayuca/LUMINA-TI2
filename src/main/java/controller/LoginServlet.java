package controller;

import com.google.gson.Gson;
import dao.UsuarioDAO;
import dao.EstudianteDAO;
import dao.UsuarioDAO.ResultadoLogin;
import dao.EstudianteDAO.Estudiante;
import dao.EstudianteDAO.Horario;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;
import java.io.*;
import java.sql.SQLException;
import java.util.List;

@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    private final Gson gson = new Gson();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final EstudianteDAO estudianteDAO = new EstudianteDAO();

    private static class LoginRequest {
        String email;
        String password;
    }

    // Respuesta ampliada: incluye estudiante y horarios opcionalmente
    private static class LoginResponse {
        boolean success;
        String rol;
        String mensaje;
        Estudiante estudiante; // puede ser null
        List<Horario> horarios; // puede ser null o empty
        LoginResponse(boolean s, String r, String m) { success = s; rol = r; mensaje = m; }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Leer JSON del body
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line);
        }

        LoginRequest loginReq = gson.fromJson(sb.toString(), LoginRequest.class);
        ResultadoLogin resultado = usuarioDAO.verificarCredenciales(loginReq.email, loginReq.password);
        
        System.out.println(loginReq.email);
        System.out.println(loginReq.password);

        resp.setContentType("application/json;charset=UTF-8");

        if (resultado.ok) {
            HttpSession session = req.getSession(true);
            session.setAttribute("usuario", loginReq.email);
            session.setAttribute("rol", resultado.rol);

            LoginResponse lr = new LoginResponse(true, resultado.rol, "Login exitoso");

            try {
                // Si es estudiante, intentar traer info y horarios
                String rolLower = (resultado.rol == null) ? "" : resultado.rol.toLowerCase();
                if (rolLower.contains("estudiante") || rolLower.equals("estudiante")) {
                    Estudiante e = estudianteDAO.obtenerPorCorreo(loginReq.email);
                    lr.estudiante = e;
                    if (e != null) {
                        List<Horario> horarios = estudianteDAO.obtenerHorariosPorIdUsuario(e.idUsuario);
                        lr.horarios = horarios;
                        // opcional: guardar en session para uso server-side
                        session.setAttribute("estudiante", e);
                        session.setAttribute("horarios", horarios);
                    } else {
                        lr.horarios = java.util.Collections.emptyList();
                    }
                } else {
                    // no es estudiante -> no devolvemos horarios
                    lr.estudiante = null;
                    lr.horarios = java.util.Collections.emptyList();
                }
            } catch (SQLException ex) {
                // En caso de error DB al obtener estudiante/horarios, devolvemos empty y registramos
                lr.estudiante = null;
                lr.horarios = java.util.Collections.emptyList();
                // log (si tienes logger) o print
                ex.printStackTrace();
            }

            resp.setStatus(HttpServletResponse.SC_OK);
            resp.getWriter().write(gson.toJson(lr));
        } else {
            LoginResponse lr = new LoginResponse(false, null, resultado.mensaje);
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            resp.getWriter().write(gson.toJson(lr));
        }
    }
}
