import 'package:flutter/material.dart';

abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isError
        ? (isDark ? const Color(0xFF8B1A1A) : const Color(0xFFC62828))
        : (isDark ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
