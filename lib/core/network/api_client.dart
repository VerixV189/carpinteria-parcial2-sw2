import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/constants/api_constants.dart';
import 'package:carpinteria_movil_sw2/core/errors/app_exception.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = LocalStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path').replace(queryParameters: queryParams);
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    try {
      final response = await _client
          .get(
            _buildUri(endpoint, queryParams),
            headers: _buildHeaders(withAuth: withAuth),
          )
          .timeout(ApiConstants.timeout);
      return _processResponse(response);
    } on SocketException {
      throw const NetworkException('Sin conexión con el servidor backend.');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al conectar al backend.');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUri(endpoint),
            headers: _buildHeaders(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.timeout);
      return _processResponse(response);
    } on SocketException {
      throw const NetworkException('Sin conexión con el servidor backend.');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al conectar al backend.');
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final response = await _client
          .put(
            _buildUri(endpoint),
            headers: _buildHeaders(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.timeout);
      return _processResponse(response);
    } on SocketException {
      throw const NetworkException('Sin conexión con el servidor backend.');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al conectar al backend.');
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    } else if (statusCode == 401 || statusCode == 403) {
      final msg = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'No autorizado o credenciales incorrectas.';
      throw AuthException(msg);
    } else {
      final msg = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Error del servidor ($statusCode)';
      throw ServerException(msg, statusCode);
    }
  }
}
