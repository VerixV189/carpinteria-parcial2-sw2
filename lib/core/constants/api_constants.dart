class ApiConstants {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';

  // Carpintería endpoints
  static const String products = '/productos';
  static const String categories = '/categorias';
  static const String orders = '/pedidos';
  static const String materials = '/materiales';
  static const String voiceReports = '/reportes-voz';

  // Timeouts
  static const Duration timeout = Duration(seconds: 8);
}
