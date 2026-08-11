$ErrorActionPreference = 'Stop'

flutter --version
flutter config --enable-windows-desktop
flutter create --platforms=android,windows --org studio.agr --project-name viti .

$gradle = 'android/app/build.gradle.kts'
if (Test-Path $gradle) {
  $content = Get-Content $gradle -Raw
  $content = $content.Replace('minSdk = flutter.minSdkVersion', 'minSdk = 23')
  Set-Content $gradle $content
}

flutter pub get
flutter doctor
Write-Host 'VITI Flutter preparado para Android y Windows.' -ForegroundColor Green
