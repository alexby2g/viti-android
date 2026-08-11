import 'package:flutter/material.dart';

import 'appearance_controller.dart';

class AppearanceMenuButton extends StatelessWidget {
  const AppearanceMenuButton({required this.controller, super.key});

  final AppearanceController controller;

  IconData get _icon => switch (controller.mode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Apariencia',
      initialValue: controller.mode,
      onSelected: controller.setMode,
      icon: Icon(_icon),
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
    );
  }
}
