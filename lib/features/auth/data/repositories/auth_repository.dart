import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/odoo_rpc_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/odoo_session.dart';
import '../datasources/session_storage.dart';

class AuthRepository {
  AuthRepository(this._rpc, this._storage);

  final OdooRpcClient _rpc;
  final SessionStorage _storage;

  Future<({String? url, String? db, String? login})> loadSavedPrefs() =>
      _storage.readConnectionPrefs();

  Future<Result<OdooSession>> login({
    required String baseUrl,
    required String database,
    required String username,
    required String password,
    bool rememberConnection = true,
  }) async {
    try {
      final normalizedUrl = _rpc.normalizeUrl(baseUrl);
      final uid = await _rpc.authenticate(
        baseUrl: normalizedUrl,
        database: database.trim(),
        login: username.trim(),
        password: password,
      );

      final session = OdooSession(
        baseUrl: normalizedUrl,
        database: database.trim(),
        login: username.trim(),
        uid: uid,
        displayName: username.trim(),
      );

      await _storage.saveSession(session, password);
      if (rememberConnection) {
        await _storage.saveConnectionPrefs(
          baseUrl: normalizedUrl,
          database: database.trim(),
          login: username.trim(),
        );
      }

      return Success(session);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al iniciar sesion: $e'));
    }
  }

  Future<Result<({OdooSession session, String password})>> restoreSession() async {
    try {
      final loaded = await _storage.loadSession();
      if (loaded == null) {
        return Failure(AuthException('No hay sesion guardada'));
      }
      // Verificar que la sesion sigue valida
      await _rpc.authenticate(
        baseUrl: loaded.session.baseUrl,
        database: loaded.session.database,
        login: loaded.session.login,
        password: loaded.password,
      );
      return Success(loaded);
    } on AppException catch (e) {
      await _storage.clearSession();
      return Failure(e);
    } catch (e) {
      await _storage.clearSession();
      return Failure(OdooRpcException('Sesion invalida: $e'));
    }
  }

  Future<void> logout() => _storage.clearSession();

  Future<Result<bool>> testConnection({
    required String baseUrl,
    required String database,
    required String username,
    required String password,
  }) async {
    final result = await login(
      baseUrl: baseUrl,
      database: database,
      username: username,
      password: password,
      rememberConnection: false,
    );
    switch (result) {
      case Success():
        await logout();
        return const Success(true);
      case Failure(:final error):
        return Failure(error);
    }
  }
}
