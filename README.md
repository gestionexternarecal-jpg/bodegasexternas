# Gestion Externa

Aplicacion Flutter para **transferencias internas de Odoo** (Windows, Android, Web).

## Funcionalidades (MVP)

- Login Odoo via JSON-RPC
- Lista y detalle de transferencias internas (`stock.picking`)
- Lineas de producto (`stock.move.line`) con cantidad realizada
- Confirmar y validar transferencias
- **Crear transferencias internas** (tipo operacion, ubicaciones, productos)
- Escaneo de codigo de barras (teclado HID)
- Sesion segura y tema claro/oscuro

## Requisitos

- Flutter 3.41+
- Visual Studio (escritorio Windows)
- Android SDK (opcional)
- Odoo con modulo Inventario y usuario con permisos de stock

## Ejecutar

La URL y la base de datos de Odoo **no** se muestran en el login; deben pasarse al compilar o ejecutar con `--dart-define`.

### Opcion A: archivo local (recomendado en desarrollo)

```powershell
cd "d:\Desarollo de software\PC\Bodegas XT"
copy dart_defines.example.json dart_defines.json
# Editar dart_defines.json con tu URL y base de datos
flutter pub get
flutter run -d windows --dart-define-from-file=dart_defines.json
```

`dart_defines.json` esta en `.gitignore` (no se sube al repositorio).

### Opcion B: defines en la linea de comandos

```powershell
flutter run -d windows `
  --dart-define=ODOO_BASE_URL=https://tu-servidor.odoo.com `
  --dart-define=ODOO_DATABASE=nombre_base_datos
```

### Build de release (Windows)

```powershell
flutter build windows --dart-define-from-file=dart_defines.json
```

Tras el primer inicio de sesion exitoso, URL y DB quedan guardadas cifradas en el equipo; los `--dart-define` siguen siendo necesarios en instalaciones nuevas o si se borra el almacenamiento seguro.

## Estructura

```
lib/
├── main.dart, app.dart
├── core/           # RPC, router, tema, providers
├── features/
│   ├── auth/       # Login y sesion
│   ├── transfers/  # Pickings y lineas
│   └── shell/      # Layout con sidebar
└── shared/widgets/
```

## Distribucion (instalador Windows)

Para generar el instalador y `version.json` para actualizaciones:

```powershell
copy dart_defines.example.json dart_defines.json
# Editar ODOO_*, UPDATE_MANIFEST_URL y UPDATE_DOWNLOAD_BASE_URL
.\tool\build_release.ps1
```

Salida en `dist\`. Guia completa: [docs/DISTRIBUCION.md](docs/DISTRIBUCION.md).

## Documentacion

- [Distribucion y versionado](docs/DISTRIBUCION.md)
- [Integracion Odoo y CORS](docs/INTEGRACION_ODOO.md)
- [Especificacion del proyecto](docs/PROMPT_DESARROLLO.md)
