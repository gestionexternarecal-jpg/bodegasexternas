import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/bin_stock_allocation.dart';
import '../../domain/entities/product_stock_summary.dart';
import '../../domain/services/stock_allocation_validator.dart';
import '../repositories/firebase_bin_repository.dart';
import '../repositories/odoo_warehouse_stock_repository.dart';

/// Orquesta lectura Odoo + Firebase y arma el resumen por producto.
class WarehouseStockService {
  WarehouseStockService({
    required OdooWarehouseStockRepository odoo,
    required FirebaseBinRepository firebase,
  })  : _odoo = odoo,
        _firebase = firebase;

  final OdooWarehouseStockRepository _odoo;
  final FirebaseBinRepository _firebase;

  Future<Result<ProductStockSummary>> getProductSummary({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String warehouseKey,
    required int odooProductId,
    required String productName,
    required int companyId,
    String? uomName,
  }) async {
    final odooQty = await _odoo.fetchAvailableInWarehouse(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      warehouseKey: warehouseKey,
      productId: odooProductId,
      companyId: companyId,
    );

    switch (odooQty) {
      case Success(:final value):
        final allocations = await _firebase.listAllocations(
          warehouseKey: warehouseKey,
          odooProductId: odooProductId,
        );
        return Success(
          ProductStockSummary(
            odooProductId: odooProductId,
            productName: productName,
            warehouseKey: warehouseKey,
            odooAvailableQty: value.quantity,
            uomName: uomName,
            odooLocationLabel: value.locationLabel,
            allocations: allocations,
          ),
        );
      case Failure(:final error):
        return Failure(error);
    }
  }

  Future<Result<void>> upsertAllocation({
    required BinStockAllocation allocation,
    required double odooAvailableQty,
    required List<BinStockAllocation> currentAllocations,
  }) async {
    final validation = StockAllocationValidator.validate(
      odooAvailableQty: odooAvailableQty,
      allocations: currentAllocations,
      replacingAllocationId: allocation.id,
      newQuantityForReplacement: allocation.quantity,
    );
    if (!validation.isValid) {
      return Failure(
        OdooRpcException(validation.message ?? 'Asignacion invalida'),
      );
    }
    return _firebase.saveAllocation(allocation);
  }
}
