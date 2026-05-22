import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/session_storage.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/domain/entities/odoo_session.dart';
import '../../features/transfers/data/repositories/transfers_repository.dart';
import '../network/odoo_rpc_client.dart';

final odooRpcClientProvider = Provider<OdooRpcClient>((ref) {
  return OdooRpcClient();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final sessionStorageProvider = FutureProvider<SessionStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  const secure = FlutterSecureStorage();
  return SessionStorage(prefs, secure);
});

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final storage = await ref.watch(sessionStorageProvider.future);
  return AuthRepository(ref.watch(odooRpcClientProvider), storage);
});

final transfersRepositoryProvider = Provider<TransfersRepository>((ref) {
  return TransfersRepository(ref.watch(odooRpcClientProvider));
});

/// Sesion activa + contraseña (solo en memoria tras login; password desde secure storage).
class ActiveSession {
  const ActiveSession({required this.session, required this.password});
  final OdooSession session;
  final String password;
}

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSession?>((ref) {
  return ActiveSessionNotifier(ref);
});

class ActiveSessionNotifier extends StateNotifier<ActiveSession?> {
  ActiveSessionNotifier(this._ref) : super(null);

  final Ref _ref;

  Future<void> setSession(OdooSession session, String password) async {
    state = ActiveSession(session: session, password: password);
  }

  Future<void> clear() async {
    final repo = await _ref.read(authRepositoryProvider.future);
    await repo.logout();
    _ref.read(transfersRepositoryProvider).clearCache();
    state = null;
  }
}

final appThemeModeProvider =
    StateNotifierProvider<AppThemeModeNotifier, AppThemeMode>((ref) {
  return AppThemeModeNotifier(ref);
});

enum AppThemeMode { light, dark, system }

class AppThemeModeNotifier extends StateNotifier<AppThemeMode> {
  AppThemeModeNotifier(this._ref) : super(AppThemeMode.system) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final value = prefs.getString('theme_mode');
    state = switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
      'theme_mode',
      switch (mode) {
        AppThemeMode.light => 'light',
        AppThemeMode.dark => 'dark',
        AppThemeMode.system => 'system',
      },
    );
  }
}
