/// URL del manifest de actualizaciones (compilado con --dart-define).
abstract final class UpdateConfig {
  static const String manifestUrl =
      String.fromEnvironment('UPDATE_MANIFEST_URL');

  static bool get isEnabled => manifestUrl.isNotEmpty;
}
