/// Manifest remoto (`version.json`) para avisar de nuevas versiones.
class AppUpdateManifest {
  const AppUpdateManifest({
    required this.version,
    required this.build,
    required this.downloadUrl,
    this.releaseNotes = '',
  });

  final String version;
  final int build;
  final String downloadUrl;
  final String releaseNotes;

  factory AppUpdateManifest.fromJson(Map<String, dynamic> json) {
    return AppUpdateManifest(
      version: json['version'] as String? ?? '0.0.0',
      build: _parseBuild(json['build']),
      downloadUrl: json['download_url'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
    );
  }

  static int _parseBuild(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
