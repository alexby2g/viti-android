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
        builder: (context, child) => Stack(
          children: [
            Positioned.fill(child: child ?? const SizedBox.shrink()),
            Positioned(
              right: 14,
              bottom: 14,
              child: SafeArea(
                child: _AppearanceControl(controller: appearance),
              ),
            ),
          ],
        ),
        home: session.authenticated
            ? HomeShell(session: session, repository: repository)
            : LoginScreen(session: session),
      ),
    );
  }
}

class _AppearanceControl extends StatelessWidget {
  const _AppearanceControl({required this.controller});

  final AppearanceController controller;

  IconData get _icon => switch (controller.mode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      child: PopupMenuButton<ThemeMode>(
        tooltip: 'Apariencia',
        initialValue: controller.mode,
        onSelected: controller.setMode,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: ThemeMode.system,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.brightness_auto_outlined),
              title: Text('Sistema'),
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.light,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.light_mode_outlined),
              title: Text('Claro'),
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.dark,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.dark_mode_outlined),
              title: Text('Oscuro'),
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(_icon, size: 21),
        ),
      ),
    );
  }
}
