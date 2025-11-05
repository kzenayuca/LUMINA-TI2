async function iniciarSesion() {
  try {
    const correo = document.getElementById("usuario").value.trim();
    const contrasena = document.getElementById("contrasena").value.trim();

    // 🔍 Validación básica
    if (!correo || !contrasena) {
      alert("Por favor completa usuario y contraseña.");
      return;
    }

    // 📡 Enviamos petición al servidor
    const resp = await fetch("login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: correo, password: contrasena })
    });

    // Intentamos obtener el JSON de respuesta
    const data = await resp.json().catch(() => null);

    // Si el servidor respondió correctamente (2xx)
    if (resp.ok && data && data.success) {

      // 💾 Guardamos toda la información en localStorage
      localStorage.setItem("usuarioDatos", JSON.stringify(data.usuario || {}));
      localStorage.setItem("rol", data.rol || "");
      localStorage.setItem("email", correo);

      // 🚪 Redirigimos según el rol
      const rol = (data.rol || "").toLowerCase();
      let destino = "frontend/estudiante.html"; // página por defecto

      if (rol.includes("docente") || rol === "docente")
        destino = "doc/profesor.html";
      else if (rol.includes("admin") || rol === "administrador")
        destino = "admin/admin.html";
      else if (rol.includes("secretaria"))
        destino = "admin/admin.html";
      else if (rol.includes("estudiante"))
        destino = "est/estudiante_dashboard.html";

      // Redirección final
      window.location.href = destino;

    } else {
      // ⚠️ Error de credenciales u otro mensaje del servidor
      const mensaje = data?.mensaje || "Credenciales incorrectas.";
      alert("⚠️ " + mensaje);
    }

  } catch (err) {
    console.error("Error en iniciarSesion:", err);
    alert("❌ Error al contactar el servidor");
  }
}
