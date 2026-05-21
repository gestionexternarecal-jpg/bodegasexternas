import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';

/// Banner de error con contraste legible en tema claro y oscuro.
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: semantic.errorSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: semantic.errorBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: semantic.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: semantic.onErrorSurface,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
