import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../platform/native_device.dart';

class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'viti_token';
  static const _userKey = 'viti_user';
  static const _deviceKey = 'viti_device_id';

  final FlutterSecureStorage _storage;

  Future<String?> token() => _storage.read(key: _tokenKey);

  Future<Map<String, dynamic>?> user() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    await _storage.write(key: _tokenKey, value: token);
    await saveUser(user);
  }

  Future<void> saveUser(Map<String, dynamic> user) {
    return _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null && existing.length >= 8) return existing;
    final created = NativeDevice.randomId();
    await _storage.write(key: _deviceKey, value: created);
    return created;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
