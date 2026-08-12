import 'package:flutter/material.dart';

class VitiTheme {
  const VitiTheme._();

  static const navy = Color(0xFF092B55);
  static const navyDeep = Color(0xFF06162B);
  static const blue = Color(0xFF1565C0);
  static const blueBright = Color(0xFF2D8CFF);
  static const cyan = Color(0xFF38BDF8);
  static const success = Color(0xFF2FA86F);
  static const warning = Color(0xFFE59A2F);

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scaffold: const Color(0xFF06162B),
        surface: const Color(0xFF0C294C),
        surfaceLow: const Color(0xFF0A223F),
        surfaceContainer: const Color(0xFF103255),
        surfaceContainerHigh: const Color(0xFF153A60),
        divider: const Color(0xFF244667),
        primary: const Color(0xFF75B8FF),
        secondary: cyan,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scaffold: const Color(0xFFF3F6FB),
        surface: const Color(0xFFFFFFFF),
        surfaceLow: const Color(0xFFF8FAFD),
        surfaceContainer: const Color(0xFFEEF3F9),
        surfaceContainerHigh: const Color(0xFFE6EDF6),
        divider: const Color(0xFFDFE7F1),
        primary: blue,
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
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: dark ? const Color(0xFF6EE7B7) : success,
      surface: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHigh,
      outline: dark ? const Color(0xFF557594) : const Color(0xFF9BAABD),
      outlineVariant: divider,
      error: dark ? const Color(0xFFFF8A95) : const Color(0xFFB42335),
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ).copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.9),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.7),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.45),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider.withValues(alpha: .92)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: navy,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navy,
        indicatorColor: Colors.white.withValues(alpha: .12),
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: Color(0xFFBCD0E5)),
      ),
      dividerTheme: DividerThemeData(color: divider.withValues(alpha: .9), thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: dark ? const Color(0xFF0B2545) : surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: .78)),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: inputBorder(divider),
        enabledBorder: inputBorder(divider),
        focusedBorder: inputBorder(primary, 1.6),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: divider.withValues(alpha: .9)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary, linearTrackColor: surfaceContainerHigh),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(999),
        thickness: WidgetStateProperty.all(7),
        thumbVisibility: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered)),
      ),
    );
  }
}
