import 'package:flutter/material.dart';

class VitiTheme {
  const VitiTheme._();

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6),
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFF0EA5E9),
      surface: const Color(0xFF12121A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF09090F),
    );
  }
}
