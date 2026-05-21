import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/bin_location.dart';
import '../../domain/entities/bin_stock_allocation.dart';
import 'firebase_bin_repository.dart';

/// Implementacion Firestore (activar tras `flutterfire configure`).
///
/// Sustituye [InMemoryFirebaseBinRepository] en [warehouseFirebaseRepositoryProvider]
/// cuando [AppConstants.useFirebase] sea true y exista `firebase_options.dart`.
class FirestoreFirebaseBinRepository implements FirebaseBinRepository {
  // ignore: unused_field
  FirestoreFirebaseBinRepository();

  static Never _notConfigured() {
    throw const OdooRpcException(
      'Firebase no configurado. Ejecute flutterfire configure y active '
      'AppConstants.useFirebase. Ver docs/gestion_almacen/FIREBASE_SETUP.md',
    );
  }

  @override
  Future<List<BinLocation>> listBinLocations({required String warehouseKey}) async {
    if (!AppConstants.useFirebase) _notConfigured();
    return [];
  }

  @override
  Future<List<BinStockAllocation>> listAllocations({
    required String warehouseKey,
    int? odooProductId,
  }) async {
    if (!AppConstants.useFirebase) _notConfigured();
    return [];
  }

  @override
  Future<Result<void>> saveBinLocation(BinLocation location) async {
    if (!AppConstants.useFirebase) _notConfigured();
    return const Success(null);
  }

  @override
  Future<Result<void>> saveAllocation(BinStockAllocation allocation) async {
    if (!AppConstants.useFirebase) _notConfigured();
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAllocation(String allocationId) async {
    if (!AppConstants.useFirebase) _notConfigured();
    return const Success(null);
  }
}
