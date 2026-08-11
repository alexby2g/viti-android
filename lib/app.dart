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
        builder: (context, child) {
          if (!session.authenticated) return child ?? const SizedBox.shrink();
          return Stack(
            children: [
              Positioned.fill(child: child ?? const SizedBox.shrink()),
              Positioned(
                right: 14,
                bottom: 14,
                child: SafeArea(child: _AppearanceCycleButton(controller: appearance)),
              ),
            ],
          );
        },
        home: session.authenticated
            ? HomeShell(session: session, repository: repository)
            : LoginScreen(session: session, appearance: appearance),
      ),
    );
  }
}

class _AppearanceCycleButton extends StatelessWidget {
  const _AppearanceCycleButton({required this.controller});

  final AppearanceController controller;

  IconData get _icon => switch (controller.mode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };

  ThemeMode get _next => switch (controller.mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.setMode(_next),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(_icon, size: 21),
        ),
      ),
    );
  }
}
