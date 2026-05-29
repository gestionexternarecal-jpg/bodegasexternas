import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_externa/features/transfers/domain/entities/transfer_catalog.dart';
import 'package:gestion_externa/features/transfers/domain/transfer_company_validator.dart';

void main() {
  group('TransferCompanyValidator', () {
    const phsaId = 1;
    const pvId = 2;

    test('detecta producto de otra empresa', () {
      const line = TransferLineDraft(
        productId: 10,
        productName: 'Tambor de freno',
        quantity: 1,
        defaultCode: 'PV3434',
        companyId: phsaId,
        companyName: 'PHSA',
      );

      final issues = TransferCompanyValidator.collectIssues(
        expectedCompanyId: phsaId,
        lines: [line],
        productsById: {
          10: const OdooCompanyRecord(
            id: 10,
            label: 'PV3434',
            companyId: pvId,
            companyName: 'PROVEREPUESTOS CIA. LTDA.',
          ),
        },
        locationsById: {
          100: const OdooCompanyRecord(
            id: 100,
            label: 'PHSA/Bodega',
            companyId: phsaId,
            companyName: 'PHSA',
          ),
        },
        sourceLocationId: 100,
        destLocationId: 100,
        pickingTypeCompanyId: phsaId,
        pickingTypeLabel: 'PHSA: Transferencia interna',
      );

      expect(issues, isNotEmpty);
      expect(issues.first, contains('PV3434'));
      expect(issues.first, contains('PROVEREPUESTOS'));
    });

    test('acepta producto compartido sin empresa', () {
      const line = TransferLineDraft(
        productId: 11,
        productName: 'Producto generico',
        quantity: 2,
        companyId: phsaId,
      );

      final issues = TransferCompanyValidator.collectIssues(
        expectedCompanyId: phsaId,
        lines: [line],
        productsById: {
          11: const OdooCompanyRecord(
            id: 11,
            label: 'GEN-01',
            companyId: null,
          ),
        },
        locationsById: {
          101: const OdooCompanyRecord(id: 101, label: 'PHSA/Stock'),
          102: const OdooCompanyRecord(id: 102, label: 'PHSA/Destino'),
        },
        sourceLocationId: 101,
        destLocationId: 102,
        pickingTypeCompanyId: phsaId,
      );

      expect(issues, isEmpty);
    });
  });
}
