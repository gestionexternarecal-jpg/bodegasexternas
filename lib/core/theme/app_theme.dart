import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// Tipografia y paleta alineadas a escritorio Windows (aspecto corporativo).
abstract final class AppTheme {
  static const _fontFamily = 'Segoe UI';
  static const List<String> _fontFamilyFallback = [
    'Segoe UI',
    'Tahoma',
    'Arial',
    'sans-serif',
  ];

  static ThemeData light() => _base(_lightScheme, AppSemanticColors.light);

  static ThemeData dark() => _base(_darkScheme, AppSemanticColors.dark);

  /// Azul acero / pizarra — serio, legible en oficina.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1E3A5F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD4E2F0),
    onPrimaryContainer: Color(0xFF0F2438),
    secondary: Color(0xFF4A6578),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2E8F0),
    onSecondaryContainer: Color(0xFF1E293B),
    tertiary: Color(0xFF5C6B7A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE8EDF2),
    onTertiaryContainer: Color(0xFF334155),
    error: Color(0xFFB42318),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE4E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFF0F3F7),
    onSurface: Color(0xFF1E293B),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFFCBD5E1),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF1F5F9),
    inversePrimary: Color(0xFF93B4D4),
    surfaceTint: Color(0xFF1E3A5F),
    surfaceContainerHighest: Color(0xFFE2E8F0),
    surfaceContainerHigh: Color(0xFFE8EDF2),
    surfaceContainer: Color(0xFFEDF1F5),
    surfaceContainerLow: Color(0xFFF5F7FA),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceBright: Color(0xFFF8FAFC),
    surfaceDim: Color(0xFFDCE3EB),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7BA3D4),
    onPrimary: Color(0xFF0D1926),
    primaryContainer: Color(0xFF1E3A5F),
    onPrimaryContainer: Color(0xFFD4E6F5),
    secondary: Color(0xFF8BA4B8),
    onSecondary: Color(0xFF0F1419),
    secondaryContainer: Color(0xFF2A3A4A),
    onSecondaryContainer: Color(0xFFE2E8F0),
    tertiary: Color(0xFF94A3B8),
    onTertiary: Color(0xFF0F1419),
    tertiaryContainer: Color(0xFF243044),
    onTertiaryContainer: Color(0xFFCBD5E1),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFECACA),
    surface: Color(0xFF0F1419),
    onSurface: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF475569),
    outlineVariant: Color(0xFF334155),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE2E8F0),
    onInverseSurface: Color(0xFF1E293B),
    inversePrimary: Color(0xFF1E3A5F),
    surfaceTint: Color(0xFF7BA3D4),
    surfaceContainerHighest: Color(0xFF243044),
    surfaceContainerHigh: Color(0xFF1E2836),
    surfaceContainer: Color(0xFF1A2332),
    surfaceContainerLow: Color(0xFF151C24),
    surfaceContainerLowest: Color(0xFF0A0E12),
    surfaceBright: Color(0xFF2A3544),
    surfaceDim: Color(0xFF0F1419),
  );

  static TextTheme _textTheme(ColorScheme scheme) {
    const base = TextStyle(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      letterSpacing: 0,
      height: 1.35,
    );
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return TextTheme(
      displayLarge: base.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      displayMedium: base.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      displaySmall: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      headlineLarge: base.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      headlineMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      headlineSmall: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      titleLarge: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      titleMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      titleSmall: base.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
      bodyLarge: base.copyWith(fontSize: 13, color: onSurface),
      bodyMedium: base.copyWith(fontSize: 12, color: onSurface),
      bodySmall: base.copyWith(fontSize: 11, color: muted),
      labelLarge: base.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelMedium: base.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
      labelSmall: base.copyWith(fontSize: 10, color: muted),
    );
  }

  static ThemeData _base(ColorScheme scheme, AppSemanticColors semantic) {
    final textTheme = _textTheme(scheme);
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [semantic],
      visualDensity: VisualDensity.compact,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
      iconTheme: IconThemeData(size: 20, color: scheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: 36,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onPrimary, size: 20),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(size: 22, color: scheme.primary),
        unselectedIconTheme: IconThemeData(
          size: 22,
          color: scheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        shape: cardShape,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        labelStyle: textTheme.bodySmall,
        hintStyle: textTheme.bodySmall,
        fillColor: scheme.surfaceContainerLowest,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        dataTextStyle: textTheme.bodyMedium,
        headingRowColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 36,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyMedium,
        subtitleTextStyle: textTheme.bodySmall,
        dense: true,
        minVerticalPadding: 4,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
    );
  }
}
