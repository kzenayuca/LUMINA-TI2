package controller;

import com.google.gson.Gson;
import dao.UsuarioDAO;
import dao.UsuarioDAO.ResultadoLogin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;
import java.io.*;

@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    private final Gson gson = new Gson();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    private static class LoginRequest {
        String email;
        String password;
    }

    private static class LoginResponse {
        boolean success;
        String rol;
        String mensaje;
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

        resp.setContentType("application/json;charset=UTF-8");

        if (resultado.ok) {
            HttpSession session = req.getSession(true);
            session.setAttribute("usuario", loginReq.email);
            session.setAttribute("rol", resultado.rol);

            resp.setStatus(HttpServletResponse.SC_OK);
            resp.getWriter().write(gson.toJson(new LoginResponse(true, resultado.rol, "Login exitoso")));
        } else {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            resp.getWriter().write(gson.toJson(new LoginResponse(false, null, resultado.mensaje)));
        }
    }
}
