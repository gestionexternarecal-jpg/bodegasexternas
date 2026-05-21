import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/update_config.dart';
import '../models/app_update_manifest.dart';

/// Comprueba si hay una version mas reciente publicada en el manifest.
class UpdateCheckService {
  UpdateCheckService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<PackageInfo> getPackageInfo() => PackageInfo.fromPlatform();

  Future<String> formatVersionLabel() async {
    final info = await getPackageInfo();
    return 'v${info.version} (${info.buildNumber})';
  }

  /// `null` si no hay actualizacion o no se pudo comprobar.
  Future<AppUpdateManifest?> checkForUpdate() async {
    if (!UpdateConfig.isEnabled) return null;

    try {
      final info = await getPackageInfo();
      final installedBuild = int.tryParse(info.buildNumber) ?? 0;

      final response = await _dio.get<Map<String, dynamic>>(
        UpdateConfig.manifestUrl,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data;
      if (data == null) return null;

      final manifest = AppUpdateManifest.fromJson(data);
      if (manifest.build > installedBuild && manifest.downloadUrl.isNotEmpty) {
        return manifest;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
