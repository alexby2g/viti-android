import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/secure_session_store.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._store, {http.Client? client}) : _client = client ?? http.Client();

  final SecureSessionStore _store;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}${path.startsWith('/') ? path : '/$path'}');

  Future<Map<String, dynamic>> getJson(String path, {bool authenticated = true}) {
    return _send('GET', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await _store.token();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, _uri(path))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) decoded = value;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        (decoded['message'] as String?) ?? 'VITI no pudo completar la solicitud.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
