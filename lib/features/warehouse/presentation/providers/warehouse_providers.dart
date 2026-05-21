import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../transfers/presentation/providers/transfers_providers.dart';
import '../../data/repositories/firebase_bin_repository.dart';
import '../../data/repositories/firestore_firebase_bin_repository.dart';
import '../../data/repositories/in_memory_firebase_bin_repository.dart';
import '../../data/repositories/odoo_warehouse_stock_repository.dart';
import '../../data/services/warehouse_stock_service.dart';
import '../../domain/entities/warehouse_workspace.dart';

/// Cambiar a [FirestoreFirebaseBinRepository] cuando Firebase este listo.
final warehouseFirebaseRepositoryProvider = Provider<FirebaseBinRepository>((ref) {
  if (AppConstants.useFirebase) {
    return FirestoreFirebaseBinRepository();
  }
  return InMemoryFirebaseBinRepository();
});

final odooWarehouseStockRepositoryProvider =
    Provider<OdooWarehouseStockRepository>((ref) {
  return OdooWarehouseStockRepository(ref.watch(transfersRepositoryProvider));
});

final warehouseStockServiceProvider = Provider<WarehouseStockService>((ref) {
  return WarehouseStockService(
    odoo: ref.watch(odooWarehouseStockRepositoryProvider),
    firebase: ref.watch(warehouseFirebaseRepositoryProvider),
  );
});

/// Bodega de trabajo activa en el modulo almacen.
final warehouseWorkspaceProvider =
    StateProvider<WarehouseWorkspace?>((ref) => null);

/// Reutiliza claves de origen primario del modulo transferencias.
final warehouseOriginKeysProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(primaryOriginLocationKeysProvider.future);
});
