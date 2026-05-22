/// URL del manifest de actualizaciones (compilado con --dart-define).
abstract final class UpdateConfig {
  /// Opcional: URL fija (ej. carpeta propia). Si vacio, solo se usa [latestManifestUrl].
  static const String manifestUrl =
      String.fromEnvironment('UPDATE_MANIFEST_URL');

  /// Siempre apunta al manifest del ultimo Release en GitHub (mismo nombre de archivo).
  static const String latestManifestUrl =
      'https://github.com/gestionexternarecal-jpg/bodegasexternas/releases/latest/download/version.json';

  static bool get isEnabled =>
      manifestUrl.isNotEmpty || latestManifestUrl.isNotEmpty;

  /// URLs a probar, sin duplicados. Primero "latest", luego la URL personalizada.
  static List<String> get manifestUrlsToTry {
    final urls = <String>[latestManifestUrl];
    if (manifestUrl.isNotEmpty && !urls.contains(manifestUrl)) {
      urls.add(manifestUrl);
    }
    return urls;
  }
}
