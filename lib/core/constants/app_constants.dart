abstract final class AppConstants {
  static const String appName = 'Gestion Externa';
  static const int defaultPageSize = 50;
  static const Duration rpcTimeout = Duration(seconds: 45);

  static const String keyServerUrl = 'server_url';
  static const String keyDatabase = 'database';
  static const String keyLogin = 'login';
  static const String keyThemeMode = 'theme_mode';

  static const String secureUid = 'odoo_uid';
  static const String securePassword = 'odoo_password';
  static const String secureSessionJson = 'odoo_session';
}
