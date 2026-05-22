# Gestion Externa — Especificacion aplicada

Proyecto Flutter Desktop (Windows) + Android + Web, integrado con Odoo JSON-RPC para **transferencias internas**.

## Fase MVP implementada

- Login Odoo (URL, BD, usuario, contraseña)
- Probar conexion
- Sesion cifrada (`flutter_secure_storage`)
- Dashboard con contadores por estado
- Lista de `stock.picking` (tipo internal)
- Detalle con lineas `stock.move.line`
- Editar `qty_done`
- Confirmar (`action_confirm`) y validar (`button_validate` / fallback `action_done`)
- Escaneo HID (campo + Enter)
- Crear transferencia interna (`/transfer/new`)
- Riverpod + go_router + sidebar + tema claro/oscuro
- `window_manager` en Windows

## Pendiente (fases siguientes)

- Drift / offline
- Freezed en modelos
- Impresion PDF
- Android permisos red cleartext si HTTP

## Permisos Odoo requeridos

Usuario con acceso a Inventario: lectura/escritura en `stock.picking`, `stock.move.line`, validar transferencias.

## Ejecutar

```powershell
cd "d:\Desarollo de software\PC\Bodegas XT"
flutter pub get
flutter run -d windows
```
