import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

/// Cliente JSON-RPC para Odoo (`/jsonrpc`).
class OdooRpcClient {
  OdooRpcClient({Dio? dio, Logger? logger})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppConstants.rpcTimeout,
                receiveTimeout: AppConstants.rpcTimeout,
                headers: {'Content-Type': 'application/json'},
              ),
            ),
        _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final Dio _dio;
  final Logger _log;
  int _requestId = 0;

  String normalizeUrl(String url) {
    var base = url.trim();
    if (base.isEmpty) throw const NetworkException('URL del servidor requerida');
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'https://$base';
    }
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  Future<int> authenticate({
    required String baseUrl,
    required String database,
    required String login,
    required String password,
  }) async {
    final uid = await _call<int>(
      baseUrl: baseUrl,
      service: 'common',
      method: 'authenticate',
      args: [database, login, password, <String, dynamic>{}],
    );
    if (uid == 0) {
      throw const AuthException('Usuario o contraseña incorrectos');
    }
    return uid;
  }

  Future<T> executeKw<T>({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    return _call<T>(
      baseUrl: baseUrl,
      service: 'object',
      method: 'execute_kw',
      args: [database, uid, password, model, method, args, kwargs],
    );
  }

  Future<List<Map<String, dynamic>>> searchRead({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String model,
    List<dynamic> domain = const [],
    List<String> fields = const [],
    int offset = 0,
    int limit = AppConstants.defaultPageSize,
    String? order,
  }) async {
    final kwargs = <String, dynamic>{
      'domain': domain,
      'fields': fields,
      'offset': offset,
      'limit': limit,
    };
    if (order != null) kwargs['order'] = order;

    final raw = await executeKw<dynamic>(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      model: model,
      method: 'search_read',
      args: const [],
      kwargs: kwargs,
    );

    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<int> create({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String model,
    required Map<String, dynamic> values,
  }) async {
    final result = await executeKw<dynamic>(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      model: model,
      method: 'create',
      args: [values],
    );
    if (result is int) return result;
    throw OdooRpcException('Respuesta create invalida: $result');
  }

  Future<bool> unlink({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String model,
    required List<int> ids,
  }) async {
    if (ids.isEmpty) return true;
    final result = await executeKw<dynamic>(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      model: model,
      method: 'unlink',
      args: [ids],
    );
    return result == true;
  }

  Future<bool> write({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String model,
    required List<int> ids,
    required Map<String, dynamic> values,
  }) async {
    final result = await executeKw<dynamic>(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      model: model,
      method: 'write',
      args: [ids, values],
    );
    return result == true;
  }

  Future<dynamic> callModelMethod({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    return executeKw<dynamic>(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      model: model,
      method: method,
      args: args,
      kwargs: kwargs,
    );
  }

  Future<T> _call<T>({
    required String baseUrl,
    required String service,
    required String method,
    required List<dynamic> args,
  }) async {
    final url = '${normalizeUrl(baseUrl)}/jsonrpc';
    _requestId++;
    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'service': service,
        'method': method,
        'args': args,
      },
      'id': _requestId,
    };

    try {
      _log.d('RPC $service.$method -> $url');
      final response = await _dio.post<Map<String, dynamic>>(url, data: payload);
      final data = response.data;
      if (data == null) {
        throw const NetworkException('Respuesta vacia del servidor');
      }
      if (data['error'] != null) {
        throw _mapRpcError(data['error']);
      }
      final result = data['result'];
      if (result is T) return result;
      return result as T;
    } on DioException catch (e) {
      _log.e('Dio error', error: e.message);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException('Tiempo de espera agotado');
      }
      throw NetworkException(e.message ?? 'Error de red');
    } on AppException {
      rethrow;
    } catch (e) {
      throw OdooRpcException('Error inesperado: $e');
    }
  }

  AppException _mapRpcError(dynamic error) {
    if (error is! Map) return OdooRpcException(error.toString());

    final data = error['data'];
    final message = error['message']?.toString() ?? 'Error RPC';
    if (data is Map) {
      final name = data['name']?.toString() ?? '';
      final debug = data['message']?.toString() ?? message;
      if (name.contains('AccessDenied') || debug.contains('Access')) {
        return AccessDeniedException(debug);
      }
      return OdooRpcException(debug, odooError: error);
    }
    return OdooRpcException(message, odooError: error);
  }
}
