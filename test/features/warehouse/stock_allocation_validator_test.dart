import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_externa/features/warehouse/domain/entities/bin_stock_allocation.dart';
import 'package:gestion_externa/features/warehouse/domain/services/stock_allocation_validator.dart';

void main() {
  group('StockAllocationValidator', () {
    test('permite reparto que suma exactamente el stock Odoo', () {
      final allocations = [
        _alloc('a', 100),
        _alloc('b', 50),
      ];
      final r = StockAllocationValidator.validate(
        odooAvailableQty: 150,
        allocations: allocations,
      );
      expect(r.isValid, isTrue);
      expect(r.allocatedTotal, 150);
    });

    test('rechaza cuando la suma supera Odoo', () {
      final allocations = [
        _alloc('a', 100),
        _alloc('b', 100),
      ];
      final r = StockAllocationValidator.validate(
        odooAvailableQty: 150,
        allocations: allocations,
      );
      expect(r.isValid, isFalse);
      expect(r.excess, 50);
    });

    test('validateNewBinQty respeta cantidad sin ubicar', () {
      final existing = [_alloc('a', 100)];
      final r = StockAllocationValidator.validateNewBinQty(
        odooAvailableQty: 150,
        existing: existing,
        newBinQty: 60,
      );
      expect(r.isValid, isFalse);
    });
  });
}

BinStockAllocation _alloc(String id, double qty) {
  return BinStockAllocation(
    id: id,
    warehouseKey: 'test',
    binLocationId: 'bin_$id',
    binCode: id,
    odooProductId: 1,
    quantity: qty,
  );
}
