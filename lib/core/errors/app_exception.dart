class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No se pudo conectar con el servidor.']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Credenciales inválidas o sesión expirada.'])
      : super(statusCode: 401);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Error interno del servidor.', int? code])
      : super(statusCode: code);
}
