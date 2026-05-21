# Build release Windows + instalador Inno Setup + version.json
# Uso: .\tool\build_release.ps1 [-SkipFlutterBuild]

param(
    [switch]$SkipFlutterBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$definesPath = Join-Path $root "dart_defines.json"
if (-not (Test-Path $definesPath)) {
    Write-Error "Falta dart_defines.json. Copia dart_defines.example.json y editalo."
}

function Get-PubspecVersion {
    $line = Get-Content (Join-Path $root "pubspec.yaml") | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
    if (-not $line) { throw "No se encontro version en pubspec.yaml" }
    if ($line -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)') {
        return @{ Semver = $Matches[1]; Build = [int]$Matches[2]; Full = "$($Matches[1])+$($Matches[2])" }
    }
    if ($line -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
        return @{ Semver = $Matches[1]; Build = 0; Full = $Matches[1] }
    }
    throw "Formato de version invalido: $line"
}

function Get-DartDefineValue {
    param([string]$Key)
    $json = Get-Content $definesPath -Raw | ConvertFrom-Json
    $prop = $json.PSObject.Properties[$Key]
    if ($prop) { return [string]$prop.Value }
    return ""
}

$ver = Get-PubspecVersion
Write-Host "Version: $($ver.Full) (semver $($ver.Semver), build $($ver.Build))"

if (-not $SkipFlutterBuild) {
    Write-Host "flutter pub get..."
    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $firebaseCmake = Join-Path $root "build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"
    if (Test-Path $firebaseCmake) {
        Write-Host "Parche Firebase CMake (si aplica)..."
        & (Join-Path $root "tool\patch_firebase_cmake.ps1")
    }

    Write-Host "flutter build windows --release..."
    flutter build windows --release --dart-define-from-file=dart_defines.json
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$releaseDir = Join-Path $root "build\windows\x64\runner\Release"
if (-not (Test-Path (Join-Path $releaseDir "gestion_externa.exe"))) {
    Write-Error "No existe $releaseDir\gestion_externa.exe. Ejecuta el build primero."
}

$innoPaths = @(
    ${env:INNO_SETUP_PATH},
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
) | Where-Object { $_ -and (Test-Path $_) }

$iscc = $innoPaths | Select-Object -First 1
if (-not $iscc) {
    Write-Error "Inno Setup no encontrado. Instala Inno Setup 6 o define INNO_SETUP_PATH."
}

$distDir = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

Write-Host "Compilando instalador con Inno Setup..."
& $iscc `
    "/DAppVersion=$($ver.Semver)" `
    "/DReleaseDir=$releaseDir" `
    (Join-Path $root "installer\gestion_externa.iss")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$setupName = "GestionExterna_$($ver.Semver)_setup.exe"
$setupPath = Join-Path $distDir $setupName

$downloadBase = Get-DartDefineValue "UPDATE_DOWNLOAD_BASE_URL"
if (-not $downloadBase) {
    $downloadBase = ""
}
$downloadBase = $downloadBase.TrimEnd('/')
$downloadUrl = if ($downloadBase) { "$downloadBase/$setupName" } else { $setupName }

$changelogNote = ""
$changelogPath = Join-Path $root "CHANGELOG.md"
if (Test-Path $changelogPath) {
    $changelogNote = "Consulte CHANGELOG.md en el repositorio."
}

$manifest = @{
    version     = $ver.Semver
    build       = $ver.Build
    download_url = $downloadUrl
    release_notes = $changelogNote
} | ConvertTo-Json -Depth 3

$manifestPath = Join-Path $distDir "version.json"
Set-Content -Path $manifestPath -Value $manifest -Encoding UTF8

Write-Host ""
Write-Host "Listo:"
Write-Host "  Instalador: $setupPath"
Write-Host "  Manifest:   $manifestPath"
Write-Host ""
Write-Host "Sube ambos archivos al servidor y verifica UPDATE_MANIFEST_URL en dart_defines.json."
