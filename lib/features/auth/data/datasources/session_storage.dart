import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/odoo_connection_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/odoo_session.dart';

class SessionStorage {
  SessionStorage(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  Future<void> saveConnectionPrefs({
    required String baseUrl,
    required String database,
    required String login,
  }) async {
    await _secure.write(
      key: AppConstants.secureServerUrl,
      value: baseUrl,
    );
    await _secure.write(
      key: AppConstants.secureDatabase,
      value: database,
    );
    await _secure.write(
      key: AppConstants.secureLogin,
      value: login,
    );
    await _prefs.setString(AppConstants.keyLogin, login);
    await _clearLegacyConnectionPrefs();
  }

  Future<({String? url, String? db, String? login})> readConnectionPrefs() async {
    await _migrateConnectionPrefsFromPrefsIfNeeded();

    var url = await _secure.read(key: AppConstants.secureServerUrl);
    var db = await _secure.read(key: AppConstants.secureDatabase);
    var login = await _secure.read(key: AppConstants.secureLogin);

    login ??= _prefs.getString(AppConstants.keyLogin);

    url = _firstNonEmpty(url, OdooConnectionConfig.defaultBaseUrl);
    db = _firstNonEmpty(db, OdooConnectionConfig.defaultDatabase);

    return (url: _nullableIfEmpty(url), db: _nullableIfEmpty(db), login: login);
  }

  Future<void> saveSession(OdooSession session, String password) async {
    await _secure.write(
      key: AppConstants.secureSessionJson,
      value: jsonEncode(session.toJson()),
    );
    await _secure.write(
      key: AppConstants.securePassword,
      value: password,
    );
    await saveConnectionPrefs(
      baseUrl: session.baseUrl,
      database: session.database,
      login: session.login,
    );
  }

  Future<({OdooSession session, String password})?> loadSession() async {
    final sessionJson = await _secure.read(key: AppConstants.secureSessionJson);
    final password = await _secure.read(key: AppConstants.securePassword);
    if (sessionJson == null || password == null) return null;
    final map = jsonDecode(sessionJson) as Map<String, dynamic>;
    return (session: OdooSession.fromJson(map), password: password);
  }

  Future<void> clearSession() async {
    await _secure.delete(key: AppConstants.secureSessionJson);
    await _secure.delete(key: AppConstants.securePassword);
  }

  Future<void> _migrateConnectionPrefsFromPrefsIfNeeded() async {
    final legacyUrl = _prefs.getString(AppConstants.keyServerUrl);
    final legacyDb = _prefs.getString(AppConstants.keyDatabase);
    if (legacyUrl == null && legacyDb == null) return;

    final existingUrl = await _secure.read(key: AppConstants.secureServerUrl);
    if (existingUrl == null && legacyUrl != null && legacyUrl.isNotEmpty) {
      await _secure.write(key: AppConstants.secureServerUrl, value: legacyUrl);
    }

    final existingDb = await _secure.read(key: AppConstants.secureDatabase);
    if (existingDb == null && legacyDb != null && legacyDb.isNotEmpty) {
      await _secure.write(key: AppConstants.secureDatabase, value: legacyDb);
    }

    await _clearLegacyConnectionPrefs();
  }

  Future<void> _clearLegacyConnectionPrefs() async {
    await _prefs.remove(AppConstants.keyServerUrl);
    await _prefs.remove(AppConstants.keyDatabase);
  }

  static String? _nullableIfEmpty(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static String? _firstNonEmpty(String? a, String b) {
    if (a != null && a.isNotEmpty) return a;
    if (b.isNotEmpty) return b;
    return null;
  }
}
