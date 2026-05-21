# Modelo Firestore — ubicaciones internas

Las ubicaciones **no existen en Odoo**; solo en Firebase. Se vinculan a una bodega de trabajo mediante `warehouseKey` (mismo texto que el usuario elige en la app, ej. `Casa de la moneda`).

## Colecciones

### `warehouse_profiles`

Documento por bodega de trabajo (opcional, metadatos).

```json
{
  "warehouseKey": "Casa de la moneda",
  "odooLocationLabel": "PHSA/Casa de la moneda",
  "companyIds": [1, 2],
  "active": true,
  "updatedAt": "Timestamp"
}
```

ID sugerido: slug del `warehouseKey`.

### `bin_locations`

Ubicaciones internas (estanterías, pasillos).

```json
{
  "warehouseKey": "Casa de la moneda",
  "code": "101-A12",
  "zone": "101",
  "aisle": "A",
  "level": "12",
  "active": true,
  "notes": ""
}
```

ID sugerido: `{warehouseKey}_{code}` normalizado.

### `bin_stock`

Cantidad asignada por producto y ubicación.

```json
{
  "warehouseKey": "Casa de la moneda",
  "binLocationId": "casa_de_la_moneda_101-a12",
  "binCode": "101-A12",
  "odooProductId": 12345,
  "productDefaultCode": "REF-001",
  "quantity": 100.0,
  "uomName": "Unidades",
  "updatedAt": "Timestamp",
  "updatedBy": "usuario@empresa.com"
}
```

ID sugerido: `{warehouseKey}_{productId}_{binLocationId}`.

## Índices compuestos recomendados

- `bin_stock`: `warehouseKey` + `odooProductId`
- `bin_locations`: `warehouseKey` + `active`

## Reglas de negocio (app)

Antes de escribir `bin_stock`:

1. Obtener `odooAvailable` del producto en la bodega.
2. Sumar todas las filas `bin_stock` del mismo `warehouseKey` + `odooProductId` (excluyendo la fila que se edita si es update).
3. Rechazar si `nuevaSuma > odooAvailable`.

La validación vive en `StockAllocationValidator` (dominio) y se repite en reglas Firestore cuando se despliegue backend.
