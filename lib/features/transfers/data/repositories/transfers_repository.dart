import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/odoo_value.dart';
import '../../../../core/network/odoo_report_downloader.dart';
import '../../../../core/network/odoo_rpc_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/stock_picking.dart';
import '../../domain/entities/transfer_catalog.dart';
import '../../domain/primary_origin_resolver.dart';
import '../../domain/transfer_company_validator.dart';

class TransfersRepository {
  TransfersRepository(this._rpc, {OdooReportDownloader? reportDownloader})
      : _reportDownloader = reportDownloader ?? OdooReportDownloader();

  final OdooRpcClient _rpc;
  final OdooReportDownloader _reportDownloader;
  List<int>? _internalPickingTypeIds;

  static const _pickingFields = [
    'id',
    'name',
    'state',
    'scheduled_date',
    'date_done',
    'origin',
    'location_id',
    'location_dest_id',
    'user_id',
    'picking_type_id',
    'company_id',
  ];

  List<dynamic> _buildPickingsDomain({
    required List<int> typeIds,
    int? companyId,
    String? stateFilter,
    String? searchQuery,
  }) {
    final domain = <dynamic>[..._internalDomain(typeIds)];

    if (companyId != null) {
      domain.add(['company_id', '=', companyId]);
    }
    if (stateFilter != null && stateFilter.isNotEmpty) {
      domain.add(['state', '=', stateFilter]);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      domain.add('|');
      domain.add('|');
      domain.add(['name', 'ilike', q]);
      domain.add(['origin', 'ilike', q]);
      domain.add(['location_id', 'ilike', q]);
    }
    return domain;
  }

  Future<List<int>> _getInternalPickingTypeIds({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
  }) async {
    if (_internalPickingTypeIds != null) return _internalPickingTypeIds!;

    final types = await _rpc.searchRead(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      model: 'stock.picking.type',
      domain: [
        ['code', '=', 'internal'],
      ],
      fields: ['id', 'name', 'code'],
      limit: 100,
    );
    _internalPickingTypeIds = types.map((t) => t['id'] as int).toList();
    return _internalPickingTypeIds!;
  }

  List<dynamic> _internalDomain(List<int> typeIds) {
    if (typeIds.isEmpty) {
      return [
        ['picking_type_id.code', '=', 'internal'],
      ];
    }
    return [
      ['picking_type_id', 'in', typeIds],
    ];
  }

  Future<Result<List<ResCompany>>> fetchCompanies({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
  }) async {
    try {
      final rows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'res.company',
        domain: const [],
        fields: ['id', 'name'],
        limit: 200,
        order: 'name',
      );
      return Success(rows.map(ResCompany.fromOdoo).toList());
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al cargar empresas: $e'));
    }
  }

  Future<Result<List<StockPicking>>> fetchPickings({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    String? stateFilter,
    String? searchQuery,
    int? companyId,
    int offset = 0,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      final typeIds = await _getInternalPickingTypeIds(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
      );
      final domain = _buildPickingsDomain(
        typeIds: typeIds,
        companyId: companyId,
        stateFilter: stateFilter,
        searchQuery: searchQuery,
      );

      final rows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking',
        domain: domain,
        fields: _pickingFields,
        offset: offset,
        limit: limit,
        order: 'scheduled_date desc, id desc',
      );

      return Success(rows.map(StockPicking.fromOdoo).toList());
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al cargar transferencias: $e'));
    }
  }

  Future<Result<TransferStats>> fetchStats({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    int? companyId,
  }) async {
    try {
      final typeIds = await _getInternalPickingTypeIds(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
      );
      final base = _buildPickingsDomain(typeIds: typeIds, companyId: companyId);

      Future<int> countFor(List<dynamic> extra) async {
        final domain = [...base, ...extra];
        final n = await _rpc.executeKw<int>(
          baseUrl: baseUrl,
          database: database,
          uid: uid,
          password: password,
          model: 'stock.picking',
          method: 'search_count',
          args: [domain],
        );
        return n;
      }

      final pending = await countFor([
        ['state', 'in', ['draft', 'waiting']],
      ]);
      final inProgress = await countFor([
        ['state', 'in', ['confirmed', 'assigned']],
      ]);
      final done = await countFor([
        ['state', '=', 'done'],
      ]);
      final cancelled = await countFor([
        ['state', '=', 'cancel'],
      ]);

      return Success(
        TransferStats(
          pending: pending,
          inProgress: inProgress,
          done: done,
          cancelled: cancelled,
        ),
      );
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al cargar resumen: $e'));
    }
  }

  Future<Result<StockPicking>> fetchPickingById({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int pickingId,
  }) async {
    try {
      final rows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking',
        domain: [
          ['id', '=', pickingId],
        ],
        fields: _pickingFields,
        limit: 1,
      );
      if (rows.isEmpty) {
        return Failure(OdooRpcException('Transferencia no encontrada'));
      }
      return Success(StockPicking.fromOdoo(rows.first));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al cargar detalle: $e'));
    }
  }

  Future<Result<List<StockMoveLine>>> fetchMoveLines({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int pickingId,
  }) async {
    try {
      final moveLineResult = await _readMoveLines(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        pickingId: pickingId,
      );

      if (moveLineResult.isNotEmpty) {
        return Success(
          await _enrichLinesWithProductCodes(
            baseUrl: baseUrl,
            database: database,
            uid: uid,
            password: password,
            lines: moveLineResult,
          ),
        );
      }

      // En borrador suele existir solo stock.move (sin move.line aun).
      final moves = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.move',
        domain: [
          ['picking_id', '=', pickingId],
        ],
        fields: [
          'id',
          'product_id',
          'product_uom_qty',
          'quantity',
          'location_id',
          'location_dest_id',
        ],
        limit: 500,
        order: 'id',
      );

      final fromMoves = moves.map(StockMoveLine.fromStockMove).toList();
      return Success(
        await _enrichLinesWithProductCodes(
          baseUrl: baseUrl,
          database: database,
          uid: uid,
          password: password,
          lines: fromMoves,
        ),
      );
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al cargar lineas: $e'));
    }
  }

  Future<List<StockMoveLine>> _readMoveLines({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int pickingId,
  }) async {
    final rows = await _rpc.searchRead(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      model: 'stock.move.line',
      domain: [
        ['picking_id', '=', pickingId],
      ],
      fields: [
        'id',
        'product_id',
        'quantity',
        'qty_done',
        'location_id',
        'location_dest_id',
      ],
      limit: 500,
      order: 'id',
    );
    return rows.map(StockMoveLine.fromOdoo).toList();
  }

  Future<List<StockMoveLine>> _enrichLinesWithProductCodes({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required List<StockMoveLine> lines,
  }) async {
    final enriched = <StockMoveLine>[];
    for (final line in lines) {
      var current = line;
      if (line.productId > 0) {
        final products = await _rpc.searchRead(
          baseUrl: baseUrl,
          database: database,
          uid: uid,
          password: password,
          model: 'product.product',
          domain: [
            ['id', '=', line.productId],
          ],
          fields: ['barcode', 'default_code'],
          limit: 1,
        );
        if (products.isNotEmpty) {
          current = StockMoveLine(
            id: line.id,
            productId: line.productId,
            productName: line.productName,
            productUomQty: line.productUomQty,
            qtyDone: line.qtyDone,
            barcode: OdooValue.string(products.first['barcode']),
            defaultCode: OdooValue.string(products.first['default_code']),
            locationId: line.locationId,
            locationDestId: line.locationDestId,
            isStockMove: line.isStockMove,
          );
        }
      }
      enriched.add(current);
    }
    return enriched;
  }

  Future<Result<void>> updateLineQtyDone({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int lineId,
    required double qtyDone,
    bool isStockMove = false,
  }) async {
    try {
      if (isStockMove) {
        await _rpc.write(
          baseUrl: baseUrl,
          database: database,
          uid: uid,
          password: password,
          model: 'stock.move',
          ids: [lineId],
          values: {'product_uom_qty': qtyDone},
        );
      } else {
        await _rpc.write(
          baseUrl: baseUrl,
          database: database,
          uid: uid,
          password: password,
          model: 'stock.move.line',
          ids: [lineId],
          values: {'qty_done': qtyDone},
        );
      }
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al actualizar cantidad: $e'));
    }
  }

  Future<Result<void>> validatePicking({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int pickingId,
  }) async {
    try {
      await _rpc.callModelMethod(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking',
        method: 'button_validate',
        args: [
          [pickingId],
        ],
      );
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      // Fallback metodo alternativo en algunas versiones
      try {
        await _rpc.callModelMethod(
          baseUrl: baseUrl,
          database: database,
          uid: uid,
          password: password,
          model: 'stock.picking',
          method: 'action_done',
          args: [
            [pickingId],
          ],
        );
        return const Success(null);
      } on AppException catch (e2) {
        return Failure(e2);
      } catch (e2) {
        return Failure(
          OdooRpcException(
            'No se pudo validar la transferencia. Verifique estados y permisos.\n$e\n$e2',
          ),
        );
      }
    }
  }

  /// Cancela la transferencia (`action_cancel`), igual que el boton Cancelar en Odoo.
  Future<Result<void>> cancelPicking({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int pickingId,
  }) async {
    try {
      final rows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking',
        domain: [
          ['id', '=', pickingId],
        ],
        fields: ['id', 'name', 'state'],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const Failure(OdooRpcException('Transferencia no encontrada'));
      }

      final state = OdooValue.stringOrEmpty(rows.first['state']);
      if (!StockPicking.cancelableStates.contains(state)) {
        return Failure(
          OdooRpcException(
            'No se puede cancelar en estado ${_stateLabel(state)}. '
            'Solo: borrador, en espera, confirmado o preparacion.',
          ),
        );
      }

      await _rpc.callModelMethod(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking',
        method: 'action_cancel',
        args: [
          [pickingId],
        ],
      );
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al cancelar transferencia: $e'));
    }
  }

  static String _stateLabel(String state) {
    switch (state) {
      case 'draft':
        return 'Borrador';
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

  Future<Result<void>> confirmPicking({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int pickingId,
  }) async {
    try {
      await _rpc.callModelMethod(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking',
        method: 'action_confirm',
        args: [
          [pickingId],
        ],
      );
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al confirmar: $e'));
    }
  }

  Future<Result<List<InternalPickingType>>> fetchInternalPickingTypes({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    int? companyId,
  }) async {
    try {
      final domain = <dynamic>[
        ['code', '=', 'internal'],
      ];
      if (companyId != null) {
        domain.add(['company_id', '=', companyId]);
      }
      final rows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking.type',
        domain: domain,
        fields: [
          'id',
          'name',
          'default_location_src_id',
          'default_location_dest_id',
          'company_id',
        ],
        limit: 100,
        order: 'name',
      );
      return Success(rows.map(InternalPickingType.fromOdoo).toList());
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(
        OdooRpcException('Error al cargar tipos de operacion: $e'),
      );
    }
  }

  Future<Result<List<StockLocation>>> fetchInternalLocations({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    int? companyId,
  }) async {
    try {
      final domain = <dynamic>[
        ['usage', '=', 'internal'],
      ];
      if (companyId != null) {
        domain.add('|');
        domain.add(['company_id', '=', false]);
        domain.add(['company_id', '=', companyId]);
      }
      final rows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.location',
        domain: domain,
        fields: ['id', 'name', 'complete_name', 'company_id'],
        limit: 500,
        order: 'complete_name, name',
      );
      final locations = rows.map(StockLocation.fromOdoo).toList();
      if (companyId != null) {
        return Success(
          locations
              .where(
                (l) =>
                    l.companyId == null || l.companyId == companyId,
              )
              .toList(),
        );
      }
      return Success(locations);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al cargar ubicaciones: $e'));
    }
  }

  /// Cantidad disponible del producto en una ubicacion (incluye sububicaciones).
  Future<Result<double>> fetchAvailableQuantityAtLocation({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int productId,
    required int locationId,
  }) async {
    try {
      final rows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.quant',
        domain: [
          ['product_id', '=', productId],
          ['location_id', 'child_of', locationId],
        ],
        fields: ['quantity', 'reserved_quantity', 'available_quantity'],
        limit: 200,
      );

      var total = 0.0;
      for (final row in rows) {
        final available = OdooValue.decimal(row['available_quantity']);
        if (available != null) {
          total += available;
          continue;
        }
        final qty = OdooValue.decimal(row['quantity']) ?? 0;
        final reserved = OdooValue.decimal(row['reserved_quantity']) ?? 0;
        total += qty - reserved;
      }
      return Success(total < 0 ? 0 : total);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al consultar stock: $e'));
    }
  }

  /// Stock en la ubicacion de origen primaria resuelta para la empresa del producto.
  Future<Result<StockCheckResult>> checkStockAtPrimaryOrigin({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int productId,
    required int companyId,
    required String primaryOriginKey,
    required double requestedQty,
  }) async {
    final locationsResult = await fetchInternalLocations(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      companyId: companyId,
    );

    late final List<StockLocation> locations;
    switch (locationsResult) {
      case Success(:final value):
        locations = value;
      case Failure(:final error):
        return Failure(error);
    }

    final location = PrimaryOriginResolver.resolve(locations, primaryOriginKey);
    if (location == null) {
      return Failure(
        OdooRpcException(
          'No existe ubicacion de origen "$primaryOriginKey" para esta empresa',
        ),
      );
    }

    final qtyResult = await fetchAvailableQuantityAtLocation(
      baseUrl: baseUrl,
      database: database,
      uid: uid,
      password: password,
      productId: productId,
      locationId: location.id,
    );

    return switch (qtyResult) {
      Success(:final value) => Success(
          StockCheckResult(
            locationId: location.id,
            locationLabel: location.displayLabel,
            availableQty: value,
            requestedQty: requestedQty,
          ),
        ),
      Failure(:final error) => Failure(error),
    };
  }

  Future<Result<List<ProductOption>>> searchProducts({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String query,
    int limit = 25,
  }) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return const Success([]);

      final rows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'product.product',
        domain: [
          '|',
          '|',
          ['name', 'ilike', q],
          ['default_code', 'ilike', q],
          ['barcode', '=', q],
        ],
        fields: [
          'id',
          'name',
          'barcode',
          'default_code',
          'uom_id',
          'company_id',
        ],
        limit: limit,
        order: 'name',
      );
      return Success(rows.map(ProductOption.fromOdoo).toList());
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al buscar productos: $e'));
    }
  }

  /// Busca producto por codigo de barras o referencia interna (Enter en grilla).
  Future<Result<List<ProductOption>>> findProductsByCode({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required String code,
  }) async {
    try {
      final c = code.trim();
      if (c.isEmpty) return const Success([]);

      final exact = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'product.product',
        domain: [
          '|',
          ['barcode', '=', c],
          ['default_code', '=', c],
        ],
        fields: [
          'id',
          'name',
          'barcode',
          'default_code',
          'uom_id',
          'company_id',
        ],
        limit: 10,
      );
      if (exact.isNotEmpty) {
        return Success(exact.map(ProductOption.fromOdoo).toList());
      }

      return searchProducts(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        query: c,
        limit: 10,
      );
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al buscar codigo: $e'));
    }
  }

  /// Crea una transferencia interna por cada empresa detectada en las lineas.
  Future<Result<List<int>>> createTransfersByCompany({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required Map<int, List<TransferLineDraft>> linesByCompany,
    String? origin,
    bool confirmAfterCreate = true,
  }) async {
    try {
      if (linesByCompany.isEmpty) {
        return Failure(
          OdooRpcException('No hay lineas validas para crear transferencias'),
        );
      }

      final createdIds = <int>[];
      for (final entry in linesByCompany.entries) {
        final companyId = entry.key;
        final lines = entry.value;

        final typesResult = await fetchInternalPickingTypes(
          baseUrl: baseUrl,
          database: database,
          uid: uid,
          password: password,
          companyId: companyId,
        );
        late final List<InternalPickingType> types;
        switch (typesResult) {
          case Success(:final value):
            types = value;
          case Failure(:final error):
            return Failure(error);
        }
        if (types.isEmpty) {
          return Failure(
            OdooRpcException(
              'Sin tipo de operacion interna para empresa '
              '${lines.first.companyName ?? companyId}',
            ),
          );
        }

        final matchingTypes = types
            .where((t) => t.companyId == null || t.companyId == companyId)
            .toList();
        if (matchingTypes.isEmpty) {
          return Failure(
            OdooRpcException(
              'Sin tipo de operacion interna para la empresa '
              '${lines.first.companyName ?? companyId}',
            ),
          );
        }
        final type = matchingTypes.first;
        final sourceId = type.defaultSourceId;
        final destId = type.defaultDestId;
        if (sourceId == null || destId == null) {
          return Failure(
            OdooRpcException(
              'Configure ubicaciones por defecto en el tipo de operacion '
              '"${type.name}" (${lines.first.companyName})',
            ),
          );
        }

        final createResult = await createInternalTransfer(
          baseUrl: baseUrl,
          database: database,
          uid: uid,
          password: password,
          pickingTypeId: type.id,
          sourceLocationId: sourceId,
          destLocationId: destId,
          lines: lines,
          origin: origin,
          companyId: companyId,
          confirmAfterCreate: confirmAfterCreate,
        );
        switch (createResult) {
          case Success(:final value):
            createdIds.add(value);
          case Failure(:final error):
            return Failure(error);
        }
      }
      return Success(createdIds);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(
        OdooRpcException('Error al crear transferencias: $e'),
      );
    }
  }

  /// Valida en Odoo que productos, ubicaciones y tipo de operacion coincidan con la empresa.
  Future<Result<void>> verifyTransferCompanyConsistency({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int companyId,
    required String companyName,
    required List<TransferLineDraft> lines,
    required int pickingTypeId,
    required int sourceLocationId,
    required int destLocationId,
  }) async {
    try {
      if (lines.isEmpty) {
        return Failure(
          OdooRpcException('No hay productos para validar'),
        );
      }

      final productIds = lines.map((l) => l.productId).toSet().toList();
      final productRows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'product.product',
        domain: [
          ['id', 'in', productIds],
        ],
        fields: ['id', 'name', 'default_code', 'company_id'],
        limit: productIds.length,
      );

      final productsById = <int, OdooCompanyRecord>{
        for (final row in productRows)
          row['id'] as int: OdooCompanyRecord(
            id: row['id'] as int,
            label: OdooValue.string(row['default_code']) ??
                OdooValue.stringOrEmpty(row['name']),
            companyId: OdooValue.many2oneId(row['company_id']),
            companyName: OdooValue.many2oneName(row['company_id']),
          ),
      };

      final locationRows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.location',
        domain: [
          ['id', 'in', [sourceLocationId, destLocationId]],
        ],
        fields: ['id', 'name', 'complete_name', 'company_id'],
        limit: 2,
      );

      final locationsById = <int, OdooCompanyRecord>{
        for (final row in locationRows)
          row['id'] as int: OdooCompanyRecord(
            id: row['id'] as int,
            label: OdooValue.string(row['complete_name']) ??
                OdooValue.stringOrEmpty(row['name']),
            companyId: OdooValue.many2oneId(row['company_id']),
            companyName: OdooValue.many2oneName(row['company_id']),
          ),
      };

      final typeRows = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking.type',
        domain: [
          ['id', '=', pickingTypeId],
        ],
        fields: ['id', 'name', 'company_id'],
        limit: 1,
      );

      final typeRow = typeRows.isEmpty ? null : typeRows.first;
      final pickingTypeCompanyId =
          typeRow == null ? null : OdooValue.many2oneId(typeRow['company_id']);
      final pickingTypeCompanyName = typeRow == null
          ? null
          : OdooValue.many2oneName(typeRow['company_id']);
      final pickingTypeLabel = typeRow == null
          ? null
          : OdooValue.stringOrEmpty(typeRow['name']);

      final issues = TransferCompanyValidator.collectIssues(
        expectedCompanyId: companyId,
        lines: lines,
        productsById: productsById,
        locationsById: locationsById,
        sourceLocationId: sourceLocationId,
        destLocationId: destLocationId,
        pickingTypeCompanyId: pickingTypeCompanyId,
        pickingTypeCompanyName: pickingTypeCompanyName,
        pickingTypeLabel: pickingTypeLabel,
      );

      if (issues.isNotEmpty) {
        return Failure(
          OdooRpcException(
            TransferCompanyValidator.formatBlockingMessage(
              expectedCompanyName: companyName,
              issues: issues,
            ),
          ),
        );
      }

      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(
        OdooRpcException('Error al validar empresa de la transferencia: $e'),
      );
    }
  }

  Future<Result<int>> createInternalTransfer({
    required String baseUrl,
    required String database,
    required int uid,
    required String password,
    required int pickingTypeId,
    required int sourceLocationId,
    required int destLocationId,
    required List<TransferLineDraft> lines,
    String? origin,
    int? companyId,
    bool confirmAfterCreate = true,
  }) async {
    try {
      if (lines.isEmpty) {
        return Failure(
          OdooRpcException('Agregue al menos un producto a la transferencia'),
        );
      }
      if (companyId == null) {
        return Failure(
          OdooRpcException(
            'Falta la empresa del borrador; revise la grilla de productos',
          ),
        );
      }
      if (sourceLocationId == destLocationId) {
        return Failure(
          OdooRpcException(
            'La ubicacion de origen y destino deben ser diferentes',
          ),
        );
      }

      final companyLabel = lines
              .map((l) => l.companyName)
              .whereType<String>()
              .where((n) => n.isNotEmpty)
              .firstOrNull ??
          'Empresa $companyId';

      final consistency = await verifyTransferCompanyConsistency(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        companyId: companyId,
        companyName: companyLabel,
        lines: lines,
        pickingTypeId: pickingTypeId,
        sourceLocationId: sourceLocationId,
        destLocationId: destLocationId,
      );
      if (consistency case Failure(:final error)) {
        return Failure(error);
      }

      final moves = <List<dynamic>>[];
      for (final line in lines) {
        final move = <String, dynamic>{
          'name': line.productName,
          'product_id': line.productId,
          'product_uom_qty': line.quantity,
          'location_id': sourceLocationId,
          'location_dest_id': destLocationId,
        };
        if (line.uomId != null) move['product_uom'] = line.uomId;
        moves.add([0, 0, move]);
      }

      final values = <String, dynamic>{
        'picking_type_id': pickingTypeId,
        'location_id': sourceLocationId,
        'location_dest_id': destLocationId,
        'move_ids': moves,
      };
      values['company_id'] = companyId;
      final originText = origin?.trim();
      if (originText != null && originText.isNotEmpty) {
        values['origin'] = originText;
      }

      final pickingId = await _rpc.create(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'stock.picking',
        values: values,
      );

      if (confirmAfterCreate) {
        try {
          await _rpc.callModelMethod(
            baseUrl: baseUrl,
            database: database,
            uid: uid,
            password: password,
            model: 'stock.picking',
            method: 'action_confirm',
            args: [
              [pickingId],
            ],
          );
        } catch (_) {
          // La transferencia se creo; confirmar puede fallar por permisos/stock
        }
      }

      return Success(pickingId);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al crear transferencia: $e'));
    }
  }

  /// PDF del reporte de transferencia via URL web de Odoo (no RPC privado).
  Future<Result<Uint8List>> downloadPickingReportPdf({
    required String baseUrl,
    required String database,
    required int uid,
    required String login,
    required String password,
    required int pickingId,
  }) async {
    try {
      final reports = await _rpc.searchRead(
        baseUrl: baseUrl,
        database: database,
        uid: uid,
        password: password,
        model: 'ir.actions.report',
        domain: [
          ['model', '=', 'stock.picking'],
          ['report_type', '=', 'qweb-pdf'],
        ],
        fields: ['report_name', 'name'],
        limit: 20,
      );

      final reportNames = <String>[
        for (final r in reports)
          if (OdooValue.string(r['report_name']) != null)
            OdooValue.string(r['report_name'])!,
        'stock.report_picking',
        'stock.report_deliveryslip',
      ];

      final bytes = await _reportDownloader.downloadPdf(
        baseUrl: baseUrl,
        database: database,
        login: login,
        password: password,
        reportNames: reportNames,
        documentIds: [pickingId],
      );
      return Success(bytes);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OdooRpcException('Error al generar PDF: $e'));
    }
  }

  void clearCache() => _internalPickingTypeIds = null;
}
