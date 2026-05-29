import 'entities/transfer_catalog.dart';

/// Comprueba que productos, ubicaciones y tipo de operacion pertenezcan a la empresa del borrador.
abstract final class TransferCompanyValidator {
  TransferCompanyValidator._();

  static List<String> collectIssues({
    required int expectedCompanyId,
    required List<TransferLineDraft> lines,
    required Map<int, OdooCompanyRecord> productsById,
    required Map<int, OdooCompanyRecord> locationsById,
    required int sourceLocationId,
    required int destLocationId,
    int? pickingTypeCompanyId,
    String? pickingTypeCompanyName,
    String? pickingTypeLabel,
  }) {
    final issues = <String>[];

    for (final line in lines) {
      final product = productsById[line.productId];
      if (product == null) {
        issues.add(
          'Producto "${line.productName}" no encontrado en Odoo',
        );
        continue;
      }
      if (!_companyMatches(product.companyId, expectedCompanyId)) {
        issues.add(
          'Producto "${_productLabel(line, product)}" pertenece a '
          '${product.companyName ?? "otra empresa"}',
        );
      }
    }

    _checkLocation(
      issues,
      locationsById[sourceLocationId],
      expectedCompanyId,
      'Ubicacion de origen',
    );
    _checkLocation(
      issues,
      locationsById[destLocationId],
      expectedCompanyId,
      'Ubicacion de destino',
    );

    if (pickingTypeCompanyId != null &&
        !_companyMatches(pickingTypeCompanyId, expectedCompanyId)) {
      issues.add(
        'Tipo de operacion "${pickingTypeLabel ?? pickingTypeCompanyId}" '
        'pertenece a ${pickingTypeCompanyName ?? "otra empresa"}',
      );
    }

    return issues;
  }

  static String formatBlockingMessage({
    required String expectedCompanyName,
    required List<String> issues,
  }) {
    final buffer = StringBuffer()
      ..writeln('Empresas incompatibles para $expectedCompanyName.')
      ..writeln('Corrija en la grilla o en Odoo antes de crear el borrador:');
    for (final issue in issues) {
      buffer.writeln('• $issue');
    }
    return buffer.toString().trim();
  }

  static bool _companyMatches(int? recordCompanyId, int expectedCompanyId) {
    if (recordCompanyId == null) return true;
    return recordCompanyId == expectedCompanyId;
  }

  static void _checkLocation(
    List<String> issues,
    OdooCompanyRecord? location,
    int expectedCompanyId,
    String role,
  ) {
    if (location == null) {
      issues.add('$role no encontrada en Odoo');
      return;
    }
    if (!_companyMatches(location.companyId, expectedCompanyId)) {
      issues.add(
        '$role "${location.label}" pertenece a '
        '${location.companyName ?? "otra empresa"}',
      );
    }
  }

  static String _productLabel(
    TransferLineDraft line,
    OdooCompanyRecord product,
  ) {
    final code = line.defaultCode ?? product.label;
    return code.isNotEmpty ? code : line.productName;
  }
}

/// Registro Odoo con empresa opcional (producto, ubicacion, etc.).
class OdooCompanyRecord {
  const OdooCompanyRecord({
    required this.id,
    required this.label,
    this.companyId,
    this.companyName,
  });

  final int id;
  final String label;
  final int? companyId;
  final String? companyName;
}
