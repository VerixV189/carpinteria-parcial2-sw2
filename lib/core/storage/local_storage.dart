import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _baseUrlKey = 'custom_base_url';
  static const String _registeredUsersKey = 'local_registered_users';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(_tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> userJson) async {
    await init();
    await _prefs!.setString(_userKey, jsonEncode(userJson));
  }

  static Map<String, dynamic>? getUser() {
    final raw = _prefs?.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    await init();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userKey);
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
