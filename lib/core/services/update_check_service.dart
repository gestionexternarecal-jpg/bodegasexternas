import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/update_config.dart';
import '../models/app_update_manifest.dart';
import '../models/update_check_result.dart';

/// Comprueba si hay una version mas reciente publicada en el manifest.
class UpdateCheckService {
  UpdateCheckService({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    final dio = Dio();
    dio.options.headers['User-Agent'] = 'GestionExterna-UpdateCheck/1.0';
    dio.options.headers['Accept'] = 'application/json, text/plain, */*';
    return dio;
  }

  Future<PackageInfo> getPackageInfo() => PackageInfo.fromPlatform();

  Future<String> formatVersionLabel() async {
    final info = await getPackageInfo();
    return 'v${info.version} (${info.buildNumber})';
  }

  /// Comprobacion detallada (para UI y depuracion).
  Future<UpdateCheckResult> checkForUpdateDetailed() async {
    if (!UpdateConfig.isEnabled) {
      return const UpdateCheckResult(
        status: UpdateCheckStatus.disabled,
        message: 'Actualizaciones no configuradas en este instalador.',
      );
    }

    final info = await getPackageInfo();
    final installedBuild = int.tryParse(info.buildNumber) ?? 0;

    Object? lastError;
    for (final url in UpdateConfig.manifestUrlsToTry) {
      try {
        final manifest = await _fetchManifest(url);
        if (manifest == null) continue;

        if (manifest.build > installedBuild &&
            manifest.downloadUrl.isNotEmpty) {
          return UpdateCheckResult(
            status: UpdateCheckStatus.updateAvailable,
            manifest: manifest,
            message:
                'Nueva version ${manifest.version} (build ${manifest.build}).',
          );
        }

        return UpdateCheckResult(
          status: UpdateCheckStatus.upToDate,
          message:
              'Instalado: build $installedBuild. Servidor: build ${manifest.build}.',
        );
      } catch (e) {
        lastError = e;
      }
    }

    return UpdateCheckResult(
      status: UpdateCheckStatus.networkError,
      message:
          'No se pudo leer el manifest. Compruebe internet o acceso a GitHub.\n'
          '$lastError',
    );
  }

  /// `null` si no hay actualizacion o no se pudo comprobar.
  Future<AppUpdateManifest?> checkForUpdate() async {
    final result = await checkForUpdateDetailed();
    if (result.status == UpdateCheckStatus.updateAvailable) {
      return result.manifest;
    }
    return null;
  }

  Future<AppUpdateManifest?> _fetchManifest(String url) async {
    final response = await _dio.get<dynamic>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'HTTP ${response.statusCode}',
      );
    }

    final map = _parseManifestBody(response.data);
    if (map == null) {
      throw const FormatException('Manifest vacio o no es JSON valido');
    }
    return AppUpdateManifest.fromJson(map);
  }

  /// GitHub sirve version.json como texto; a veces Dio devuelve String en lugar de Map.
  static Map<String, dynamic>? _parseManifestBody(dynamic body) {
    if (body == null) return null;

    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);

    final text = body.toString().trim().replaceFirst('\uFEFF', '');
    if (text.isEmpty) return null;

    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);

    return null;
  }
}
