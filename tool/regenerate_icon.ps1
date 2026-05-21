# Regenera app_icon.ico valido para Windows desde assets/icons/app_icon.png
# Uso: .\tool\regenerate_icon.ps1
# NO renombres un .png a .ico manualmente (provoca error RC2175).

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host 'Regenerando iconos...' -ForegroundColor Cyan
dart run flutter_launcher_icons

$ico = 'windows\runner\resources\app_icon.ico'
$bytes = [System.IO.File]::ReadAllBytes((Join-Path (Get-Location) $ico))[0..3]
$hex = [BitConverter]::ToString($bytes)

if ($hex -eq '00-00-01-00') {
    $size = (Get-Item $ico).Length
    Write-Host "OK: $ico ($size bytes) formato ICO valido." -ForegroundColor Green
} else {
    Write-Host "ERROR: $ico no es ICO valido (cabecera: $hex). Debe ser 00-00-01-00." -ForegroundColor Red
    Write-Host 'Coloca tu imagen en assets\icons\app_icon.png (PNG) y vuelve a ejecutar este script.'
    exit 1
}
