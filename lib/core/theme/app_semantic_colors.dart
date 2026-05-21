import 'package:flutter/material.dart';

/// Colores de estado y métricas (formales, no saturados).
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.pending,
    required this.active,
    required this.success,
    required this.danger,
    required this.neutral,
    required this.info,
    required this.errorSurface,
    required this.onErrorSurface,
    required this.errorBorder,
  });

  final Color pending;
  final Color active;
  final Color success;
  final Color danger;
  final Color neutral;
  final Color info;
  final Color errorSurface;
  final Color onErrorSurface;
  final Color errorBorder;

  static const light = AppSemanticColors(
    pending: Color(0xFFB45309),
    active: Color(0xFF1D4ED8),
    success: Color(0xFF047857),
    danger: Color(0xFFB42318),
    neutral: Color(0xFF64748B),
    info: Color(0xFF2563EB),
    errorSurface: Color(0xFFFEF2F2),
    onErrorSurface: Color(0xFF991B1B),
    errorBorder: Color(0xFFFCA5A5),
  );

  static const dark = AppSemanticColors(
    pending: Color(0xFFD4A574),
    active: Color(0xFF7BA3D4),
    success: Color(0xFF4ADE80),
    danger: Color(0xFFF87171),
    neutral: Color(0xFF94A3B8),
    info: Color(0xFF60A5FA),
    errorSurface: Color(0xFF3D1F1F),
    onErrorSurface: Color(0xFFFECACA),
    errorBorder: Color(0xFF991B1B),
  );

  @override
  AppSemanticColors copyWith({
    Color? pending,
    Color? active,
    Color? success,
    Color? danger,
    Color? neutral,
    Color? info,
    Color? errorSurface,
    Color? onErrorSurface,
    Color? errorBorder,
  }) {
    return AppSemanticColors(
      pending: pending ?? this.pending,
      active: active ?? this.active,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      neutral: neutral ?? this.neutral,
      info: info ?? this.info,
      errorSurface: errorSurface ?? this.errorSurface,
      onErrorSurface: onErrorSurface ?? this.onErrorSurface,
      errorBorder: errorBorder ?? this.errorBorder,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      pending: l(pending, other.pending),
      active: l(active, other.active),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      neutral: l(neutral, other.neutral),
      info: l(info, other.info),
      errorSurface: l(errorSurface, other.errorSurface),
      onErrorSurface: l(onErrorSurface, other.onErrorSurface),
      errorBorder: l(errorBorder, other.errorBorder),
    );
  }
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
