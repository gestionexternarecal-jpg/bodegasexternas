import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_layout.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/ecuador_datetime.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/company_badge.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/state_chip.dart';
import '../../data/repositories/transfers_repository.dart';
import '../../domain/entities/stock_picking.dart';
import '../providers/transfers_providers.dart';

class TransferDetailScreen extends ConsumerStatefulWidget {
  const TransferDetailScreen({super.key, required this.pickingId});

  final int pickingId;

  @override
  ConsumerState<TransferDetailScreen> createState() =>
      _TransferDetailScreenState();
}

class _TransferDetailScreenState extends ConsumerState<TransferDetailScreen> {
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  TransfersRepository get _repo => ref.read(transfersRepositoryProvider);

  ActiveSession? get _active => ref.read(activeSessionProvider);

  Future<void> _runAction(Future<Result<void>> Function() action, String ok) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        _show(ok);
        ref.invalidate(transferDetailProvider(widget.pickingId));
        ref.invalidate(transferLinesProvider(widget.pickingId));
        ref.invalidate(transfersListProvider);
        ref.invalidate(transferStatsProvider);
      case Failure(:final error):
        _show(error.message, error: true);
    }
  }

  void _show(String msg, {bool error = false}) {
    AppSnackbar.show(context, message: msg, isError: error);
  }

  Future<void> _onScan(String code) async {
    final active = _active;
    if (active == null || code.trim().isEmpty) return;

    final lines = await ref.read(transferLinesProvider(widget.pickingId).future);
    final match = lines.where((l) {
      return l.barcode == code ||
          l.defaultCode == code ||
          l.productName.toLowerCase().contains(code.toLowerCase());
    }).toList();

    if (match.isEmpty) {
      _show('Producto no encontrado: $code', error: true);
      return;
    }

    final line = match.first;
    final newQty = line.qtyDone + 1;
    await _runAction(
      () => _repo.updateLineQtyDone(
        baseUrl: active.session.baseUrl,
        database: active.session.database,
        uid: active.session.uid,
        password: active.password,
        lineId: line.id,
        qtyDone: newQty,
        isStockMove: line.isStockMove,
      ),
      'Cantidad actualizada: ${line.productName}',
    );
    _scanController.clear();
    _scanFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final pickingAsync = ref.watch(transferDetailProvider(widget.pickingId));
    final linesAsync = ref.watch(transferLinesProvider(widget.pickingId));
    return pickingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppErrorBanner(message: e.toString()),
        ),
      ),
      data: (picking) => Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                Text(
                  picking.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 12),
                PickingStateChip(state: picking.state),
                const Spacer(),
                if (!_busy && !picking.isDone && !picking.isCancelled) ...[
                  if (picking.isDraft) ...[
                    FilledButton.tonal(
                      onPressed: () => _confirm(picking),
                      child: const Text('Confirmar'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (picking.canCancel) ...[
                    OutlinedButton.icon(
                      onPressed: () => _cancelPicking(picking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: () => _validate(picking),
                    child: const Text('Validar transferencia'),
                  ),
                ],
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                if (picking.companyName != null &&
                    picking.companyName!.isNotEmpty)
                  CompanyBadge(companyName: picking.companyName!),
                _Info('Origen', picking.locationName ?? '-'),
                _Info('Destino', picking.locationDestName ?? '-'),
                _Info(
                  'Programada',
                  EcuadorDateTime.formatDateTime(picking.scheduledDate),
                ),
                if (picking.dateDone != null)
                  _Info(
                    'Realizada',
                    EcuadorDateTime.formatDateTime(picking.dateDone),
                  ),
                _Info('Referencia', picking.origin ?? '-'),
              ],
            ),
            const SizedBox(height: 16),
            if (!picking.isDone)
              TextField(
                controller: _scanController,
                focusNode: _scanFocus,
                decoration: const InputDecoration(
                  labelText: 'Escanear codigo de barras',
                  hintText: 'Escanee y presione Enter',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
                onSubmitted: _onScan,
              ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: linesAsync.when(
                  data: (lines) {
                    if (lines.isEmpty) {
                      return const Center(child: Text('Sin lineas de producto'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: lines.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final line = lines[i];
                        return _LineTile(
                          line: line,
                          enabled: !picking.isDone && !picking.isCancelled,
                          onQtyChanged: (qty) => _updateQty(line, qty),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppErrorBanner(message: e.toString()),
        ),
      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelPicking(StockPicking picking) async {
    if (!picking.canCancel) {
      _show('Este documento no se puede cancelar en su estado actual', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar transferencia'),
        content: Text(
          'Se cancelara ${picking.name} en Odoo.\n'
          'Las reservas de stock se liberaran. El documento quedara '
          'en el historial como cancelado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar transferencia'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final active = _active!;
    setState(() => _busy = true);
    final result = await _repo.cancelPicking(
      baseUrl: active.session.baseUrl,
      database: active.session.database,
      uid: active.session.uid,
      password: active.password,
      pickingId: picking.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success():
        ref.invalidate(transferDetailProvider(widget.pickingId));
        ref.invalidate(transferLinesProvider(widget.pickingId));
        ref.invalidate(transfersListProvider);
        ref.invalidate(transferStatsProvider);
        _show('Transferencia cancelada en Odoo');
      case Failure(:final error):
        _show(error.message, error: true);
    }
  }

  Future<void> _confirm(StockPicking picking) async {
    final active = _active!;
    await _runAction(
      () => _repo.confirmPicking(
        baseUrl: active.session.baseUrl,
        database: active.session.database,
        uid: active.session.uid,
        password: active.password,
        pickingId: picking.id,
      ),
      'Transferencia confirmada',
    );
  }

  Future<void> _validate(StockPicking picking) async {
    final active = _active!;
    await _runAction(
      () => _repo.validatePicking(
        baseUrl: active.session.baseUrl,
        database: active.session.database,
        uid: active.session.uid,
        password: active.password,
        pickingId: picking.id,
      ),
      'Transferencia validada',
    );
  }

  Future<void> _updateQty(StockMoveLine line, double qty) async {
    final active = _active!;
    await _runAction(
      () => _repo.updateLineQtyDone(
        baseUrl: active.session.baseUrl,
        database: active.session.database,
        uid: active.session.uid,
        password: active.password,
        lineId: line.id,
        qtyDone: qty,
        isStockMove: line.isStockMove,
      ),
      'Cantidad guardada',
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _LineTile extends StatefulWidget {
  const _LineTile({
    required this.line,
    required this.enabled,
    required this.onQtyChanged,
  });

  final StockMoveLine line;
  final bool enabled;
  final ValueChanged<double> onQtyChanged;

  @override
  State<_LineTile> createState() => _LineTileState();
}

class _LineTileState extends State<_LineTile> {
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.line.qtyDone.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _LineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.qtyDone != widget.line.qtyDone) {
      _qtyController.text = widget.line.qtyDone.toString();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return ListTile(
      title: Text(line.productName),
      subtitle: Text(
        [
          if (line.barcode != null && line.barcode!.isNotEmpty)
            'CB: ${line.barcode}',
          if (line.defaultCode != null && line.defaultCode!.isNotEmpty)
            'Ref: ${line.defaultCode}',
          'Demandado: ${line.productUomQty}',
        ].join(' · '),
      ),
      trailing: SizedBox(
        width: 100,
        child: TextField(
          controller: _qtyController,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Hecho',
            isDense: true,
          ),
          onSubmitted: (v) {
            final qty = double.tryParse(v) ?? 0;
            widget.onQtyChanged(qty);
          },
        ),
      ),
    );
  }
}
