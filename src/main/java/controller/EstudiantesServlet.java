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

@WebServlet(name = "EstudiantesServlet", urlPatterns = {"/api/estudiantes/*"})
public class EstudiantesServlet extends HttpServlet {

    private final EstudianteDAO dao = new EstudianteDAO();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // pathInfo: null o "/" o "/me" o "/notas" o "/me/horarios"
        String path = req.getPathInfo();
        if (path == null) path = "/";

        resp.setContentType("application/json;charset=UTF-8");

        try {
            switch (path) {
                case "/":
                case "":
                    // GET /api/estudiantes  -> listar todos los estudiantes
                    handleListAll(req, resp);
                    break;

                case "/me":
                    // GET /api/estudiantes/me -> devolver estudiante autenticado
                    handleGetMe(req, resp);
                    break;

                case "/notas":
                    // GET /api/estudiantes/notas?cui=...
                    handleGetNotas(req, resp);
                    break;

                case "/me/horarios":
                    // GET /api/estudiantes/me/horarios -> horarios del estudiante autenticado
                    handleGetMeHorarios(req, resp);
                    break;

                default:
                    // Podrías soportar /{id} más adelante; por ahora 404
                    resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    resp.getWriter().write(gson.toJson(new ErrorResp("Recurso no encontrado: " + path)));
            }
        } catch (SQLException ex) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write(gson.toJson(new ErrorResp("Error DB: " + ex.getMessage())));
        } catch (Exception ex) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write(gson.toJson(new ErrorResp("Error interno: " + ex.getMessage())));
        }
    }

    // --- Handlers separados para claridad ---

    private void handleListAll(HttpServletRequest req, HttpServletResponse resp) throws SQLException, IOException {
        List<Estudiante> lista = dao.obtenerTodos();
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write(gson.toJson(lista));
    }

    private void handleGetMe(HttpServletRequest req, HttpServletResponse resp) throws SQLException, IOException {
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
    }

    private void handleGetNotas(HttpServletRequest req, HttpServletResponse resp) throws SQLException, IOException {
        // Intentamos obtener 'cui' por parámetro; si no lo pasan, intentamos tomarlo de la sesión
        String cui = req.getParameter("cui");
        if (cui == null || cui.trim().isEmpty()) {
            HttpSession session = req.getSession(false);
            if (session != null && session.getAttribute("usuario") != null) {
                // si tu Estudiante tiene campo 'cui', obténlo desde DAO por correo
                String correo = (String) session.getAttribute("usuario");
                Estudiante e = dao.obtenerPorCorreo(correo);
                if (e != null) {
                    // asegúrate que Estudiante tenga el campo 'cui' o adaptarlo
                    try {
                        // si tu DTO expone 'cui' o 'numeroDocumento' ajústalo
                        java.lang.reflect.Field f = e.getClass().getDeclaredField("cui");
                        f.setAccessible(true);
                        Object val = f.get(e);
                        if (val != null) cui = val.toString();
                    } catch (NoSuchFieldException | IllegalAccessException ex) {
                        // si no hay campo 'cui', puedes adaptar: usar idUsuario u otro identificador
                        // aquí dejamos cui null y se validará abajo
                    }
                }
            }
        }

        if (cui == null || cui.trim().isEmpty()) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write(gson.toJson(new ErrorResp("Falta parámetro 'cui' (o no autenticado)")));
            return;
        }

        String semestre = req.getParameter("semestre"); // opcional
        List<EstudianteDAO.CursoNotasDTO> cursos = dao.getNotasPorCUI(cui, semestre);
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.getWriter().write(gson.toJson(cursos));
    }

    private void handleGetMeHorarios(HttpServletRequest req, HttpServletResponse resp) throws SQLException, IOException {
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
    }

    // Clase para mensajes de error simples
    private static class ErrorResp {
        String error;
        ErrorResp(String e) { error = e; }
    }
}
