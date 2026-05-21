import 'package:flutter/material.dart';

/// Referencia para pantallas de oficina comunes (19", 1366×768).
abstract final class AppLayout {
  static const Size referenceScreen = Size(1366, 768);

  /// Deja margen para barra de titulo (~32px) y barra de tareas (~40px).
  static const Size defaultWindowSize = Size(1200, 680);
  static const Size minimumWindowSize = Size(960, 580);

  static const double compactWidthBreakpoint = 1200;
  static const double compactHeightBreakpoint = 740;
  static const double wideRailBreakpoint = 1180;

  static bool isCompactHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height < compactHeightBreakpoint;

  static bool isCompactWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidthBreakpoint;

  static bool useExtendedRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideRailBreakpoint;

  static EdgeInsets pagePadding(BuildContext context) {
    final compact =
        isCompactWidth(context) || isCompactHeight(context);
    return EdgeInsets.all(compact ? 12 : 16);
  }

  static EdgeInsets headerPadding(BuildContext context) {
    final compact = isCompactHeight(context);
    return EdgeInsets.symmetric(
      horizontal: compact ? 12 : 16,
      vertical: compact ? 6 : 8,
    );
  }

  /// Altura maxima de la grilla de productos segun alto de ventana.
  static double productGridMaxHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    if (h < 640) return 180;
    if (h < 720) return 220;
    if (h < 800) return 280;
    return 340;
  }

  /// Ancho de tabla de captura; evita scroll horizontal innecesario en pantallas estrechas.
  static double productGridTableWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w - 140).clamp(560.0, 960.0);
  }
}
