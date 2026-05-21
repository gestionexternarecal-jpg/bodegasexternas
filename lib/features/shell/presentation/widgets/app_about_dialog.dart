import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/update_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/update_providers.dart';

Future<void> showAppAboutDialog(BuildContext context, WidgetRef ref) async {
  final versionLabel = await ref.read(appVersionLabelProvider.future);

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppConstants.appName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version instalada: $versionLabel'),
          const SizedBox(height: 8),
          Text(
            UpdateConfig.isEnabled
                ? 'Las actualizaciones se notifican al iniciar la aplicacion.'
                : 'Comprobacion de actualizaciones no configurada en este build.',
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
