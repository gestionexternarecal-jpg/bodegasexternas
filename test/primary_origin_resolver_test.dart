import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_externa/features/transfers/domain/entities/transfer_catalog.dart';
import 'package:gestion_externa/features/transfers/domain/primary_origin_resolver.dart';

void main() {
  group('PrimaryOriginResolver', () {
    test('resolve matches by name and complete path per company', () {
      const phsa = StockLocation(
        id: 1,
        name: 'Casa de la moneda',
        completeName: 'PHSA/Casa de la moneda',
      );
      const pv = StockLocation(
        id: 2,
        name: 'Casa de la moneda',
        completeName: 'PV/Casa de la moneda',
      );

      expect(
        PrimaryOriginResolver.resolve([phsa], 'Casa de la moneda')?.id,
        1,
      );
      expect(
        PrimaryOriginResolver.resolve([pv], 'Casa de la moneda')?.displayLabel,
        'PV/Casa de la moneda',
      );
    });

    test('uniqueOriginKeys returns sorted unique names', () {
      const a = StockLocation(id: 1, name: 'Bodega');
      const b = StockLocation(
        id: 2,
        name: 'Casa de la moneda',
        completeName: 'PHSA/Casa de la moneda',
      );
      const c = StockLocation(
        id: 3,
        name: 'Casa de la moneda',
        completeName: 'PV/Casa de la moneda',
      );

      expect(
        PrimaryOriginResolver.uniqueOriginKeys([a, b, c]),
        ['Bodega', 'Casa de la moneda'],
      );
    });
  });
}
