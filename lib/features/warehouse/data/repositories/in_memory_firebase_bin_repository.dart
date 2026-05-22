import '../../../../core/utils/result.dart';
import '../../domain/entities/bin_location.dart';
import '../../domain/entities/bin_stock_allocation.dart';
import 'firebase_bin_repository.dart';

/// Implementacion local hasta configurar Firestore.
class InMemoryFirebaseBinRepository implements FirebaseBinRepository {
  final List<BinLocation> _locations = [];
  final List<BinStockAllocation> _allocations = [];

  @override
  Future<List<BinLocation>> listBinLocations({required String warehouseKey}) async {
    return _locations
        .where((l) => l.warehouseKey == warehouseKey && l.active)
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  @override
  Future<List<BinStockAllocation>> listAllocations({
    required String warehouseKey,
    int? odooProductId,
  }) async {
    return _allocations.where((a) {
      if (a.warehouseKey != warehouseKey) return false;
      if (odooProductId != null && a.odooProductId != odooProductId) return false;
      return true;
    }).toList();
  }

  @override
  Future<Result<void>> saveBinLocation(BinLocation location) async {
    _locations.removeWhere((l) => l.id == location.id);
    _locations.add(location);
    return const Success(null);
  }

  @override
  Future<Result<void>> saveAllocation(BinStockAllocation allocation) async {
    _allocations.removeWhere((a) => a.id == allocation.id);
    _allocations.add(allocation);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAllocation(String allocationId) async {
    _allocations.removeWhere((a) => a.id == allocationId);
    return const Success(null);
  }

}
