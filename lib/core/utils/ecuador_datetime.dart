import 'package:intl/intl.dart';

/// Fechas y horas en zona horaria y formato de Ecuador (es_EC, UTC-5).
abstract final class EcuadorDateTime {
  static const locale = 'es_EC';
  static const _ecuadorOffset = Duration(hours: 5);

  static final DateFormat dateTime = DateFormat('dd/MM/yyyy hh:mm a', locale);
  static final DateFormat dateOnly = DateFormat('dd/MM/yyyy', locale);

  /// Interpreta cadenas de Odoo (`scheduled_date`, etc.) como UTC.
  static DateTime? parseOdooUtc(dynamic value) {
    if (value == null || value == false) return null;
    if (value is! String) return null;
    final s = value.trim();
    if (s.isEmpty) return null;

    final parsed = DateTime.tryParse(s);
    if (parsed == null) return null;

    if (s.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s) ||
        RegExp(r'[+-]\d{4}$').hasMatch(s)) {
      return parsed.toUtc();
    }

    final withT = s.replaceFirst(' ', 'T');
    final hasTime = s.contains(':');
    final iso = hasTime ? '${withT}Z' : '${withT}T00:00:00Z';
    return DateTime.tryParse(iso)?.toUtc();
  }

  /// UTC → hora civil de Ecuador (America/Guayaquil, sin horario de verano).
  static DateTime toEcuador(DateTime value) {
    final utc = value.isUtc ? value : value.toUtc();
    return utc.subtract(_ecuadorOffset);
  }

  static String formatDateTime(DateTime? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    return dateTime.format(toEcuador(value));
  }

  static String formatDate(DateTime? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    return dateOnly.format(toEcuador(value));
  }
}
