import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_externa/core/utils/odoo_value.dart';
import 'package:gestion_externa/features/transfers/domain/entities/stock_picking.dart';

void main() {
  group('OdooValue', () {
    test('string convierte false de Odoo en null', () {
      expect(OdooValue.string(false), isNull);
      expect(OdooValue.string('REF-001'), 'REF-001');
    });

    test('many2oneName tolera nombre false', () {
      expect(OdooValue.many2oneName([1, false]), isNull);
      expect(OdooValue.many2oneName([2, 'Almacen']), 'Almacen');
    });
  });

  group('StockPicking.fromOdoo', () {
    test('parsea origin false sin error', () {
      final picking = StockPicking.fromOdoo({
        'id': 10,
        'name': 'INT/00010',
        'state': 'assigned',
        'origin': false,
        'location_id': [1, 'Stock'],
        'location_dest_id': [2, 'Salida'],
        'user_id': false,
        'picking_type_id': [5, 'Internal'],
        'company_id': [2, 'Mi Empresa SA'],
        'scheduled_date': false,
        'date_done': false,
      });

      expect(picking.companyId, 2);
      expect(picking.companyName, 'Mi Empresa SA');
      expect(picking.origin, isNull);
      expect(picking.userName, isNull);
      expect(picking.name, 'INT/00010');
    });
  });
}
