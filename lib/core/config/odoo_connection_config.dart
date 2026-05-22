/// Configuracion de conexion Odoo (no visible en login).
///
/// Orden de prioridad al iniciar sesion:
/// 1. Valores guardados cifrados en el dispositivo (tras un login previo).
/// 2. `--dart-define=ODOO_BASE_URL=...` y `--dart-define=ODOO_DATABASE=...`
///    (o `dart_defines.json` con `--dart-define-from-file`).
abstract final class OdooConnectionConfig {
  static const String buildTimeBaseUrl = String.fromEnvironment('ODOO_BASE_URL');
  static const String buildTimeDatabase =
      String.fromEnvironment('ODOO_DATABASE');

  static String get defaultBaseUrl => buildTimeBaseUrl;

  static String get defaultDatabase => buildTimeDatabase;

  static bool get hasBuildDefaults =>
      defaultBaseUrl.isNotEmpty && defaultDatabase.isNotEmpty;
}
