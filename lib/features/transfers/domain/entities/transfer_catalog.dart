import '../../../../core/utils/odoo_value.dart';

/// Empresa Odoo (`res.company`) asociada a una transferencia.
class ResCompany {
  const ResCompany({required this.id, required this.name});

  final int id;
  final String name;

  static ResCompany fromOdoo(Map<String, dynamic> json) {
    return ResCompany(
      id: json['id'] as int,
      name: OdooValue.stringOrEmpty(json['name']),
    );
  }
}

class StockLocation {
  const StockLocation({required this.id, required this.name, this.completeName});

  final int id;
  final String name;
  final String? completeName;

  String get displayLabel => completeName ?? name;

  static StockLocation fromOdoo(Map<String, dynamic> json) {
    return StockLocation(
      id: json['id'] as int,
      name: OdooValue.stringOrEmpty(json['name']),
      completeName: OdooValue.string(json['complete_name']),
    );
  }
}

class InternalPickingType {
  const InternalPickingType({
    required this.id,
    required this.name,
    this.defaultSourceId,
    this.defaultDestId,
    this.defaultSourceName,
    this.defaultDestName,
    this.companyId,
    this.companyName,
  });

  final int id;
  final String name;
  final int? defaultSourceId;
  final int? defaultDestId;
  final String? defaultSourceName;
  final String? defaultDestName;
  final int? companyId;
  final String? companyName;

  static InternalPickingType fromOdoo(Map<String, dynamic> json) {
    return InternalPickingType(
      id: json['id'] as int,
      name: OdooValue.stringOrEmpty(json['name']),
      defaultSourceId: OdooValue.many2oneId(json['default_location_src_id']),
      defaultDestId: OdooValue.many2oneId(json['default_location_dest_id']),
      defaultSourceName: OdooValue.many2oneName(json['default_location_src_id']),
      defaultDestName: OdooValue.many2oneName(json['default_location_dest_id']),
      companyId: OdooValue.many2oneId(json['company_id']),
      companyName: OdooValue.many2oneName(json['company_id']),
    );
  }
}

class ProductOption {
  const ProductOption({
    required this.id,
    required this.name,
    this.barcode,
    this.defaultCode,
    this.uomId,
    this.uomName,
    this.companyId,
    this.companyName,
  });

  final int id;
  final String name;
  final String? barcode;
  final String? defaultCode;
  final int? uomId;
  final String? uomName;
  final int? companyId;
  final String? companyName;

  String get subtitle {
    final parts = <String>[];
    if (defaultCode != null && defaultCode!.isNotEmpty) {
      parts.add('Ref: $defaultCode');
    }
    if (barcode != null && barcode!.isNotEmpty) parts.add('CB: $barcode');
    return parts.join(' · ');
  }

  static ProductOption fromOdoo(Map<String, dynamic> json) {
    return ProductOption(
      id: json['id'] as int,
      name: OdooValue.stringOrEmpty(json['name']),
      barcode: OdooValue.string(json['barcode']),
      defaultCode: OdooValue.string(json['default_code']),
      uomId: OdooValue.many2oneId(json['uom_id']),
      uomName: OdooValue.many2oneName(json['uom_id']),
      companyId: OdooValue.many2oneId(json['company_id']),
      companyName: OdooValue.many2oneName(json['company_id']),
    );
  }
}

/// Resultado de comprobar stock en la ubicacion de origen primaria.
class StockCheckResult {
  const StockCheckResult({
    required this.locationId,
    required this.locationLabel,
    required this.availableQty,
    required this.requestedQty,
  });

  final int locationId;
  final String locationLabel;
  final double availableQty;
  final double requestedQty;

  bool get isSufficient => availableQty >= requestedQty;
  bool get hasStock => availableQty > 0;

  String? get userMessage {
    if (!hasStock) {
      return 'Sin stock en $locationLabel';
    }
    if (!isSufficient) {
      return 'Stock insuficiente en $locationLabel: '
          'disponible ${availableQty.toStringAsFixed(availableQty == availableQty.roundToDouble() ? 0 : 2)}, '
          'solicitado ${requestedQty.toStringAsFixed(requestedQty == requestedQty.roundToDouble() ? 0 : 2)}';
    }
    return null;
  }
}

/// Linea local antes de crear la transferencia en Odoo.
class TransferLineDraft {
  const TransferLineDraft({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.uomId,
    this.barcode,
    this.defaultCode,
    this.companyId,
    this.companyName,
  });

  final int productId;
  final String productName;
  final double quantity;
  final int? uomId;
  final String? barcode;
  final String? defaultCode;
  final int? companyId;
  final String? companyName;

  TransferLineDraft copyWith({
    double? quantity,
    int? companyId,
    String? companyName,
  }) {
    return TransferLineDraft(
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      uomId: uomId,
      barcode: barcode,
      defaultCode: defaultCode,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
    );
  }
}
