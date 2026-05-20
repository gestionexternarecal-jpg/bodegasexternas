import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await _prefs.setString(AppConstants.keyServerUrl, baseUrl);
    await _prefs.setString(AppConstants.keyDatabase, database);
    await _prefs.setString(AppConstants.keyLogin, login);
  }

  ({String? url, String? db, String? login}) readConnectionPrefs() {
    return (
      url: _prefs.getString(AppConstants.keyServerUrl),
      db: _prefs.getString(AppConstants.keyDatabase),
      login: _prefs.getString(AppConstants.keyLogin),
    );
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
}
