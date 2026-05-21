import 'bin_stock_allocation.dart';

/// Vista combinada: stock Odoo + reparto Firebase.
class ProductStockSummary {
  const ProductStockSummary({
    required this.odooProductId,
    required this.productName,
    required this.warehouseKey,
    required this.odooAvailableQty,
    required this.allocations,
    this.uomName,
    this.odooLocationLabel,
  });

  final int odooProductId;
  final String productName;
  final String warehouseKey;
  final double odooAvailableQty;
  final String? uomName;
  final String? odooLocationLabel;
  final List<BinStockAllocation> allocations;

  double get allocatedTotal =>
      allocations.fold(0.0, (sum, a) => sum + a.quantity);

  double get unallocatedQty => odooAvailableQty - allocatedTotal;

  bool get isFullyAllocated => unallocatedQty <= 0;

  bool get isOverAllocated => allocatedTotal > odooAvailableQty;
}
