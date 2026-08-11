import '../../core/api/api_client.dart';
import '../../core/platform/native_device.dart';
import '../../core/storage/secure_session_store.dart';
import 'session_user.dart';

class AuthRepository {
  AuthRepository(this._api, this._store);

  final ApiClient _api;
  final SecureSessionStore _store;

  Future<SessionUser> login({
    required String access,
    required String password,
    String adminSecret = '',
  }) async {
    final deviceId = await _store.deviceId();
    final response = await _api.postJson('/mobile/login', {
      'acceso': access.trim(),
      'password': password,
      'codigo_secreto': adminSecret.trim().isEmpty ? null : adminSecret.trim(),
      'device_id': deviceId,
      'device_name': NativeDevice.displayName,
      'platform': NativeDevice.platform,
    }, authenticated: false);

    final token = response['token']?.toString();
    final rawUser = response['usuario'];
    if (token == null || token.isEmpty || rawUser is! Map<String, dynamic>) {
      throw const ApiException('El servidor no devolvió una sesión válida.');
    }
    await _store.saveSession(token, rawUser);
    return SessionUser.fromJson(rawUser);
  }

  Future<SessionUser?> restore() async {
    final token = await _store.token();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _api.getJson('/auth/me');
      final rawUser = response['usuario'];
      if (rawUser is! Map<String, dynamic>) return null;
      await _store.saveUser(rawUser);
      return SessionUser.fromJson(rawUser);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _store.clearSession();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/mobile/logout', const <String, dynamic>{});
    } catch (_) {
      // El cierre local siempre continúa aunque el servidor no responda.
    } finally {
      await _store.clearSession();
    }
  }
}
