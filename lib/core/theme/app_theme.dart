import 'package:flutter/material.dart';

/// Tipografia y densidad alineadas a aplicaciones de escritorio Windows.
abstract final class AppTheme {
  static const _fontFamily = 'Segoe UI';
  static const List<String> _fontFamilyFallback = [
    'Segoe UI',
    'Tahoma',
    'Arial',
    'sans-serif',
  ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF90CAF9),
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

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
      displayLarge: base.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      displayMedium: base.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      displaySmall: base.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      headlineLarge: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      headlineMedium: base.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      headlineSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      titleLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      titleMedium: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      titleSmall: base.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      bodyLarge: base.copyWith(fontSize: 14, color: onSurface),
      bodyMedium: base.copyWith(fontSize: 13, color: onSurface),
      bodySmall: base.copyWith(fontSize: 12, color: muted),
      labelLarge: base.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: base.copyWith(fontSize: 11, color: muted),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = _textTheme(scheme);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      iconTheme: IconThemeData(size: 20, color: scheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: 40,
        titleTextStyle: textTheme.titleLarge,
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
        selectedIconTheme: IconThemeData(size: 22, color: scheme.primary),
        unselectedIconTheme: IconThemeData(
          size: 22,
          color: scheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        labelStyle: textTheme.bodySmall,
        hintStyle: textTheme.bodySmall,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        filled: true,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: textTheme.bodyMedium,
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }
}
