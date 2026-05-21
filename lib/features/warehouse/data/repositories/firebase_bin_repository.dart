import '../../../../core/utils/result.dart';
import '../../domain/entities/bin_location.dart';
import '../../domain/entities/bin_stock_allocation.dart';

/// Persistencia de ubicaciones y asignaciones (Firebase o memoria).
abstract class FirebaseBinRepository {
  Future<List<BinLocation>> listBinLocations({required String warehouseKey});

  Future<List<BinStockAllocation>> listAllocations({
    required String warehouseKey,
    int? odooProductId,
  });

  Future<Result<void>> saveBinLocation(BinLocation location);

  Future<Result<void>> saveAllocation(BinStockAllocation allocation);

  Future<Result<void>> deleteAllocation(String allocationId);
}
