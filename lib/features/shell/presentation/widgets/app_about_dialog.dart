import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/update_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/update_check_result.dart';
import '../../../../core/providers/update_providers.dart';
import 'app_update_dialog.dart';

Future<void> showAppAboutDialog(BuildContext context, WidgetRef ref) async {
  final versionLabel = await ref.read(appVersionLabelProvider.future);

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => _AboutDialogBody(
      versionLabel: versionLabel,
      ref: ref,
    ),
  );
}

class _AboutDialogBody extends StatefulWidget {
  const _AboutDialogBody({
    required this.versionLabel,
    required this.ref,
  });

  final String versionLabel;
  final WidgetRef ref;

  @override
  State<_AboutDialogBody> createState() => _AboutDialogBodyState();
}

class _AboutDialogBodyState extends State<_AboutDialogBody> {
  bool _checking = false;
  String? _checkMessage;

  Future<void> _checkUpdates() async {
    setState(() {
      _checking = true;
      _checkMessage = 'Comprobando...';
    });

    final result =
        await widget.ref.read(updateCheckServiceProvider).checkForUpdateDetailed();

    if (!mounted) return;

    setState(() {
      _checking = false;
      _checkMessage = result.message ??
          switch (result.status) {
            UpdateCheckStatus.upToDate => 'Ya tiene la ultima version.',
            UpdateCheckStatus.updateAvailable => 'Hay una actualizacion disponible.',
            UpdateCheckStatus.networkError =>
              'No se pudo conectar al servidor de actualizaciones.',
            UpdateCheckStatus.disabled => 'Actualizaciones no configuradas.',
          };
    });

    if (result.status == UpdateCheckStatus.updateAvailable &&
        result.manifest != null &&
        mounted) {
      await showAppUpdateDialog(context, result.manifest!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppConstants.appName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version instalada: ${widget.versionLabel}'),
          const SizedBox(height: 8),
          Text(
            UpdateConfig.isEnabled
                ? 'Las actualizaciones se comprueban al iniciar sesion.'
                : 'Comprobacion de actualizaciones no configurada en este build.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_checkMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _checkMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        if (UpdateConfig.isEnabled)
          TextButton(
            onPressed: _checking ? null : _checkUpdates,
            child: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Buscar actualizaciones'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
