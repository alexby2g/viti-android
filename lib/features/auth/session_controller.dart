import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import 'auth_repository.dart';
import 'session_user.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._repository);

  final AuthRepository _repository;
  SessionUser? user;
  bool busy = false;
  String? error;

  bool get authenticated => user != null;

  Future<void> initialize() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _repository.restore();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'No pudimos comprobar la sesión guardada.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> login(String access, String password, String adminSecret) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _repository.login(
        access: access,
        password: password,
        adminSecret: adminSecret,
      );
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'No pudimos conectar con VITI. Revisa tu conexión.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    busy = true;
    notifyListeners();
    await _repository.logout();
    user = null;
    busy = false;
    notifyListeners();
  }
}
