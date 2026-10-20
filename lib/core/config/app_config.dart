import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String _customBaseUrl = '';

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Si falla la carga de .env, se usan valores por defecto
    }
  }

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    return dotenv.maybeGet('BASE_URL') ?? 'http://10.0.2.2:8000/api';
  }

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.trim();
  }

  static String get appName =>
      dotenv.maybeGet('APP_NAME') ?? 'Carpintería Móvil';
}
