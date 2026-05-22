import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'odoo_rpc_client.dart';

/// Descarga reportes PDF de Odoo via HTTP (sesion web), sin RPC privado.
class OdooReportDownloader {
  OdooReportDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final _url = OdooRpcClient(dio: Dio());

  Future<Uint8List> downloadPdf({
    required String baseUrl,
    required String database,
    required String login,
    required String password,
    required List<String> reportNames,
    required List<int> documentIds,
  }) async {
    if (documentIds.isEmpty) {
      throw const OdooRpcException('Sin documentos para imprimir');
    }

    final root = _url.normalizeUrl(baseUrl);
    final cookie = await _webSessionCookie(
      root: root,
      database: database,
      login: login,
      password: password,
    );

    final idsPath = documentIds.join(',');
    AppException? lastError;

    for (final reportName in reportNames) {
      try {
        final bytes = await _fetchReportBytes(
          root: root,
          cookie: cookie,
          path: '/report/pdf/$reportName/$idsPath',
        );
        return bytes;
      } on AppException catch (e) {
        lastError = e;
      }
    }

    throw lastError ??
        const OdooRpcException(
          'No se pudo descargar el PDF. Verifique el reporte en Odoo.',
        );
  }

  Future<String> _webSessionCookie({
    required String root,
    required String database,
    required String login,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$root/web/session/authenticate',
      data: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'db': database,
          'login': login,
          'password': password,
        },
        'id': 1,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    final result = response.data?['result'];
    if (result is! Map || result['uid'] == null || result['uid'] == false) {
      throw const AuthException('No se pudo autenticar para imprimir');
    }

    final sessionId = _extractSessionId(response.headers);
    if (sessionId == null || sessionId.isEmpty) {
      throw const NetworkException(
        'Odoo no devolvio sesion web para descargar el reporte',
      );
    }
    return 'session_id=$sessionId';
  }

  String? _extractSessionId(Headers headers) {
    final cookies = headers.map['set-cookie'];
    if (cookies == null) return null;

    final Iterable<String> values = switch (cookies) {
      final List<dynamic> list => list.map((e) => e.toString()),
      _ => [cookies.toString()],
    };
    for (final raw in values) {
      final match = RegExp(r'session_id=([^;,\s]+)').firstMatch(raw);
      if (match != null) return match.group(1);
    }
    return null;
  }

  Future<Uint8List> _fetchReportBytes({
    required String root,
    required String cookie,
    required String path,
  }) async {
    final response = await _dio.get<List<int>>(
      '$root$path',
      options: Options(
        headers: {'Cookie': cookie},
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw OdooRpcException(
        'Error HTTP ${response.statusCode} al descargar reporte',
      );
    }

    final bytes = Uint8List.fromList(response.data!);
    if (!_isPdf(bytes)) {
      final preview = utf8.decode(bytes.take(200).toList(), allowMalformed: true);
      if (preview.toLowerCase().contains('login')) {
        throw const AuthException('Sesion expirada al generar PDF');
      }
      throw const OdooRpcException(
        'La respuesta del servidor no es un PDF valido',
      );
    }
    return bytes;
  }

  bool _isPdf(Uint8List bytes) =>
      bytes.length > 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}
