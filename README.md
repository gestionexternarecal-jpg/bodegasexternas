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

```powershell
cd "d:\Desarollo de software\PC\Bodegas XT"
flutter pub get
flutter run -d windows
```

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

## Documentacion

- [Integracion Odoo y CORS](docs/INTEGRACION_ODOO.md)
- [Especificacion del proyecto](docs/PROMPT_DESARROLLO.md)
