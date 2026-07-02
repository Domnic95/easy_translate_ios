import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandBlueDeep = Color(0xFF1E40AF);
  static const Color brandViolet = Color(0xFF8B5CF6);
  static const Color brandCyan = Color(0xFF22D3EE);
  static const Color darkBg = Color(0xFF0A1029);
  static const Color darkSurface = Color(0xFF111A33);
  static const Color darkSurfaceHigh = Color(0xFF1B2547);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurfaceHigh = Color(0xFFEEF2FF);
  static const Color slate900 = Color(0xFF0F172A);

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      primary: const Color(0xFF2563EB),
      onPrimary: Colors.white,
      secondary: brandViolet,
      onSecondary: Colors.white,
      tertiary: brandCyan,
      onTertiary: slate900,
      surface: lightBg,
      onSurface: slate900,
      surfaceContainerLowest: Colors.white,
      surfaceContainer: const Color(0xFFF1F5F9),
      surfaceContainerHigh: lightSurfaceHigh,
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      outline: const Color(0xFFCBD5E1),
      outlineVariant: const Color(0xFFE2E8F0),
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: const Color(0xFF60A5FA),
      onPrimary: const Color(0xFF071029),
      secondary: brandViolet,
      onSecondary: Colors.white,
      tertiary: brandCyan,
      onTertiary: slate900,
      surface: darkBg,
      onSurface: const Color(0xFFE2E8F0),
      surfaceContainerLowest: const Color(0xFF070C1F),
      surfaceContainer: darkSurface,
      surfaceContainerHigh: darkSurfaceHigh,
      surfaceContainerHighest: const Color(0xFF243056),
      outline: const Color(0xFF334155),
      outlineVariant: const Color(0xFF1E293B),
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final text = GoogleFonts.interTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.6,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.6 : 0.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: scheme.shadow.withValues(alpha: 0.4),
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.16),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
