/// Bodega de trabajo elegida por el usuario (clave primaria de origen).
class WarehouseWorkspace {
  const WarehouseWorkspace({
    required this.warehouseKey,
    this.odooLocationLabel,
  });

  /// Texto que el usuario selecciona (ej. "Casa de la moneda").
  final String warehouseKey;
  final String? odooLocationLabel;

  bool get isValid => warehouseKey.trim().isNotEmpty;
}
