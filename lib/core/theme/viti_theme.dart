import 'package:flutter/material.dart';

class VitiTheme {
  const VitiTheme._();

  static ThemeData dark() => _build(
        scaffold: const Color(0xFF09090F),
        surface: const Color(0xFF12121A),
        surfaceContainer: const Color(0xFF1B1B25),
        surfaceContainerHigh: const Color(0xFF242432),
        divider: const Color(0xFF30303D),
      );

  /// Primer modo claro de VITI: aclara la interfaz sin sacrificar contraste.
  /// Más adelante podremos llevarlo a un claro casi blanco a medida que los
  /// módulos migren todos sus textos a colores semánticos del tema.
  static ThemeData light() => _build(
        scaffold: const Color(0xFF31394A),
        surface: const Color(0xFF3C465A),
        surfaceContainer: const Color(0xFF465166),
        surfaceContainerHigh: const Color(0xFF536077),
        divider: const Color(0xFF69758B),
      );

  static ThemeData _build({
    required Color scaffold,
    required Color surface,
    required Color surfaceContainer,
    required Color surfaceContainerHigh,
    required Color divider,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFA78BFA),
      secondary: const Color(0xFF38BDF8),
      surface: surface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHighest: surfaceContainerHigh,
      outlineVariant: divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: divider.withValues(alpha: .72)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: surface),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(color: surfaceContainerHigh),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
    );
  }
}
