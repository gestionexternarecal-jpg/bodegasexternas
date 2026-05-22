import 'entities/transfer_catalog.dart';

/// Resuelve la ubicacion de origen por empresa a partir de un nombre primario
/// (ej. "Casa de la moneda" -> "PHSA/Casa de la moneda", "PV/Casa de la moneda").
class PrimaryOriginResolver {
  PrimaryOriginResolver._();

  /// Bodegas que no deben aparecer en el selector de origen.
  static const Set<String> excludedOriginKeysLower = {
    'bodega en revisión',
    'bodega en revision',
    'productos con falla',
  };

  static bool isExcludedOriginKey(String name) {
    return excludedOriginKeysLower.contains(name.trim().toLowerCase());
  }

  /// Nombres unicos de ubicacion interna para el selector primario.
  static List<String> uniqueOriginKeys(List<StockLocation> locations) {
    final keys = <String>{};
    for (final loc in locations) {
      final name = loc.name.trim();
      if (name.isNotEmpty && !isExcludedOriginKey(name)) {
        keys.add(name);
      }
    }
    final list = keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Ubicacion de origen de la empresa que corresponde al nombre primario.
  static StockLocation? resolve(
    List<StockLocation> companyLocations,
    String primaryKey,
  ) {
    final key = primaryKey.trim();
    if (key.isEmpty) return null;

    final keyLower = key.toLowerCase();
    StockLocation? byName;
    StockLocation? byPath;

    for (final loc in companyLocations) {
      if (loc.name.trim().toLowerCase() == keyLower) {
        byName ??= loc;
      }
      final label = loc.displayLabel.trim();
      final labelLower = label.toLowerCase();
      if (labelLower == keyLower || labelLower.endsWith('/$keyLower')) {
        byPath ??= loc;
      }
    }

    return byName ?? byPath;
  }
}
