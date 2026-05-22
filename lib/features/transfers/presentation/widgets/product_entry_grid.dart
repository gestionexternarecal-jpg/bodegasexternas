import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/company_badge.dart';
import '../../data/repositories/transfers_repository.dart';
import '../../domain/bulk_import_row.dart';
import '../../domain/entities/transfer_catalog.dart';

/// Fila editable tipo Excel para codigo + cantidad + empresa detectada.
class ProductEntryGrid extends StatefulWidget {
  const ProductEntryGrid({
    super.key,
    required this.repo,
    required this.session,
    required this.fallbackCompanies,
    required this.primaryOriginKey,
    required this.documentOriginController,
    required this.onLinesChanged,
  });

  final TransfersRepository repo;
  final ({
    String baseUrl,
    String database,
    int uid,
    String password,
  }) session;
  final List<ResCompany> fallbackCompanies;
  /// Nombre de ubicacion primaria para validar stock por empresa.
  final String? primaryOriginKey;
  /// Referencia / documento origen (`stock.picking.origin` en Odoo).
  final TextEditingController documentOriginController;
  final ValueChanged<List<TransferLineDraft>> onLinesChanged;

  @override
  State<ProductEntryGrid> createState() => ProductEntryGridState();
}

class ProductEntryGridState extends State<ProductEntryGrid> {
  final List<_GridRow> _rows = [];
  int _searchingRow = -1;

  @override
  void initState() {
    super.initState();
    _ensureEmptyRows(5);
  }

  @override
  void didUpdateWidget(ProductEntryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryOriginKey != widget.primaryOriginKey) {
      for (var i = 0; i < _rows.length; i++) {
        if (_rows[i].isResolved) {
          _validateStock(i);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _ensureEmptyRows(int count) {
    while (_rows.length < count) {
      _rows.add(_GridRow());
    }
  }

  List<TransferLineDraft> _validatedLines() {
    return _rows
        .where((r) => r.isResolved && r.productId != null && r.quantity > 0)
        .map(
          (r) => TransferLineDraft(
            productId: r.productId!,
            productName: r.productName!,
            quantity: r.quantity,
            uomId: r.uomId,
            barcode: r.barcode,
            defaultCode: r.defaultCode,
            companyId: r.companyId,
            companyName: r.companyName,
          ),
        )
        .toList();
  }

  void _notifyChange() {
    widget.onLinesChanged(_validatedLines());
  }

  /// Lineas resueltas con problema de stock en origen primario.
  bool get hasBlockingStockIssues =>
      _rows.any((r) => r.isResolved && r.hasStockIssue);

  /// Producto encontrado pero cantidad en 0 (o vacia).
  bool get hasZeroQuantityResolvedLines =>
      _rows.any((r) => r.isResolved && r.quantity <= 0);

  List<TransferLineDraft> get validatedLinesSnapshot => _validatedLines();

  static double _parseQuantityText(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return double.tryParse(t) ?? 0;
  }

  /// Lee cantidad del campo; si es 0 o invalida, marca error y notifica.
  bool _syncQuantityFromField(int index) {
    final row = _rows[index];
    row.quantity = _parseQuantityText(row.qtyController.text);
    if (row.quantity > 0) {
      if (row.quantityError != null) {
        setState(() => row.quantityError = null);
      }
      return true;
    }
    setState(() {
      row.quantityError = 'Ingrese una cantidad mayor a 0';
    });
    AppSnackbar.show(
      context,
      message:
          'La cantidad no puede ser 0. Indique cuantas unidades transferir.',
      isError: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && index < _rows.length) {
        FocusScope.of(context).requestFocus(_rows[index].qtyFocus);
      }
    });
    return false;
  }

  int? _resolveCompanyId(ProductOption product) {
    if (product.companyId != null) return product.companyId;
    if (widget.fallbackCompanies.length == 1) {
      return widget.fallbackCompanies.first.id;
    }
    return null;
  }

  String? _resolveCompanyName(ProductOption product, int? companyId) {
    if (product.companyName != null && product.companyName!.isNotEmpty) {
      return product.companyName;
    }
    if (companyId != null) {
      for (final c in widget.fallbackCompanies) {
        if (c.id == companyId) return c.name;
      }
    }
    return companyId == null ? 'Sin empresa en producto' : null;
  }

  ProductOption? _pickProductForRow(
    List<ProductOption> products, {
    String? expectedDetail,
    required bool bulkMode,
  }) {
    if (products.length == 1) return products.first;
    if (expectedDetail != null && expectedDetail.trim().isNotEmpty) {
      final hint = expectedDetail.trim().toLowerCase();
      for (final p in products) {
        final name = p.name.toLowerCase();
        if (name.contains(hint) || hint.contains(name)) return p;
      }
    }
    return bulkMode ? products.first : null;
  }

  /// Importa filas desde Excel y resuelve productos en Odoo.
  Future<BulkImportReport> importBulkRows(
    List<BulkImportRow> entries, {
    void Function(int done, int total)? onProgress,
  }) async {
    for (final row in _rows) {
      row.dispose();
    }
    _rows.clear();

    final dataRows =
        entries.where((e) => e.codigo.trim().isNotEmpty).toList();

    for (final entry in dataRows) {
      final row = _GridRow();
      row.codeController.text = entry.codigo.trim();
      row.quantity = entry.cantidad > 0 ? entry.cantidad : 1;
      row.qtyController.text = row.quantity == row.quantity.roundToDouble()
          ? row.quantity.toInt().toString()
          : row.quantity.toString();
      _rows.add(row);
    }
    _ensureEmptyRows(5);

    var loaded = 0;
    var failed = 0;

    for (var i = 0; i < dataRows.length; i++) {
      await _searchRow(
        i,
        expectedDetail: dataRows[i].detalle,
        bulkMode: true,
        advanceFocus: false,
      );
      if (!mounted) break;

      final row = _rows[i];
      final ok = row.isResolved &&
          (row.companyError == null || row.companyError!.isEmpty) &&
          !row.hasStockIssue;
      if (ok) {
        loaded++;
      } else {
        failed++;
      }
      onProgress?.call(i + 1, dataRows.length);
    }
    _notifyChange();
    return BulkImportReport(
      totalRows: dataRows.length,
      loadedRows: loaded,
      failedRows: failed,
      skippedRows: entries.length - dataRows.length,
    );
  }

  Future<void> _searchRow(
    int index, {
    String? expectedDetail,
    bool bulkMode = false,
    bool advanceFocus = true,
  }) async {
    final row = _rows[index];
    final code = row.codeController.text.trim();
    if (code.isEmpty) return;

    row.quantity = _parseQuantityText(row.qtyController.text);
    if (!bulkMode && row.quantity <= 0) {
      _syncQuantityFromField(index);
      return;
    }

    setState(() {
      _searchingRow = index;
      row.clearProduct(keepCode: true);
      row.companyError = null;
      row.stockMessage = null;
      row.availableStock = null;
      row.stockLoading = false;
    });

    final result = await widget.repo.findProductsByCode(
      baseUrl: widget.session.baseUrl,
      database: widget.session.database,
      uid: widget.session.uid,
      password: widget.session.password,
      code: code,
    );

    if (!mounted) return;

    setState(() => _searchingRow = -1);

    switch (result) {
      case Success(:final value):
        final products = value;
        if (products.isEmpty) {
          setState(() {
            row.companyError = 'Codigo no encontrado';
          });
          _notifyChange();
          return;
        }

        var selected = _pickProductForRow(
          products,
          expectedDetail: expectedDetail,
          bulkMode: bulkMode,
        );
        if (selected == null && !bulkMode) {
          selected = await showDialog<ProductOption>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: Text('Varios productos para "$code"'),
              children: products
                  .map(
                    (p) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, p),
                      child: ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                          [
                            if (p.defaultCode != null) 'Ref: ${p.defaultCode}',
                            if (p.companyName != null) p.companyName!,
                          ].join(' · '),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        if (selected == null || !mounted) return;

        final companyId = _resolveCompanyId(selected);
        final companyName = _resolveCompanyName(selected, companyId);

        setState(() {
          row.applyProduct(
            selected!,
            companyId: companyId,
            companyName: companyName,
            quantity: row.quantity,
          );
          if (companyId == null) {
            row.companyError =
                'Producto sin empresa; seleccione una sola empresa en Odoo o asigne company_id al producto';
          }
        });

        await _validateStock(index);
        if (!mounted) return;

        _notifyChange();
        if (advanceFocus) _focusNextRow(index);
      case Failure(:final error):
        setState(() => row.companyError = error.message);
        _notifyChange();
    }
  }

  static String _formatQty(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  Future<void> _validateStock(int index) async {
    final row = _rows[index];
    final key = widget.primaryOriginKey?.trim();
    if (key == null || key.isEmpty) {
      if (mounted) {
        setState(() {
          row.stockMessage = null;
          row.availableStock = null;
          row.stockLoading = false;
        });
      }
      return;
    }
    if (row.productId == null || row.companyId == null) {
      if (mounted) {
        setState(() {
          row.stockMessage = null;
          row.availableStock = null;
          row.stockLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => row.stockLoading = true);

    final result = await widget.repo.checkStockAtPrimaryOrigin(
      baseUrl: widget.session.baseUrl,
      database: widget.session.database,
      uid: widget.session.uid,
      password: widget.session.password,
      productId: row.productId!,
      companyId: row.companyId!,
      primaryOriginKey: key,
      requestedQty: row.quantity,
    );

    if (!mounted || index >= _rows.length) return;

    setState(() {
      row.stockLoading = false;
      switch (result) {
        case Success(:final value):
          row.availableStock = value.availableQty;
          row.stockMessage = value.userMessage;
        case Failure(:final error):
          row.availableStock = null;
          row.stockMessage = error.message;
      }
    });
    _notifyChange();
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
      _ensureEmptyRows(5);
    });
    _notifyChange();
  }

  void _focusQty(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && index < _rows.length) {
        FocusScope.of(context).requestFocus(_rows[index].qtyFocus);
      }
    });
  }

  /// Tras Enter en cantidad: agrega fila si hace falta y mueve el foco al codigo siguiente.
  void _focusNextRow(int currentIndex) {
    final nextIndex = currentIndex + 1;
    setState(() {
      if (nextIndex >= _rows.length) {
        _rows.add(_GridRow());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && nextIndex < _rows.length) {
        FocusScope.of(context).requestFocus(_rows[nextIndex].codeFocus);
      }
    });
  }

  void _onCodeEnter(int index) {
    final code = _rows[index].codeController.text.trim();
    if (code.isEmpty) {
      _focusNextRow(index);
      return;
    }
    _focusQty(index);
  }

  void _onQtyEnter(int index) {
    final row = _rows[index];
    if (!_syncQuantityFromField(index)) return;

    if (row.isResolved) {
      _notifyChange();
      _validateStock(index);
      _focusNextRow(index);
      return;
    }
    _searchRow(index);
  }

  @override
  Widget build(BuildContext context) {
    final border = TableBorder.all(
      color: Theme.of(context).dividerColor,
      width: 1,
    );
    final headerStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: AppLayout.productGridMaxHeight(context),
          ),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: AppLayout.productGridTableWidth(context),
                child: Table(
                  border: border,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(48),
                    1: FixedColumnWidth(180),
                    2: FlexColumnWidth(2),
                    3: FixedColumnWidth(90),
                    4: FixedColumnWidth(100),
                    5: FixedColumnWidth(200),
                    6: FixedColumnWidth(44),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      children: [
                        _headerCell('#', headerStyle),
                        _headerCell('Codigo *', headerStyle),
                        _headerCell('Producto', headerStyle),
                        _headerCell('Cantidad *', headerStyle),
                        _headerCell('Stock origen', headerStyle),
                        _headerCell('Empresa', headerStyle),
                        _headerCell('', headerStyle),
                      ],
                    ),
                    for (var i = 0; i < _rows.length; i++)
                      _buildDataRow(context, i),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: TextField(
            controller: widget.documentOriginController,
            decoration: const InputDecoration(
              labelText: 'Documento origen',
              hintText: 'Referencia del documento (ej. ABAST.MATRIZ.CCA#3)',
              prefixIcon: Icon(Icons.description_outlined),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.characters,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(text, style: style),
    );
  }

  Widget _buildStockCell(BuildContext context, _GridRow row, bool isSearching) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    if (!row.isResolved || isSearching) {
      return Text(
        '-',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    if (row.stockLoading) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final originKey = widget.primaryOriginKey?.trim();
    if (originKey == null || originKey.isEmpty) {
      return Text(
        '-',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
      );
    }

    if (row.availableStock == null) {
      return Text(
        '-',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final qty = row.availableStock!;
    Color? color;
    if (row.hasStockIssue) {
      color = semantic.danger;
    } else if (qty > 0) {
      color = semantic.success;
    } else {
      color = scheme.onSurfaceVariant;
    }

    final uom = row.uomName?.trim();
    final uomLabel = (uom != null && uom.isNotEmpty) ? uom : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          uomLabel != null ? '${_formatQty(qty)} $uomLabel' : _formatQty(qty),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.2,
              ),
        ),
        if (row.hasStockIssue && row.stockMessage != null)
          Text(
            'Insuf.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 10,
                ),
          ),
      ],
    );
  }

  TableRow _buildDataRow(BuildContext context, int index) {
    final row = _rows[index];
    final isSearching = _searchingRow == index;
    final bg = index.isEven
        ? null
        : Theme.of(context).colorScheme.surfaceContainerLowest;

    return TableRow(
      decoration: bg != null ? BoxDecoration(color: bg) : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('${index + 1}', textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextField(
            controller: row.codeController,
            focusNode: row.codeFocus,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'CB / Ref',
              errorText: row.displayError,
              errorMaxLines: 3,
              suffixIcon: isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _onCodeEnter(index),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            row.productName ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: row.isResolved
                  ? null
                  : Theme.of(context).hintColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextField(
            controller: row.qtyController,
            focusNode: row.qtyFocus,
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              errorText: row.quantityError,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _onQtyEnter(index),
            onChanged: (v) {
              row.quantity = _parseQuantityText(v);
              if (row.quantity > 0 && row.quantityError != null) {
                setState(() => row.quantityError = null);
              }
              if (row.isResolved) {
                _notifyChange();
                _validateStock(index);
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: _buildStockCell(context, row, isSearching),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: row.companyName != null && row.companyName!.isNotEmpty
              ? CompanyBadge(companyName: row.companyName!, compact: true)
              : const Text('-', style: TextStyle(fontStyle: FontStyle.italic)),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: Theme.of(context).colorScheme.error,
          onPressed: row.isEmpty ? null : () => _removeRow(index),
        ),
      ],
    );
  }
}

class _GridRow {
  _GridRow() {
    qtyController.text = '0';
    quantity = 0;
  }

  final codeController = TextEditingController();
  final qtyController = TextEditingController();
  final codeFocus = FocusNode();
  final qtyFocus = FocusNode();

  int? productId;
  String? productName;
  double quantity = 0;
  String? quantityError;
  int? uomId;
  String? uomName;
  String? barcode;
  String? defaultCode;
  int? companyId;
  String? companyName;
  String? companyError;
  String? stockMessage;
  double? availableStock;
  bool stockLoading = false;

  String? get displayError => companyError ?? stockMessage;

  bool get isResolved => productId != null;
  bool get isEmpty => codeController.text.trim().isEmpty && !isResolved;
  bool get hasStockIssue => stockMessage != null && stockMessage!.isNotEmpty;

  void applyProduct(
    ProductOption p, {
    required int? companyId,
    required String? companyName,
    required double quantity,
  }) {
    productId = p.id;
    productName = p.name;
    uomId = p.uomId;
    uomName = p.uomName;
    barcode = p.barcode;
    defaultCode = p.defaultCode;
    this.companyId = companyId;
    this.companyName = companyName;
    this.quantity = quantity;
    qtyController.text = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    companyError = null;
    stockMessage = null;
    availableStock = null;
    stockLoading = false;
  }

  void clearProduct({bool keepCode = false}) {
    productId = null;
    productName = null;
    uomId = null;
    uomName = null;
    barcode = null;
    defaultCode = null;
    companyId = null;
    companyName = null;
    companyError = null;
    stockMessage = null;
    availableStock = null;
    stockLoading = false;
    if (!keepCode) codeController.clear();
  }

  void dispose() {
    codeController.dispose();
    qtyController.dispose();
    codeFocus.dispose();
    qtyFocus.dispose();
  }
}
