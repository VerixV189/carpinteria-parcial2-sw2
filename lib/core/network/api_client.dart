import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:carpinteria_movil_sw2/core/config/app_config.dart';
import 'package:carpinteria_movil_sw2/core/constants/api_constants.dart';
import 'package:carpinteria_movil_sw2/core/errors/app_exception.dart';
import 'package:carpinteria_movil_sw2/core/storage/local_storage.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({
    bool withAuth = true,
    Map<String, String>? extraHeaders,
  }) {
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
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final base = AppConfig.baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$base$path');
    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...queryParams,
    });
  }

  Duration _timeoutFor(String endpoint, Duration? customTimeout) {
    if (customTimeout != null) return customTimeout;
    if (endpoint.contains('/ai/')) return ApiConstants.aiTimeout;
    return ApiConstants.timeout;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .get(
            _buildUri(endpoint, queryParams),
            headers: _buildHeaders(withAuth: withAuth),
          )
          .timeout(_timeoutFor(endpoint, timeout));
      return _processResponse(response);
    } on SocketException {
      throw const NetworkException('Sin conexión con el servidor backend.');
    } on TimeoutException {
      throw const NetworkException(
          'Tiempo de espera agotado al conectar al backend.');
    }
  }

  Future<Uint8List> getBytes(
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
    Duration? timeout,
  }) async {
    try {
      final headers = _buildHeaders(
        withAuth: withAuth,
        extraHeaders: {'Accept': 'application/pdf, application/octet-stream, */*'},
      );
      headers.remove('Content-Type');
      final response = await _client
          .get(
            _buildUri(endpoint, queryParams),
            headers: headers,
          )
          .timeout(_timeoutFor(endpoint, timeout));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      throw ServerException(
        'No se pudo descargar el archivo (${response.statusCode})',
        response.statusCode,
      );
    } on SocketException {
      throw const NetworkException('Sin conexión con el servidor backend.');
    } on TimeoutException {
      throw const NetworkException(
          'Tiempo de espera agotado al descargar archivo.');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUri(endpoint),
            headers: _buildHeaders(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeoutFor(endpoint, timeout));
      return _processResponse(response);
    } on SocketException {
      throw const NetworkException('Sin conexión con el servidor backend.');
    } on TimeoutException {
      throw const NetworkException(
          'Tiempo de espera agotado al conectar al backend.');
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .put(
            _buildUri(endpoint),
            headers: _buildHeaders(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeoutFor(endpoint, timeout));
      return _processResponse(response);
    } on SocketException {
      throw const NetworkException('Sin conexión con el servidor backend.');
    } on TimeoutException {
      throw const NetworkException(
          'Tiempo de espera agotado al conectar al backend.');
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    bool withAuth = true,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .delete(
            _buildUri(endpoint),
            headers: _buildHeaders(withAuth: withAuth),
          )
          .timeout(_timeoutFor(endpoint, timeout));
      return _processResponse(response);
    } on SocketException {
      throw const NetworkException('Sin conexión con el servidor backend.');
    } on TimeoutException {
      throw const NetworkException(
          'Tiempo de espera agotado al conectar al backend.');
    }
  }

  Future<Map<String, dynamic>> graphql(
    String query, {
    Map<String, dynamic>? variables,
    Duration? timeout,
  }) async {
    final res = await post(
      ApiConstants.graphql,
      body: {
        'query': query,
        'variables': ?variables,
      },
      timeout: timeout,
    );
    if (res is Map<String, dynamic>) {
      if (res['errors'] is List && (res['errors'] as List).isNotEmpty) {
        final firstErr = (res['errors'] as List).first;
        final msg = (firstErr is Map && firstErr['message'] != null)
            ? firstErr['message'].toString()
            : 'Error en consulta GraphQL';
        throw ServerException(msg);
      }
      if (res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
      return res;
    }
    throw const ServerException('Respuesta GraphQL inválida');
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    } else if (statusCode == 401 || statusCode == 403) {
      final msg = _extractErrorMessage(decoded) ??
          'No autorizado o credenciales incorrectas.';
      throw AuthException(msg);
    } else {
      final msg =
          _extractErrorMessage(decoded) ?? 'Error del servidor ($statusCode)';
      throw ServerException(msg, statusCode);
    }
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map) {
      final m = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (m is List) return m.join(', ');
      if (m != null) return m.toString();
    }
    return null;
  }
}
