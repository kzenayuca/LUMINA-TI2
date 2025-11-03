async function iniciarSesion() {
  try {
    const correo = document.getElementById("usuario").value.trim();
    const contrasena = document.getElementById("contrasena").value.trim();

    // Validación básica (evita llamadas innecesarias)
    if (!correo || !contrasena) {
      alert("Por favor completa usuario y contraseña.");
      return;
    }

    const resp = await fetch("login", {
      method: "POST",
      headers: { "Content-Type": "application/json" }, // CORRECCIÓN
      body: JSON.stringify({ email: correo, password: contrasena })
    });

    // Intentamos parsear JSON (el backend siempre devuelve JSON en tu servlet)
    const data = await resp.json().catch(() => null);

    if (resp.ok && data && data.success) {
      // Guardamos rol y usuario (solo para uso UI). No confíes en esto para seguridad.
      localStorage.setItem("rol", data.rol);
      localStorage.setItem("usuario", correo);

      // MAPA de rol -> página (ajusta nombres de archivos si los tuyos son otros)
      const rol = (data.rol || "").toLowerCase();
      let destino = "frontend/estudiante.html"; // fallback

      if (rol.includes("docente") || rol === "docente") destino = "doc/profesor.html";
      else if (rol.includes("admin") || rol === "administrador" || rol === "admin") destino = "admin/admin.html";
      else if (rol.includes("secretaria") || rol === "secretaria" || rol === "admin") destino = "admin/admin.html";
      else if (rol.includes("estudiante") || rol === "estudiante") destino = "est/estudiante_dashboard.html";

      window.location.href = destino;
    } else {
      // Si el servidor devolvió un mensaje, mostrarlo. Si no, mostrar error por defecto.
      const mensaje = data && data.mensaje ? data.mensaje : "Credenciales incorrectas";
      alert("⚠️ " + mensaje);
    }
  } catch (err) {
    console.error("Error en iniciarSesion:", err);
    alert("❌ Error al contactar el servidor");
  }
}
