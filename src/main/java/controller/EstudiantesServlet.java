package controller;

import com.google.gson.Gson;
import dao.EstudianteDAO;
import dao.EstudianteDAO.Estudiante;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet(name = "EstudiantesServlet", urlPatterns = {"/api/estudiantes", "/api/estudiantes/me"})
public class EstudiantesServlet extends HttpServlet {

    private final EstudianteDAO dao = new EstudianteDAO();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // Ruta solicitada
        String path = req.getRequestURI(); // ej: /home/api/estudiantes o /home/api/estudiantes/me
        // Normalizamos para comparar
        String servletPath = req.getContextPath() + "/api/estudiantes/me";

        resp.setContentType("application/json;charset=UTF-8");
        
        // dentro de doGet, después de obtener 'servletPath' y 'resp.setContentType'
        String servletMePath = req.getContextPath() + "/api/estudiantes/me";
        String servletMeHorariosPath = req.getContextPath() + "/api/estudiantes/me/horarios";

        try {
            if (path.equals(servletPath)) {
                // --- Obtener estudiante actual (requiere sesión) ---
                HttpSession session = req.getSession(false);
                if (session == null || session.getAttribute("usuario") == null) {
                    resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    resp.getWriter().write(gson.toJson(new ErrorResp("No autenticado")));
                    return;
                }

                String correo = (String) session.getAttribute("usuario");
                Estudiante e = dao.obtenerPorCorreo(correo);
                if (e == null) {
                    resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    resp.getWriter().write(gson.toJson(new ErrorResp("Estudiante no encontrado")));
                    return;
                }

                resp.setStatus(HttpServletResponse.SC_OK);
                resp.getWriter().write(gson.toJson(e));
                return;
            }else if(path.equals(servletMeHorariosPath)){
                // --- Obtener horarios del estudiante autenticado ---
                HttpSession session = req.getSession(false);
                if (session == null || session.getAttribute("usuario") == null) {
                    resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    resp.getWriter().write(gson.toJson(new ErrorResp("No autenticado")));
                    return;
                }
                String correo = (String) session.getAttribute("usuario");
                Estudiante e = dao.obtenerPorCorreo(correo);
                if (e == null) {
                    resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    resp.getWriter().write(gson.toJson(new ErrorResp("Estudiante no encontrado")));
                    return;
                }

                List<EstudianteDAO.Horario> horarios = dao.obtenerHorariosPorIdUsuario(e.idUsuario);
                resp.setStatus(HttpServletResponse.SC_OK);
                resp.getWriter().write(gson.toJson(horarios));
                return;
            }else {
                // --- Obtener lista completa de estudiantes ---
                List<Estudiante> lista = dao.obtenerTodos();
                resp.setStatus(HttpServletResponse.SC_OK);
                resp.getWriter().write(gson.toJson(lista));
                return;
            }
        } catch (SQLException ex) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write(gson.toJson(new ErrorResp("Error DB: " + ex.getMessage())));
        }
    }

    // Clase para mensajes de error simples
    private static class ErrorResp {
        String error;
        ErrorResp(String e) { error = e; }
    }
}
