# VITI Flutter

Cliente nativo multiplataforma de **VITI · producto de AGR Studio**.

## Plataformas

Una sola base Flutter para:

- Android (APK / AAB)
- Windows (aplicación de escritorio)
- iOS en una fase posterior

El nombre histórico del repositorio es `viti-android`, pero el producto dentro del código es VITI Flutter y soportará también Windows.

## Arquitectura

Flutter **no replica la lógica de negocio**. Laravel + Neon siguen siendo la fuente única de verdad para:

- autenticación y roles;
- empresas y permisos;
- solicitudes y cuestionarios;
- proyectos y avances;
- aplicaciones y estados;
- pagos y comprobantes;
- archivos y documentos;
- mensajería y soporte.

Flutter se conecta al mismo API que VITI Web mediante Bearer tokens Sanctum por dispositivo.

## Seguridad de sesión

Cada instalación genera un `device_id` aleatorio persistente y guarda el token usando `flutter_secure_storage`.

Eso permite mantener Android y Windows conectados al mismo tiempo. Volver a iniciar sesión en un dispositivo rota solamente el token de esa instalación.

## Preparar el proyecto en Windows

Requisitos:

1. Flutter estable instalado.
2. Android Studio + Android SDK para Android.
3. Visual Studio con **Desktop development with C++** para compilar Windows.

Desde PowerShell:

```powershell
./scripts/bootstrap.ps1
```

El script genera los hosts nativos Android y Windows, fija Android mínimo en API 23 y ejecuta `flutter pub get` + `flutter doctor`.

## Ejecutar

Android:

```powershell
flutter run -d android --dart-define=VITI_API_URL=https://viti-core-api-alexby2g.onrender.com/api/v1
```

Windows:

```powershell
flutter run -d windows --dart-define=VITI_API_URL=https://viti-core-api-alexby2g.onrender.com/api/v1
```

## Estado de la primera fase

- login nativo conectado;
- sesión segura persistente;
- restauración automática de sesión;
- cierre de sesión;
- interfaz AGR/VITI oscura;
- navegación adaptativa para móvil y escritorio;
- menús diferentes para Cliente, Administrador/Superadmin y Soporte;
- CI preparado para analizar, probar y compilar Android + Windows.

Los módulos de negocio se conectarán endpoint por endpoint en las siguientes fases para conservar paridad con VITI Web.
