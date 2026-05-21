# Feature: warehouse (Gestion Almacen)

Documentacion completa: `docs/gestion_almacen/`.

## Capas

- `domain/` — entidades y `StockAllocationValidator`
- `data/` — Odoo (`OdooWarehouseStockRepository`), Firebase (`FirebaseBinRepository`)
- `presentation/` — pantallas y providers Riverpod

## Pantallas

| Ruta | Widget |
|------|--------|
| `/warehouse` | `WarehouseHomeScreen` |
| `/warehouse/stock` | `WarehouseStockScreen` (fase 1) |
| `/warehouse/bins` | `WarehouseBinsScreen` (fase 2) |
