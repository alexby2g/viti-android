import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/storage/secure_session_store.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SecureSessionStore();
  final api = ApiClient(store);
  final repository = AuthRepository(api, store);
  final session = SessionController(repository);
  await session.initialize();

  runApp(VitiApp(session: session));
}
