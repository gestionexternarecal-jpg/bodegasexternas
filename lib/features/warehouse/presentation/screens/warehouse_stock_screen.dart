import 'package:flutter/material.dart';

import '../../../../core/constants/app_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../providers/warehouse_providers.dart';

/// Consulta stock Odoo + asignaciones Firebase (fase 1).
class WarehouseStockScreen extends ConsumerWidget {
  const WarehouseStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(warehouseWorkspaceProvider);

    return Padding(
      padding: AppLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(routeWarehouse),
              ),
              Expanded(
                child: Text(
                  'Consulta de stock',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (workspace != null)
            Text(
              'Bodega: ${workspace.warehouseKey}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proxima fase',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aqui se buscara el producto, se mostrara el stock Odoo '
                    'y las cantidades por ubicacion Firebase con validacion '
                    'en tiempo real (suma <= Odoo).',
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
