# VITI Android

Aplicación Android tipo WebView para la plataforma VITI.

**URL configurada:** https://viti-frontend.vercel.app/

## Funciones incluidas

- VITI se abre a pantalla completa, sin barra del navegador.
- Mantiene cookies y almacenamiento web para conservar la sesión.
- JavaScript y almacenamiento local habilitados para Vue/Quasar.
- Botón Atrás de Android navega dentro de VITI.
- Barra de progreso durante la carga.
- Pantalla amigable cuando falla la conexión.
- Enlaces externos se abren fuera de la APK.
- Selector de uno o varios archivos.
- Acceso a cámara cuando el formulario solicita imágenes.
- Descargas mediante Download Manager.
- Solo permite tráfico HTTPS.

## Opción A — construir en Android Studio

1. Instala Android Studio.
2. Abre esta carpeta como proyecto.
3. Espera la sincronización de Gradle.
4. Menú **Build > Build App Bundles or APKs > Build APKs**.
5. El APK queda normalmente en:
   `app/build/outputs/apk/debug/app-debug.apk`

El APK debug es suficiente para instalarlo manualmente en un teléfono para una demostración o defensa.

## Opción B — construir automáticamente en GitHub

El proyecto incluye `.github/workflows/build-apk.yml`.

1. Sube esta carpeta a un repositorio GitHub, por ejemplo `viti-android`.
2. En GitHub entra a **Actions**.
3. Abre **Construir APK VITI**.
4. Ejecuta **Run workflow** o simplemente haz push a `main`.
5. Cuando termine, descarga el artifact **VITI-APK**.
6. Dentro estará `app-debug.apk`.

## Identidad de la app

- Nombre: VITI
- Package: `com.agrstudio.viti`
- Versión: `1.0.0`
- Min Android: 7.0 (API 24)
- Target: Android API 35

## Cambiar URL en el futuro

En `app/src/main/java/com/agrstudio/viti/MainActivity.java` modifica:

```java
private static final String HOME_URL = "https://viti-frontend.vercel.app/";
private static final String VITI_HOST = "viti-frontend.vercel.app";
```
