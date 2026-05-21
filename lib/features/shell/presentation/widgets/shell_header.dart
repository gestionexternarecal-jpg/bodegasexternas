import 'package:flutter/material.dart';

import '../../../../core/constants/app_layout.dart';

/// Titulo superior del shell segun modulo activo.
class ShellHeader extends StatelessWidget {
  const ShellHeader({
    super.key,
    required this.title,
    this.sessionLine,
  });

  final String title;
  final String? sessionLine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 0,
      color: scheme.primary,
      child: Padding(
        padding: AppLayout.headerPadding(context),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimary,
                  ),
            ),
            const Spacer(),
            if (sessionLine != null)
              Text(
                sessionLine!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.85),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

String shellTitleForPath(String path) {
  if (path.startsWith('/warehouse')) return 'Gestion Almacen';
  if (path == '/create-transfer' ||
      path == '/transfer/new' ||
      path == '/transfers/create') {
    return 'Nueva transferencia';
  }
  return 'Transferencias internas';
}
