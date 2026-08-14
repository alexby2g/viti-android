$ErrorActionPreference = 'Stop'

flutter --version
flutter config --enable-windows-desktop
flutter create --platforms=android,windows --org studio.agr --project-name viti .

# flutter create puede generar su test de contador por defecto. Si VITI ya trae
# un widget_test.dart versionado, restauramos el archivo del repositorio para
# evitar que el test genérico MyApp bloquee futuros pulls/analyze.
if (Test-Path '.git') {
  git checkout -- test/widget_test.dart 2>$null
}

$gradle = 'android/app/build.gradle.kts'
if (Test-Path $gradle) {
  $content = Get-Content $gradle -Raw
  $content = $content.Replace('minSdk = flutter.minSdkVersion', 'minSdk = 23')
  Set-Content $gradle $content
}

flutter pub get
flutter doctor
Write-Host 'VITI Flutter preparado para Android y Windows.' -ForegroundColor Green
