import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/storage/secure_session_store.dart';
import 'core/theme/appearance_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/session_controller.dart';
import 'features/data/viti_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SecureSessionStore();
  final api = ApiClient(store);
  final authRepository = AuthRepository(api, store);
  final session = SessionController(authRepository);
  final repository = VitiRepository(api);
  final appearance = AppearanceController();

  await Future.wait([
    session.initialize(),
    appearance.initialize(),
  ]);

  runApp(VitiApp(
    session: session,
    repository: repository,
    appearance: appearance,
  ));
}
