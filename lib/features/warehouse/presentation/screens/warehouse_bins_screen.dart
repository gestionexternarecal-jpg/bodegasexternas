import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../providers/warehouse_providers.dart';

/// CRUD ubicaciones internas Firebase (fase 2).
class WarehouseBinsScreen extends ConsumerWidget {
  const WarehouseBinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(warehouseWorkspaceProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
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
                  'Ubicaciones internas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (workspace != null)
            Text(
              'Bodega: ${workspace.warehouseKey} · Solo Firebase',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Proxima fase: alta de ubicaciones (101-A12, 102-A14, etc.) '
                'en Firestore / memoria local.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
