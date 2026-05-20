/// Utilidades para valores devueltos por Odoo (a menudo `false` en lugar de null).
abstract final class OdooValue {
  static String? string(dynamic value) {
    if (value == null || value == false) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  static String stringOrEmpty(dynamic value) => string(value) ?? '';

  static int? many2oneId(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) {
      final id = value.first;
      if (id is int) return id;
    }
    return null;
  }

  static String? many2oneName(dynamic value) {
    if (value is List && value.length > 1) {
      return string(value[1]);
    }
    return null;
  }

  static double? decimal(dynamic value) {
    if (value == null || value == false) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
