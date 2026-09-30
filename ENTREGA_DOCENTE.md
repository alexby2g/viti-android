# Descripción técnica breve para la defensa

VITI dispone de una aplicación Android que funciona como cliente móvil de la plataforma web publicada. La APK contiene un WebView configurado para cargar de forma segura la aplicación VITI mediante HTTPS, manteniendo la autenticación y la navegación del usuario dentro de un entorno de aplicación móvil.

La solución permite conservar una arquitectura centralizada: el frontend Vue/Quasar y el backend Laravel continúan siendo la fuente principal del sistema, mientras que la APK proporciona el acceso desde dispositivos Android sin duplicar la lógica de negocio.

La aplicación incorpora manejo de navegación, carga de archivos e imágenes, descargas, cámara, persistencia de sesión y control de enlaces externos.
