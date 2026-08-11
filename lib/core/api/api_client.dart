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

  Future<int?> selectedCompanyId() => _store.companyId();
  Future<void> selectCompany(int? companyId) => _store.saveCompanyId(companyId);

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

  Future<Map<String, String>> _headers({required bool authenticated, bool json = true}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    if (authenticated) {
      final token = await _store.token();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final companyId = await _store.companyId();
      if (companyId != null) headers['X-VITI-Empresa'] = '$companyId';
    }
    return headers;
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String> fields = const <String, String>{},
    required String fileField,
    required String filePath,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(await _headers(authenticated: true, json: false));
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath, filename: fileName));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final request = http.Request(method, _uri(path))
      ..headers.addAll(await _headers(authenticated: authenticated));
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) decoded = value;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? validationMessage;
      final errors = decoded['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            validationMessage = value.first.toString();
            break;
          }
        }
      }
      throw ApiException(
        validationMessage ?? (decoded['message'] as String?) ?? 'VITI no pudo completar la solicitud.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
