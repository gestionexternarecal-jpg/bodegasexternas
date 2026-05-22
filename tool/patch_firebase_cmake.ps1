# Parchea el CMakeLists del SDK Firebase C++ extraido (warning CMake < 3.10).
# Ejecutar si el build muestra la advertencia en la primera compilacion con Firebase.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$sdkCmake = Join-Path $root "build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"

if (-not (Test-Path $sdkCmake)) {
    Write-Host "No existe aun: $sdkCmake"
    Write-Host "Ejecuta un build una vez (flutter build windows ...) y vuelve a lanzar este script."
    exit 1
}

$content = Get-Content $sdkCmake -Raw
$newContent = $content -replace 'cmake_minimum_required\(VERSION 3\.1\)', 'cmake_minimum_required(VERSION 3.14)'
if ($content -eq $newContent) {
    Write-Host "Ya estaba parcheado o no requiere cambios."
    exit 0
}

Set-Content -Path $sdkCmake -Value $newContent -NoNewline
Write-Host "Parcheado: $sdkCmake"
Write-Host "Vuelve a ejecutar: flutter build windows --dart-define-from-file=dart_defines.json"
