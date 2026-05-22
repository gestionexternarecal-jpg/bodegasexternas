# Pruebas de distribucion (piloto)

## 1. Build e instalador

```powershell
copy dart_defines.example.json dart_defines.json
# Completar ODOO_*, UPDATE_MANIFEST_URL, UPDATE_DOWNLOAD_BASE_URL
.\tool\build_release.ps1
```

Verificar en `dist\`:

- `GestionExterna_1.0.0_setup.exe`
- `version.json` con `build` igual al `+N` de `pubspec.yaml`

## 2. Instalacion limpia

En un PC de prueba (o VM):

1. Ejecutar el `.exe` de `dist\`.
2. Abrir la app desde el menu Inicio.
3. Iniciar sesion Odoo.
4. Menu lateral → icono **Acerca de** → debe mostrar `v1.0.0 (1)`.

## 3. Aviso de actualizacion (v1 → v2)

1. En `pubspec.yaml` subir a `1.0.1+2`.
2. Entrada en `CHANGELOG.md`.
3. `.\tool\build_release.ps1`
4. Subir `dist\version.json` y el nuevo setup al servidor (misma URL que `UPDATE_MANIFEST_URL`).
5. Con la v1 instalada, abrir la app → debe aparecer el dialogo de actualizacion.
6. **Descargar** abre la URL del manifest; instalar el nuevo setup encima.

## 4. Conservar sesion

Tras instalar v2 sin desinstalar:

- La app debe abrir sin pedir login (sesion en almacenamiento seguro).
- Si pide login, comprobar que el `AppId` del instalador no cambio.

## 5. Sin red / sin manifest

- Build sin `UPDATE_MANIFEST_URL` o URL invalida: la app inicia sin dialogo (no bloquea).
