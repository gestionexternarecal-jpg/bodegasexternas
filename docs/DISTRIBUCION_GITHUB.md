# Distribucion con GitHub Releases

Repositorio: https://github.com/gestionexternarecal-jpg/bodegasexternas

## Importante (seguridad)

- **Nunca** subas `dart_defines.json` (tiene URL/DB de Odoo). Ya esta en `.gitignore`.
- El codigo fuente en GitHub **no** debe incluir contraseñas ni `dart_defines.json`.
- Los instaladores `.exe` en Releases son publicos si el repo es publico.

## Paso 1 — Subir el codigo a GitHub (una vez)

En PowerShell, desde la carpeta del proyecto:

```powershell
cd "d:\Desarollo de software\PC\Bodegas XT"
git remote add origin https://github.com/gestionexternarecal-jpg/bodegasexternas.git
git branch -M main
git add .
git commit -m "Initial commit: Gestion Externa"
git push -u origin main
```

Si `git remote add` dice que ya existe:

```powershell
git remote set-url origin https://github.com/gestionexternarecal-jpg/bodegasexternas.git
git push -u origin main
```

## Paso 2 — Crear `dart_defines.json` (solo en tu PC)

```powershell
copy dart_defines.example.json dart_defines.json
```

Edita `dart_defines.json` con tus valores **reales** de Odoo.

```json
{
  "ODOO_BASE_URL": "https://tu-servidor.odoo.com",
  "ODOO_DATABASE": "tu_base",
  "UPDATE_MANIFEST_URL": "",
  "UPDATE_DOWNLOAD_BASE_URL": "https://github.com/gestionexternarecal-jpg/bodegasexternas/releases/latest/download/"
}
```

La app comprueba siempre el manifest del **ultimo** Release:
`.../releases/latest/download/version.json` (no cambia la URL en cada version).

## Si no aparece el aviso de actualizacion

1. En la PC instalada: **Acerca de** → debe decir `v1.0.0 (1)` si es la primera version.
2. La v1.0.0 buscaba `.../releases/download/v1.0.0/version.json`. Si solo publicaste **v1.0.1**, esa URL no existe → no hay aviso.
3. **Arreglo rapido (sin recompilar):** crea un Release **v1.0.0** en GitHub y sube un `version.json` con `"build": 2` y `download_url` al instalador 1.0.1.
4. **Arreglo definitivo:** instala el ultimo `.exe` o publica una version nueva compilada con el codigo actual (usa `releases/latest/download/version.json`).

## Paso 3 — Generar el instalador

```powershell
.\tool\build_release.ps1
```

Revisa `dist\`:

- `GestionExterna_1.0.0_setup.exe`
- `version.json`

## Paso 4 — Publicar Release en GitHub

1. Abre: https://github.com/gestionexternarecal-jpg/bodegasexternas/releases
2. **Create a new release**
3. **Choose a tag:** escribe `v1.0.0` → **Create new tag**
4. **Release title:** `v1.0.0` o `Gestion Externa 1.0.0`
5. Descripcion: copia notas de `CHANGELOG.md`
6. **Attach binaries:** arrastra desde `dist\`:
   - `GestionExterna_1.0.0_setup.exe`
   - `version.json`
7. **Publish release**

## Paso 5 — Comprobar URLs

En el navegador debe abrirse el JSON (no error 404):

https://github.com/gestionexternarecal-jpg/bodegasexternas/releases/download/v1.0.0/version.json

El instalador:

https://github.com/gestionexternarecal-jpg/bodegasexternas/releases/download/v1.0.0/GestionExterna_1.0.0_setup.exe

## Paso 6 — Entregar a usuarios

- Enlace del instalador (Release asset) o el `.exe` descargado.
- Instalar y usar. La app comprobara `version.json` al entrar.

## Proxima version (ej. 1.0.1+2)

1. `pubspec.yaml` → `version: 1.0.1+2`
2. `CHANGELOG.md`
3. En `dart_defines.json` cambia las URLs a `v1.0.1`
4. `.\tool\build_release.ps1`
5. Nuevo Release en GitHub con tag **`v1.0.1`** y sube los archivos de `dist\`

## Repo publico vs privado

| Tipo | Codigo | Releases (.exe) |
|------|--------|-----------------|
| Publico | Visible para todos | Descarga directa sin login |
| Privado | Solo colaboradores | Enlaces de release requieren login/token; la app en PCs de usuarios puede **no** leer `version.json` sin configuracion extra |

Recomendacion: repo **privado** para codigo + Release publico no aplica igual; para intranet empresarial valora **repo privado** y distribuir el `.exe` manualmente, o repo publico solo para Releases (menos ideal).

Para tu caso actual (repo publico), los `.exe` y `version.json` seran descargables por cualquiera con el enlace.
