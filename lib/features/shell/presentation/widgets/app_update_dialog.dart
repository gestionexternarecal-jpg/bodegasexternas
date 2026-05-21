import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/app_update_manifest.dart';

Future<void> showAppUpdateDialog(
  BuildContext context,
  AppUpdateManifest manifest,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: const Text('Actualizacion disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hay una nueva version: ${manifest.version} (build ${manifest.build}).',
          ),
          if (manifest.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              manifest.releaseNotes,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Descargue el instalador y ejecutelo. No es necesario desinstalar la version anterior.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Mas tarde'),
        ),
        FilledButton(
          onPressed: () async {
            final uri = Uri.tryParse(manifest.downloadUrl);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          child: const Text('Descargar'),
        ),
      ],
    ),
  );
}
