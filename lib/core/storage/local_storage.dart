import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _sessionExpiresAtKey = 'auth_session_expires_at';
  static const String _biometricCredentialsKey = 'biometric_saved_credentials';
  static const String _baseUrlKey = 'custom_base_url';
  static const String _registeredUsersKey = 'local_registered_users';

  /// Duración estándar de la sesión activa abierta (24 horas)
  static const Duration sessionTtl = Duration(hours: 24);

  /// Duración de la vinculación con huella digital (7 días)
  static const Duration biometricTtl = Duration(days: 7);

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(_tokenKey, token);
    final expiresAt = DateTime.now().add(sessionTtl).millisecondsSinceEpoch;
    await _prefs!.setInt(_sessionExpiresAtKey, expiresAt);
  }

  static String? getToken() {
    if (isSessionExpired()) return null;
    return _prefs?.getString(_tokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> userJson) async {
    await init();
    await _prefs!.setString(_userKey, jsonEncode(userJson));
    final expiresAt = DateTime.now().add(sessionTtl).millisecondsSinceEpoch;
    await _prefs!.setInt(_sessionExpiresAtKey, expiresAt);
  }

  static Map<String, dynamic>? getUser() {
    if (isSessionExpired()) return null;
    final raw = _prefs?.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static bool isSessionExpired() {
    final expiresAtMs = _prefs?.getInt(_sessionExpiresAtKey);
    if (expiresAtMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAtMs;
  }

  static DateTime? getSessionExpiresAt() {
    final expiresAtMs = _prefs?.getInt(_sessionExpiresAtKey);
    if (expiresAtMs == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
  }

  static Future<void> saveBiometricCredentials({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    await init();
    final payload = {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
      'expiresAt': DateTime.now().add(biometricTtl).millisecondsSinceEpoch,
    };
    await _prefs!.setString(_biometricCredentialsKey, jsonEncode(payload));
  }

  static Map<String, dynamic>? getBiometricCredentials() {
    final raw = _prefs?.getString(_biometricCredentialsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = map['expiresAt'] as int?;
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return null;
      }
      return map;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    await init();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userKey);
    await _prefs!.remove(_sessionExpiresAtKey);
  }

  static Future<void> saveCustomBaseUrl(String url) async {
    await init();
    await _prefs!.setString(_baseUrlKey, url);
  }

  static String? getCustomBaseUrl() {
    return _prefs?.getString(_baseUrlKey);
  }

  static List<Map<String, dynamic>> getRegisteredUsers() {
    final raw = _prefs?.getString(_registeredUsersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveRegisteredUser(Map<String, dynamic> userWithPass) async {
    await init();
    final users = getRegisteredUsers();
    users.removeWhere((u) => u['email'] == userWithPass['email']);
    users.add(userWithPass);
    await _prefs!.setString(_registeredUsersKey, jsonEncode(users));
  }
}
