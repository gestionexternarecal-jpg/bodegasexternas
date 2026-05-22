import 'app_update_manifest.dart';

enum UpdateCheckStatus {
  /// Sin URL de manifest en el build.
  disabled,

  /// No hay version mas reciente.
  upToDate,

  /// Hay version nueva en el manifest.
  updateAvailable,

  /// No se pudo leer el manifest (red, firewall, URL incorrecta).
  networkError,
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    this.manifest,
    this.message,
  });

  final UpdateCheckStatus status;
  final AppUpdateManifest? manifest;
  final String? message;
}
