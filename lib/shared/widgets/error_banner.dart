import 'package:flutter/material.dart';

/// Banner de error con contraste legible en tema claro y oscuro.
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isDark ? const Color(0xFF4A1515) : const Color(0xFFFFEBEE);
    final border = isDark ? Colors.red.shade400 : Colors.red.shade300;
    final textColor = isDark ? const Color(0xFFFFCDD2) : const Color(0xFFB71C1C);
    final iconColor = isDark ? Colors.red.shade200 : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
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
