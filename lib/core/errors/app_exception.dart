sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Error de conexion con el servidor']);
}

final class AuthException extends AppException {
  const AuthException([super.message = 'Credenciales invalidas o sesion expirada']);
}

final class OdooRpcException extends AppException {
  const OdooRpcException(super.message, {this.odooError});
  final dynamic odooError;
}

final class AccessDeniedException extends AppException {
  const AccessDeniedException([
    super.message = 'No tiene permisos para esta operacion en Odoo',
  ]);
}
