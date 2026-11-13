import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _sessionPasswordKey = 'auth_session_password';
  static const String _sessionExpiresAtKey = 'auth_session_expires_at';
  static const String _biometricCredentialsKey = 'biometric_saved_credentials';
  static const String _biometricAccountsByEmailKey =
      'biometric_accounts_by_email';
  static const String _baseUrlKey = 'custom_base_url';
  static const String _forceOfflineKey = 'force_offline_mode';
  static const String _registeredUsersKey = 'local_registered_users';
  static const String _quotationOverridesKey = 'local_quotation_overrides';
  static const String _seenQuotationSigsKey = 'seen_quotation_signatures';

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

  static Future<void> saveSessionPassword(String password) async {
    await init();
    await _prefs!.setString(_sessionPasswordKey, password);
  }

  static String? getSessionPassword() {
    return _prefs?.getString(_sessionPasswordKey);
  }

  static Map<String, Map<String, dynamic>> _getBiometricAccountsMap() {
    final raw = _prefs?.getString(_biometricAccountsByEmailKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveBiometricCredentials({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    await init();
    final key = email.trim().toLowerCase();
    final payload = {
      'email': email.trim(),
      'password': password,
      'name': name,
      'role': role,
      'expiresAt': DateTime.now().add(biometricTtl).millisecondsSinceEpoch,
    };
    final map = _getBiometricAccountsMap();
    map[key] = payload;
    await _prefs!.setString(_biometricAccountsByEmailKey, jsonEncode(map));
    await _prefs!.setString(_biometricCredentialsKey, jsonEncode(payload));
  }

  static Future<void> removeBiometricForEmail(String email) async {
    await init();
    final key = email.trim().toLowerCase();
    final map = _getBiometricAccountsMap();
    map.remove(key);
    await _prefs!.setString(_biometricAccountsByEmailKey, jsonEncode(map));
    final currentLast = getBiometricCredentials();
    if (currentLast != null &&
        (currentLast['email'] as String?)?.trim().toLowerCase() == key) {
      await _prefs!.remove(_biometricCredentialsKey);
    }
  }

  static bool isBiometricEnrolledForEmail(String email) {
    return getBiometricAccountForEmail(email) != null;
  }

  static Map<String, dynamic>? getBiometricAccountForEmail(String email) {
    final key = email.trim().toLowerCase();
    if (key.isEmpty) return null;
    final map = _getBiometricAccountsMap();
    final entry = map[key];
    if (entry != null) {
      final expiresAt = entry['expiresAt'] as int?;
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return null;
      }
      return entry;
    }
    final last = getBiometricCredentials();
    if (last != null &&
        (last['email'] as String?)?.trim().toLowerCase() == key) {
      return last;
    }
    return null;
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
    await _prefs!.remove(_sessionPasswordKey);
    await _prefs!.remove(_sessionExpiresAtKey);
  }

  static Future<void> saveCustomBaseUrl(String url) async {
    await init();
    await _prefs!.setString(_baseUrlKey, url);
  }

  static String? getCustomBaseUrl() {
    return _prefs?.getString(_baseUrlKey);
  }

  static Future<void> saveForceOfflineMode(bool value) async {
    await init();
    await _prefs!.setBool(_forceOfflineKey, value);
  }

  static bool getForceOfflineMode() {
    return _prefs?.getBool(_forceOfflineKey) ?? false;
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

  static Map<String, Map<String, dynamic>> getQuotationOverrides() {
    final raw = _prefs?.getString(_quotationOverridesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveQuotationOverride(
    String quotationId,
    Map<String, dynamic> data,
  ) async {
    await init();
    final map = getQuotationOverrides();
    final existing = map[quotationId] ?? <String, dynamic>{};
    map[quotationId] = {
      ...existing,
      ...data,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs!.setString(_quotationOverridesKey, jsonEncode(map));
  }

  static Map<String, String> getSeenQuotationSignatures(String userKey) {
    final raw = _prefs?.getString('$_seenQuotationSigsKey:$userKey');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveSeenQuotationSignatures(
    String userKey,
    Map<String, String> signatures,
  ) async {
    await init();
    await _prefs!.setString(
      '$_seenQuotationSigsKey:$userKey',
      jsonEncode(signatures),
    );
  }
}
