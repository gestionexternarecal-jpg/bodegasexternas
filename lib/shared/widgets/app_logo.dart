import 'package:flutter/material.dart';

/// Logo de la aplicacion (mismo asset que el icono del ejecutable).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 160,
    this.borderRadius = 12,
  });

  final double size;
  final double borderRadius;

  static const assetPath = 'assets/icons/app_icon.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
