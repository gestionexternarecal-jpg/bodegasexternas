# Publica el instalador y version.json en GitHub Releases (requiere: gh auth login).
# Uso:
#   .\tool\publish_github_release.ps1              # compila y publica
#   .\tool\publish_github_release.ps1 -SkipBuild   # solo sube dist\ existente
#   .\tool\publish_github_release.ps1 -SkipBuild -Replace  # reemplaza assets si el tag ya existe

param(
    [switch]$SkipBuild,
    [switch]$Replace,
    [string]$Repo = "gestionexternarecal-jpg/bodegasexternas"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$ghCmd = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghCmd) {
    Write-Error "GitHub CLI (gh) no esta en el PATH. Cierra y abre PowerShell, o ejecuta: winget install GitHub.cli"
}

$auth = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Primero inicia sesion en GitHub (una sola vez):" -ForegroundColor Yellow
    Write-Host "  gh auth login" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Recomendado: GitHub.com -> HTTPS -> Login con navegador."
    Write-Error $auth
}

function Get-PubspecVersion {
    $line = Get-Content (Join-Path $root "pubspec.yaml") | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
    if ($line -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)') {
        return @{ Semver = $Matches[1]; Build = [int]$Matches[2] }
    }
    throw "No se encontro version en pubspec.yaml"
}

if (-not $SkipBuild) {
    & (Join-Path $root "tool\build_release.ps1")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$ver = Get-PubspecVersion
$tag = "v$($ver.Semver)"
$distDir = Join-Path $root "dist"
$setupName = "GestionExterna_$($ver.Semver)_setup.exe"
$setupPath = Join-Path $distDir $setupName
$manifestPath = Join-Path $distDir "version.json"

foreach ($p in @($setupPath, $manifestPath)) {
    if (-not (Test-Path $p)) {
        Write-Error "Falta archivo: $p. Ejecuta .\tool\build_release.ps1"
    }
}

$changelogPath = Join-Path $root "CHANGELOG.md"
$notes = "Gestion Externa $($ver.Semver) (build $($ver.Build)). Ver CHANGELOG.md en el repositorio."
if (Test-Path $changelogPath) {
    $raw = Get-Content $changelogPath -Raw
    if ($raw -match "(?s)## \[$([regex]::Escape($ver.Semver))\][^\#]*") {
        $notes = $Matches[0].Trim()
    }
}

$releaseExists = $false
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
gh release view $tag --repo $Repo 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $releaseExists = $true }
$ErrorActionPreference = $prevEap

if ($releaseExists -and -not $Replace) {
    Write-Host "El release $tag ya existe. Usa -Replace para subir de nuevo los archivos." -ForegroundColor Yellow
    Write-Host "  .\tool\publish_github_release.ps1 -SkipBuild -Replace"
    exit 1
}

if ($releaseExists) {
    Write-Host "Subiendo assets a release existente $tag ..."
    gh release upload $tag $setupPath $manifestPath --repo $Repo --clobber
} else {
    Write-Host "Creando release $tag en $Repo ..."
    gh release create $tag `
        $setupPath `
        $manifestPath `
        --repo $Repo `
        --title "Gestion Externa $($ver.Semver)" `
        --notes $notes
}

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Publicado:" -ForegroundColor Green
Write-Host "  https://github.com/$Repo/releases/tag/$tag"
Write-Host "  Manifest: https://github.com/$Repo/releases/latest/download/version.json"
