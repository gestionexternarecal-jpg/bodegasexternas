/// Cantidad de un producto asignada a una ubicacion Firebase.
class BinStockAllocation {
  const BinStockAllocation({
    required this.id,
    required this.warehouseKey,
    required this.binLocationId,
    required this.binCode,
    required this.odooProductId,
    required this.quantity,
    this.productDefaultCode,
    this.productName,
    this.uomName,
  });

  final String id;
  final String warehouseKey;
  final String binLocationId;
  final String binCode;
  final int odooProductId;
  final double quantity;
  final String? productDefaultCode;
  final String? productName;
  final String? uomName;
}
