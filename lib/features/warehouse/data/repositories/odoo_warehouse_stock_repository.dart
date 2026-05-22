import '../../../../core/utils/result.dart';
import '../../../transfers/data/repositories/transfers_repository.dart';
import '../../../transfers/domain/primary_origin_resolver.dart';

/// Lectura de stock disponible en bodega desde Odoo.
class OdooWarehouseStockRepository {
  OdooWarehouseStockRepository(this._transfers);

  final TransfersRepository _transfers;

  Future<Result<OdooWarehouseStockSnapshot>> fetchAvailableInWarehouse({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String warehouseKey,
    required int productId,
    required int companyId,
  }) async {
    final result = await _transfers.checkStockAtPrimaryOrigin(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      productId: productId,
      companyId: companyId,
      primaryOriginKey: warehouseKey,
      requestedQty: 0,
    );

    return switch (result) {
      Success(:final value) => Success(
          OdooWarehouseStockSnapshot(
            quantity: value.availableQty,
            locationLabel: value.locationLabel,
            locationId: value.locationId,
          ),
        ),
      Failure(:final error) => Failure(error),
    };
  }

  Future<Result<List<String>>> listPrimaryOriginKeys({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
  }) async {
    final locationsResult = await _transfers.fetchInternalLocations(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
    );
    return switch (locationsResult) {
      Success(:final value) => Success(
          PrimaryOriginResolver.uniqueOriginKeys(value),
        ),
      Failure(:final error) => Failure(error),
    };
  }
}

class OdooWarehouseStockSnapshot {
  const OdooWarehouseStockSnapshot({
    required this.quantity,
    required this.locationLabel,
    required this.locationId,
  });

  final double quantity;
  final String locationLabel;
  final int locationId;
}
