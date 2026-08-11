import 'package:flutter/material.dart';

import 'core/theme/viti_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/session_controller.dart';
import 'features/home/home_shell.dart';

class VitiApp extends StatelessWidget {
  const VitiApp({required this.session, super.key});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => MaterialApp(
        title: 'VITI · AGR Studio',
        debugShowCheckedModeBanner: false,
        theme: VitiTheme.dark(),
        home: session.authenticated
            ? HomeShell(session: session)
            : LoginScreen(session: session),
      ),
    );
  }
}
