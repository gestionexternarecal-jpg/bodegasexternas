# Distribucion Windows — Gestion Externa

## Versionado

Fuente unica: `version: MAJOR.MINOR.PATCH+BUILD` en [`pubspec.yaml`](../pubspec.yaml).

| Parte | Cuando subir |
|-------|----------------|
| `+BUILD` | En **cada** instalador publicado (obligatorio para detectar actualizaciones) |
| PATCH | Correcciones |
| MINOR | Funciones nuevas compatibles |
| MAJOR | Cambios que rompen datos o configuracion |

## Requisitos en la PC de desarrollo

- Flutter 3.41+ y Visual Studio (CMake, MSVC)
- [Inno Setup 6](https://jrsoftware.org/isinfo.php) instalado (ruta por defecto: `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`)
- Archivo `dart_defines.json` en la raiz del proyecto (no se sube a git)

## Configurar `dart_defines.json`

```powershell
copy dart_defines.example.json dart_defines.json
```

Editar con valores reales:

```json
{
  "ODOO_BASE_URL": "https://tu-servidor.odoo.com",
  "ODOO_DATABASE": "nombre_base_datos",
  "UPDATE_MANIFEST_URL": "https://intranet/apps/gestion_externa/version.json"
}
```

- `UPDATE_MANIFEST_URL`: URL publica del manifest (mismo origen que el instalador o carpeta de red servida por IIS/nginx).

## Publicar una version (checklist)

1. Subir `version` en `pubspec.yaml` (incluir `+build` mayor que la version anterior).
2. Anadir entrada en [`CHANGELOG.md`](../CHANGELOG.md).
3. Ejecutar:

   ```powershell
   .\tool\build_release.ps1
   ```

4. Revisar salida en `dist\`:
   - `GestionExterna_<version>_setup.exe`
   - `version.json`
5. Copiar ambos archivos al servidor o carpeta compartida (`\\servidor\apps\gestion_externa\` o HTTPS interno).
6. Verificar que `version.json` en el servidor coincide con el build publicado (la app compara el campo `build`).

## Instalacion para usuarios

1. Ejecutar `GestionExterna_X.Y.Z_setup.exe`.
2. Seguir el asistente (instalacion en `C:\Program Files\Gestion Externa\`).
3. No es necesario desinstalar versiones anteriores: ejecutar el nuevo instalador encima.

Windows puede mostrar "Editor desconocido" si el instalador no esta firmado con certificado de codigo (normal en v1).

## Actualizaciones

La aplicacion consulta `UPDATE_MANIFEST_URL` al entrar al area principal (una vez por sesion). Si hay un `build` mayor, muestra un dialogo con enlace de descarga. El usuario instala el nuevo `.exe` manualmente.

Ejemplo de `version.json` generado por el script de release:

```json
{
  "version": "1.0.1",
  "build": 2,
  "download_url": "https://intranet/apps/gestion_externa/GestionExterna_1.0.1_setup.exe",
  "release_notes": "Ver CHANGELOG.md"
}
```

Ajusta `download_url` en `dart_defines.json` con la clave `UPDATE_DOWNLOAD_BASE_URL` (carpeta base donde subes el instalador) o edita `version.json` tras generarlo.

## Datos que se conservan al actualizar

| Dato | Ubicacion |
|------|-----------|
| Sesion Odoo / credenciales | Almacenamiento seguro del sistema |
| Tema | SharedPreferences |
| URL/DB Odoo embebidas | Dentro del ejecutable (mismo instalador para todos) |

No cambiar el `AppId` del instalador Inno entre versiones.

## Pruebas piloto

Ver [DISTRIBUCION_PRUEBAS.md](DISTRIBUCION_PRUEBAS.md).

## Solucion de problemas

| Problema | Accion |
|----------|--------|
| CMake Firebase &lt; 3.10 | `.\tool\patch_firebase_cmake.ps1` y volver a compilar |
| Inno no encontrado | Instalar Inno Setup 6 o definir `$env:INNO_SETUP_PATH` |
| No aparece aviso de actualizacion | Comprobar `UPDATE_MANIFEST_URL` y que `build` en JSON sea mayor que el instalado |
