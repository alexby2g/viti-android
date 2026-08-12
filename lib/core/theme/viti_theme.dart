import 'package:flutter/material.dart';

class VitiTheme {
  const VitiTheme._();

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scaffold: const Color(0xFF07080D),
        surface: const Color(0xFF0D0F16),
        surfaceLow: const Color(0xFF11141D),
        surfaceContainer: const Color(0xFF171A25),
        surfaceContainerHigh: const Color(0xFF202432),
        divider: const Color(0xFF34394B),
        primary: const Color(0xFFA78BFA),
        secondary: const Color(0xFF38BDF8),
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scaffold: const Color(0xFFF4F5F8),
        surface: const Color(0xFFFFFFFF),
        surfaceLow: const Color(0xFFF8F9FC),
        surfaceContainer: const Color(0xFFEEF0F5),
        surfaceContainerHigh: const Color(0xFFE5E8EF),
        divider: const Color(0xFFD3D8E3),
        primary: const Color(0xFF6D43D9),
        secondary: const Color(0xFF087EA4),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color surfaceLow,
    required Color surfaceContainer,
    required Color surfaceContainerHigh,
    required Color divider,
    required Color primary,
    required Color secondary,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHigh,
      outline: brightness == Brightness.dark ? const Color(0xFF586075) : const Color(0xFF7A8291),
      outlineVariant: divider,
      error: brightness == Brightness.dark ? const Color(0xFFFF7B86) : const Color(0xFFB42335),
    );

    final textTheme = ThemeData(brightness: brightness, useMaterial3: true).textTheme.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: divider.withValues(alpha: .78)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.w850),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(color: divider.withValues(alpha: .8), thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: .8)),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: divider)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.error)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: const TextStyle(fontWeight: FontWeight.w750),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w750),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: divider.withValues(alpha: .8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w750),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: divider)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 11),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: surfaceContainerHigh),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
