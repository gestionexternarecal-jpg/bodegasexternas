/// Ubicacion interna definida solo en Firebase (no existe en Odoo).
class BinLocation {
  const BinLocation({
    required this.id,
    required this.warehouseKey,
    required this.code,
    this.zone,
    this.aisle,
    this.level,
    this.active = true,
    this.notes,
  });

  final String id;
  final String warehouseKey;
  final String code;
  final String? zone;
  final String? aisle;
  final String? level;
  final bool active;
  final String? notes;

  String get displayLabel => code;
}
