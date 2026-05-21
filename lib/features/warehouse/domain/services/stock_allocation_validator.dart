import '../entities/bin_stock_allocation.dart';

/// Resultado de validar cantidades Firebase contra stock Odoo.
class AllocationValidation {
  const AllocationValidation({
    required this.isValid,
    required this.odooAvailable,
    required this.allocatedTotal,
    this.message,
  });

  final bool isValid;
  final double odooAvailable;
  final double allocatedTotal;
  final String? message;

  double get unallocated => odooAvailable - allocatedTotal;
  double get excess => allocatedTotal > odooAvailable ? allocatedTotal - odooAvailable : 0;
}

/// Garantiza: suma(Firebase) <= stock Odoo.
abstract final class StockAllocationValidator {
  static AllocationValidation validate({
    required double odooAvailableQty,
    required List<BinStockAllocation> allocations,
    String? replacingAllocationId,
    double? newQuantityForReplacement,
  }) {
    var total = 0.0;
    for (final a in allocations) {
      if (replacingAllocationId != null && a.id == replacingAllocationId) {
        total += newQuantityForReplacement ?? 0;
      } else {
        total += a.quantity;
      }
    }

    if (odooAvailableQty < 0) {
      return AllocationValidation(
        isValid: false,
        odooAvailable: odooAvailableQty,
        allocatedTotal: total,
        message: 'Stock Odoo invalido',
      );
    }

    if (total > odooAvailableQty) {
      return AllocationValidation(
        isValid: false,
        odooAvailable: odooAvailableQty,
        allocatedTotal: total,
        message:
            'La suma en ubicaciones (${_fmt(total)}) supera el stock Odoo '
            '(${_fmt(odooAvailableQty)}). Reduzca ${_fmt(total - odooAvailableQty)}.',
      );
    }

    return AllocationValidation(
      isValid: true,
      odooAvailable: odooAvailableQty,
      allocatedTotal: total,
    );
  }

  /// Valida una cantidad nueva en un bin (resto ya asignado en [existing]).
  static AllocationValidation validateNewBinQty({
    required double odooAvailableQty,
    required List<BinStockAllocation> existing,
    required double newBinQty,
    String? excludeAllocationId,
  }) {
    final others = excludeAllocationId == null
        ? existing
        : existing.where((a) => a.id != excludeAllocationId).toList();
    final othersTotal = others.fold(0.0, (s, a) => s + a.quantity);
    final total = othersTotal + newBinQty;
    if (total > odooAvailableQty) {
      return AllocationValidation(
        isValid: false,
        odooAvailable: odooAvailableQty,
        allocatedTotal: total,
        message:
            'No puede asignar ${_fmt(newBinQty)}: solo quedan '
            '${_fmt(odooAvailableQty - othersTotal)} sin ubicar en Odoo.',
      );
    }
    return AllocationValidation(
      isValid: true,
      odooAvailable: odooAvailableQty,
      allocatedTotal: total,
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
