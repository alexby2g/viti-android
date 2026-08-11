import 'package:flutter/material.dart';

import 'core/theme/appearance_controller.dart';
import 'core/theme/viti_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/session_controller.dart';
import 'features/data/viti_repository.dart';
import 'features/home/home_shell.dart';

class VitiApp extends StatelessWidget {
  const VitiApp({
    required this.session,
    required this.repository,
    required this.appearance,
    super.key,
  });

  final SessionController session;
  final VitiRepository repository;
  final AppearanceController appearance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([session, appearance]),
      builder: (context, _) => MaterialApp(
        title: 'VITI · AGR Studio',
        debugShowCheckedModeBanner: false,
        theme: VitiTheme.light(),
        darkTheme: VitiTheme.dark(),
        themeMode: appearance.mode,
        home: session.authenticated
            ? HomeShell(
                session: session,
                repository: repository,
                appearance: appearance,
              )
            : LoginScreen(
                session: session,
                appearance: appearance,
              ),
      ),
    );
  }
}
