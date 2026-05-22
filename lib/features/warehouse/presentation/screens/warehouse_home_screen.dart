import 'package:flutter/material.dart';

import '../../../../core/constants/app_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../domain/entities/warehouse_workspace.dart';
import '../providers/warehouse_providers.dart';

/// Inicio del modulo Gestion Almacen.
class WarehouseHomeScreen extends ConsumerWidget {
  const WarehouseHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(warehouseOriginKeysProvider);
    final workspace = ref.watch(warehouseWorkspaceProvider);

    return Padding(
      padding: AppLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gestion Almacen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Stock real desde Odoo. Ubicaciones internas en Firebase. '
            'La suma por ubicacion no puede superar el disponible en Odoo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bodega de trabajo',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  keysAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => AppErrorBanner(message: e.toString()),
                    data: (keys) => Autocomplete<String>(
                      initialValue: workspace == null
                          ? null
                          : TextEditingValue(text: workspace.warehouseKey),
                      optionsBuilder: (text) {
                        final q = text.text.trim().toLowerCase();
                        if (q.isEmpty) return keys;
                        return keys.where((k) => k.toLowerCase().contains(q));
                      },
                      onSelected: (v) {
                        ref.read(warehouseWorkspaceProvider.notifier).state =
                            WarehouseWorkspace(warehouseKey: v);
                      },
                      fieldViewBuilder: (
                        context,
                        controller,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        if (workspace != null && controller.text.isEmpty) {
                          controller.text = workspace.warehouseKey;
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Ej. Casa de la moneda',
                            prefixIcon: Icon(Icons.warehouse_outlined),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final t = v.trim();
                            ref.read(warehouseWorkspaceProvider.notifier).state =
                                t.isEmpty
                                    ? null
                                    : WarehouseWorkspace(warehouseKey: t);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StockRuleCard(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: workspace?.isValid != true
                    ? null
                    : () => context.go(routeWarehouseStock),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Consultar stock'),
              ),
              OutlinedButton.icon(
                onPressed: workspace?.isValid != true
                    ? null
                    : () => context.go(routeWarehouseBins),
                icon: const Icon(Icons.grid_view_outlined),
                label: const Text('Ubicaciones Firebase'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(routeCreateTransfer),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Movimiento interno'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!AppConstants.useFirebase)
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Firebase: modo memoria (desarrollo). '
                        'Ver docs/gestion_almacen/FIREBASE_SETUP.md',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StockRuleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ejemplo de reparto',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text('Odoo (bodega): 150 Unidades'),
            const Text('Firebase 101-A12: 100 Unidades'),
            const Text('Firebase 102-A14: 50 Unidades'),
            const SizedBox(height: 8),
            Text(
              'No permitido: 100 + 100 = 200 si Odoo solo tiene 150.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
