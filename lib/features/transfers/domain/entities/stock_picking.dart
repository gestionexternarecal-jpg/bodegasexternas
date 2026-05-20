import '../../../../core/utils/ecuador_datetime.dart';
import '../../../../core/utils/odoo_value.dart';

class StockPicking {
  const StockPicking({
    required this.id,
    required this.name,
    required this.state,
    this.scheduledDate,
    this.dateDone,
    this.origin,
    this.locationId,
    this.locationDestId,
    this.locationName,
    this.locationDestName,
    this.userId,
    this.userName,
    this.pickingTypeId,
    this.companyId,
    this.companyName,
  });

  final int id;
  final String name;
  final String state;
  final DateTime? scheduledDate;
  final DateTime? dateDone;
  final String? origin;
  final int? locationId;
  final int? locationDestId;
  final String? locationName;
  final String? locationDestName;
  final int? userId;
  final String? userName;
  final int? pickingTypeId;
  final int? companyId;
  final String? companyName;

  bool get isDone => state == 'done';
  bool get isDraft => state == 'draft';
  bool get isCancelled => state == 'cancel';

  /// Estados en los que Odoo permite `action_cancel` en transferencias.
  static const cancelableStates = {
    'draft',
    'waiting',
    'confirmed',
    'assigned',
  };

  bool get canCancel => cancelableStates.contains(state);
  bool get isInProgress =>
      !isDone && !isCancelled && state != 'draft';

  /// Etiqueta en espanol del estado Odoo (`stock.picking.state`).
  String get stateLabelSpanish {
    switch (state) {
      case 'draft':
        return 'Borrador';
      case 'waiting':
        return 'En espera';
      case 'confirmed':
        return 'Confirmado';
      case 'assigned':
        return 'Preparacion';
      case 'done':
        return 'Hecho';
      case 'cancel':
        return 'Cancelado';
      default:
        return state;
    }
  }

  static StockPicking fromOdoo(Map<String, dynamic> json) {
    return StockPicking(
      id: json['id'] as int,
      name: OdooValue.stringOrEmpty(json['name']),
      state: OdooValue.stringOrEmpty(json['state']).isEmpty
          ? 'draft'
          : OdooValue.stringOrEmpty(json['state']),
      scheduledDate: _parseDate(json['scheduled_date']),
      dateDone: _parseDate(json['date_done']),
      origin: OdooValue.string(json['origin']),
      locationId: OdooValue.many2oneId(json['location_id']),
      locationDestId: OdooValue.many2oneId(json['location_dest_id']),
      locationName: OdooValue.many2oneName(json['location_id']),
      locationDestName: OdooValue.many2oneName(json['location_dest_id']),
      userId: OdooValue.many2oneId(json['user_id']),
      userName: OdooValue.many2oneName(json['user_id']),
      pickingTypeId: OdooValue.many2oneId(json['picking_type_id']),
      companyId: OdooValue.many2oneId(json['company_id']),
      companyName: OdooValue.many2oneName(json['company_id']),
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      EcuadorDateTime.parseOdooUtc(value);
}

class StockMoveLine {
  const StockMoveLine({
    required this.id,
    required this.productId,
    required this.productName,
    this.productUomQty = 0,
    this.qtyDone = 0,
    this.barcode,
    this.defaultCode,
    this.locationId,
    this.locationDestId,
    this.isStockMove = false,
  });

  final int id;
  final int productId;
  final String productName;
  final double productUomQty;
  final double qtyDone;
  final String? barcode;
  final String? defaultCode;
  final int? locationId;
  final int? locationDestId;

  /// `true` si la linea proviene de `stock.move` (borrador sin move.line).
  final bool isStockMove;

  static StockMoveLine fromOdoo(Map<String, dynamic> json) {
    return StockMoveLine(
      id: json['id'] as int,
      productId: OdooValue.many2oneId(json['product_id']) ?? 0,
      productName: OdooValue.many2oneName(json['product_id']) ?? 'Producto',
      productUomQty: _toDouble(
        json['quantity'] ?? json['product_uom_qty'] ?? json['reserved_uom_qty'],
      ),
      qtyDone: _toDouble(json['qty_done']),
      barcode: OdooValue.string(json['product_barcode']),
      defaultCode: OdooValue.string(json['product_default_code']),
      locationId: OdooValue.many2oneId(json['location_id']),
      locationDestId: OdooValue.many2oneId(json['location_dest_id']),
    );
  }

  static StockMoveLine fromStockMove(Map<String, dynamic> json) {
    return StockMoveLine(
      id: json['id'] as int,
      productId: OdooValue.many2oneId(json['product_id']) ?? 0,
      productName: OdooValue.many2oneName(json['product_id']) ?? 'Producto',
      productUomQty: _toDouble(json['product_uom_qty'] ?? json['quantity']),
      qtyDone: _toDouble(json['quantity_done']),
      locationId: OdooValue.many2oneId(json['location_id']),
      locationDestId: OdooValue.many2oneId(json['location_dest_id']),
      isStockMove: true,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null || v == false) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class TransferStats {
  const TransferStats({
    this.pending = 0,
    this.inProgress = 0,
    this.done = 0,
    this.cancelled = 0,
  });

  final int pending;
  final int inProgress;
  final int done;
  final int cancelled;

  int get total => pending + inProgress + done + cancelled;
}
