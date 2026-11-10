import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String _customBaseUrl = '';
  static bool _forceOfflineMode = false;

  static bool get forceOfflineMode => _forceOfflineMode;

  static void setForceOfflineMode(bool value) {
    _forceOfflineMode = value;
  }

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Si falla la carga de .env, se usan valores por defecto
    }
  }

  static String? _safeGetEnv(String key) {
    try {
      if (!dotenv.isInitialized) return null;
      return dotenv.maybeGet(key);
    } catch (_) {
      return null;
    }
  }

  static String normalizeBaseUrl(String raw) {
    var clean = raw.trim();
    if (clean.isEmpty) return 'http://10.0.2.2:3000';
    // Migrar automáticamente el antiguo puerto de prueba 8000/api al Gateway NestJS :3000
    if (clean == 'http://10.0.2.2:8000/api' ||
        clean == 'http://10.0.2.2:8000' ||
        clean == 'http://localhost:8000/api') {
      clean = 'http://10.0.2.2:3000';
    }
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (clean.endsWith('/api')) {
      clean = clean.substring(0, clean.length - 4);
    }
    return clean;
  }

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return normalizeBaseUrl(_customBaseUrl);
    final envUrl = _safeGetEnv('BASE_URL') ?? 'http://10.0.2.2:3000';
    return normalizeBaseUrl(envUrl);
  }

  static String get wsBaseUrl {
    final base = baseUrl;
    if (base.startsWith('https://')) {
      return 'wss://${base.substring(8)}';
    }
    if (base.startsWith('http://')) {
      return 'ws://${base.substring(7)}';
    }
    return 'ws://$base';
  }

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = normalizeBaseUrl(url);
  }

  static String get appName =>
      _safeGetEnv('APP_NAME') ?? 'Carpintería El Roble';
}
