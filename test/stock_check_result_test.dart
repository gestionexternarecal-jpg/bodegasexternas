import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_externa/features/transfers/domain/entities/transfer_catalog.dart';

void main() {
  group('StockCheckResult', () {
    test('userMessage when no stock', () {
      const r = StockCheckResult(
        locationId: 1,
        locationLabel: 'PHSA/Casa de la moneda',
        availableQty: 0,
        requestedQty: 5,
      );
      expect(r.userMessage, 'Sin stock en PHSA/Casa de la moneda');
    });

    test('userMessage when insufficient', () {
      const r = StockCheckResult(
        locationId: 1,
        locationLabel: 'PV/Casa de la moneda',
        availableQty: 3,
        requestedQty: 10,
      );
      expect(
        r.userMessage,
        'Stock insuficiente en PV/Casa de la moneda: disponible 3, solicitado 10',
      );
    });

    test('userMessage null when sufficient', () {
      const r = StockCheckResult(
        locationId: 1,
        locationLabel: 'PV/Casa de la moneda',
        availableQty: 15,
        requestedQty: 10,
      );
      expect(r.userMessage, isNull);
    });
  });
}
