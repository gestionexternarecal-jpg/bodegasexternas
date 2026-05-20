import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_externa/features/transfers/data/bulk_excel_service.dart';

void main() {
  group('BulkExcelService', () {
    test('buildTemplateBytes and parse roundtrip', () {
      final bytes = BulkExcelService.buildTemplateBytes();
      final rows = BulkExcelService.parseBytes(bytes);

      expect(rows, isNotEmpty);
      expect(rows.first.codigo, 'EJEMPLO01');
      expect(rows.first.detalle, 'Descripcion del producto');
      expect(rows.first.cantidad, 1);
    });
  });
}
