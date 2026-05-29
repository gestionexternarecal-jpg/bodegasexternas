import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/company_badge.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../data/repositories/transfers_repository.dart';
import '../../domain/entities/stock_picking.dart';
import '../../domain/entities/transfer_catalog.dart';
import '../../domain/primary_origin_resolver.dart';
import '../providers/transfers_providers.dart';

enum TransferProcessMode { borrador, confirmado }

/// Configuracion de ubicaciones y procesamiento por empresa.
class CompanyProcessConfig {
  CompanyProcessConfig({
    required this.companyId,
    required this.companyName,
    required this.lines,
    this.sourceLocationId,
    this.destLocationId,
  });

  final int companyId;
  final String companyName;
  final List<TransferLineDraft> lines;
  int? sourceLocationId;
  int? destLocationId;
  bool isProcessing = false;
  bool isPrinting = false;
  bool isDone = false;
  int? createdPickingId;
  String? createdPickingName;
  String? createdPickingState;
  String? createdPickingStateLabel;
  bool isCancelling = false;

  bool get canCancelPicking =>
      createdPickingState != null &&
      StockPicking.cancelableStates.contains(createdPickingState);
}

class CompanyProcessPanel extends ConsumerStatefulWidget {
  const CompanyProcessPanel({
    super.key,
    required this.configs,
    required this.primaryOriginKey,
    this.documentOrigin,
    required this.onBack,
  });

  final List<CompanyProcessConfig> configs;
  /// Nombre de ubicacion primaria (ej. "Casa de la moneda").
  final String primaryOriginKey;
  /// Referencia Odoo `stock.picking.origin` (Documento origen).
  final String? documentOrigin;
  final VoidCallback onBack;

  @override
  ConsumerState<CompanyProcessPanel> createState() =>
      _CompanyProcessPanelState();
}

class _CompanyProcessPanelState extends ConsumerState<CompanyProcessPanel> {
  TransferProcessMode _mode = TransferProcessMode.borrador;
  late List<CompanyProcessConfig> _configs;

  @override
  void initState() {
    super.initState();
    _configs = widget.configs;
  }

  TransfersRepository get _repo => ref.read(transfersRepositoryProvider);

  ActiveSession? get _active => ref.read(activeSessionProvider);

  Future<void> _processCompany(int index) async {
    final active = _active;
    if (active == null) return;

    final config = _configs[index];
    if (config.sourceLocationId == null || config.destLocationId == null) {
      AppSnackbar.show(
        context,
        message: 'Seleccione ubicacion origen y destino',
        isError: true,
      );
      return;
    }
    if (config.sourceLocationId == config.destLocationId) {
      AppSnackbar.show(
        context,
        message: 'Origen y destino deben ser ubicaciones diferentes',
        isError: true,
      );
      return;
    }

    setState(() => config.isProcessing = true);

    final typesResult = await _repo.fetchInternalPickingTypes(
      baseUrl: active.session.baseUrl,
      database: active.session.database,
      uid: active.session.uid,
      password: active.password,
      companyId: config.companyId,
    );

    late final List<InternalPickingType> types;
    switch (typesResult) {
      case Success(:final value):
        types = value;
      case Failure(:final error):
        if (!mounted) return;
        setState(() => config.isProcessing = false);
        AppSnackbar.show(context, message: error.message, isError: true);
        return;
    }

    if (types.isEmpty) {
      if (!mounted) return;
      setState(() => config.isProcessing = false);
      AppSnackbar.show(
        context,
        message: 'Sin tipo de operacion interna para ${config.companyName}',
        isError: true,
      );
      return;
    }

    final matchingTypes = types
        .where(
          (t) => t.companyId == null || t.companyId == config.companyId,
        )
        .toList();
    if (matchingTypes.isEmpty) {
      if (!mounted) return;
      setState(() => config.isProcessing = false);
      AppSnackbar.show(
        context,
        message:
            'Ningun tipo de operacion interna corresponde a ${config.companyName}',
        isError: true,
      );
      return;
    }

    final result = await _repo.createInternalTransfer(
      baseUrl: active.session.baseUrl,
      database: active.session.database,
      uid: active.session.uid,
      password: active.password,
      pickingTypeId: matchingTypes.first.id,
      sourceLocationId: config.sourceLocationId!,
      destLocationId: config.destLocationId!,
      lines: config.lines,
      origin: widget.documentOrigin,
      companyId: config.companyId,
      confirmAfterCreate: _mode == TransferProcessMode.confirmado,
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final value):
        final pickingResult = await _repo.fetchPickingById(
          baseUrl: active.session.baseUrl,
          database: active.session.database,
          uid: active.session.uid,
          password: active.password,
          pickingId: value,
        );

        if (!mounted) return;

        String? docName;
        String? stateLabel;
        switch (pickingResult) {
          case Success(:final value):
            docName = value.name;
            stateLabel = value.stateLabelSpanish;
            config.createdPickingState = value.state;
          case Failure():
            docName = 'ID $value';
            stateLabel = _mode == TransferProcessMode.confirmado
                ? 'Confirmado'
                : 'Borrador';
            config.createdPickingState = _mode == TransferProcessMode.borrador
                ? 'draft'
                : 'confirmed';
        }

        setState(() {
          config.isProcessing = false;
          config.isDone = true;
          config.createdPickingId = value;
          config.createdPickingName = docName;
          config.createdPickingStateLabel = stateLabel;
        });
        ref.invalidate(transfersListProvider);
        ref.invalidate(transferStatsProvider);
        AppSnackbar.show(
          context,
          message: 'Documento generado: $docName ($stateLabel)',
        );
      case Failure(:final error):
        setState(() => config.isProcessing = false);
        AppSnackbar.show(context, message: error.message, isError: true);
    }
  }

  Future<bool> _confirmCancel(BuildContext context, CompanyProcessConfig config) {
    final name = config.createdPickingName ?? 'esta transferencia';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar transferencia'),
        content: Text(
          'Se cancelara el documento $name en Odoo (action_cancel).\n'
          'Las reservas de stock se liberaran. El documento quedara '
          'como cancelado en el historial.',
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
    ).then((v) => v ?? false);
  }

  Future<void> _cancelPicking(int index) async {
    final active = _active;
    if (active == null) return;

    final config = _configs[index];
    final pickingId = config.createdPickingId;
    if (pickingId == null) return;

    if (!config.canCancelPicking) {
      AppSnackbar.show(
        context,
        message: 'Este documento no se puede cancelar en su estado actual',
        isError: true,
      );
      return;
    }

    final confirmed = await _confirmCancel(context, config);
    if (!confirmed || !mounted) return;

    setState(() => config.isCancelling = true);

    final result = await _repo.cancelPicking(
      baseUrl: active.session.baseUrl,
      database: active.session.database,
      uid: active.session.uid,
      password: active.password,
      pickingId: pickingId,
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        setState(() {
          config.isCancelling = false;
          config.isDone = false;
          config.createdPickingId = null;
          config.createdPickingName = null;
          config.createdPickingState = null;
          config.createdPickingStateLabel = null;
        });
        ref.invalidate(transfersListProvider);
        ref.invalidate(transferStatsProvider);
        AppSnackbar.show(
          context,
          message:
              'Transferencia cancelada en Odoo. Puede procesar de nuevo.',
        );
      case Failure(:final error):
        setState(() => config.isCancelling = false);
        AppSnackbar.show(context, message: error.message, isError: true);
    }
  }

  Future<void> _printPicking(int index) async {
    final active = _active;
    if (active == null) return;

    final config = _configs[index];
    final pickingId = config.createdPickingId;
    if (pickingId == null) return;

    setState(() => config.isPrinting = true);

    final result = await _repo.downloadPickingReportPdf(
      baseUrl: active.session.baseUrl,
      database: active.session.database,
      uid: active.session.uid,
      login: active.session.login,
      password: active.password,
      pickingId: pickingId,
    );

    if (!mounted) return;
    setState(() => config.isPrinting = false);

    switch (result) {
      case Success(:final value):
        await Printing.layoutPdf(
          onLayout: (_) async => value,
          name: config.createdPickingName ?? 'transferencia_$pickingId',
        );
      case Failure(:final error):
        AppSnackbar.show(context, message: error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _configs.every((c) => c.isDone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: 0.35,
              ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.pin_drop_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicacion de origen primaria',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.primaryOriginKey,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'El origen de cada empresa se ajusta a su ruta '
                        '(ej. PHSA/…, PV/…).',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado al procesar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<TransferProcessMode>(
                  segments: const [
                    ButtonSegment(
                      value: TransferProcessMode.borrador,
                      label: Text('Borrador'),
                      icon: Icon(Icons.edit_note_outlined),
                    ),
                    ButtonSegment(
                      value: TransferProcessMode.confirmado,
                      label: Text('Confirmado'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) {
                    if (s.isNotEmpty) setState(() => _mode = s.first);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _mode == TransferProcessMode.borrador
                      ? 'Crea la transferencia en estado borrador en Odoo.'
                      : 'Crea y confirma la transferencia (action_confirm).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_configs.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CompanyProcessCard(
              config: _configs[i],
              primaryOriginKey: widget.primaryOriginKey,
              onSourceChanged: (id) =>
                  setState(() => _configs[i].sourceLocationId = id),
              onDestChanged: (id) =>
                  setState(() => _configs[i].destLocationId = id),
              onProcess: _configs[i].isDone ? null : () => _processCompany(i),
              onPrint: _configs[i].isDone &&
                      _configs[i].createdPickingId != null
                  ? () => _printPicking(i)
                  : null,
              onCancel: _configs[i].isDone && _configs[i].canCancelPicking
                  ? () => _cancelPicking(i)
                  : null,
            ),
          );
        }),
        if (allDone) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentos generados',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final c in _configs)
                    if (c.createdPickingName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${c.companyName}: ${c.createdPickingName} '
                          '(${c.createdPickingStateLabel ?? ''})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a la grilla'),
            ),
            const Spacer(),
            if (allDone)
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.list_alt),
                label: const Text('Ver listado'),
              ),
          ],
        ),
      ],
    );
  }
}

class _CompanyProcessCard extends ConsumerStatefulWidget {
  const _CompanyProcessCard({
    required this.config,
    required this.primaryOriginKey,
    required this.onSourceChanged,
    required this.onDestChanged,
    required this.onProcess,
    required this.onPrint,
    required this.onCancel,
  });

  final CompanyProcessConfig config;
  final String primaryOriginKey;
  final ValueChanged<int?> onSourceChanged;
  final ValueChanged<int?> onDestChanged;
  final VoidCallback? onProcess;
  final VoidCallback? onPrint;
  final VoidCallback? onCancel;

  @override
  ConsumerState<_CompanyProcessCard> createState() =>
      _CompanyProcessCardState();
}

class _CompanyProcessCardState extends ConsumerState<_CompanyProcessCard> {
  bool _defaultsApplied = false;
  bool _defaultsQueued = false;

  @override
  void didUpdateWidget(_CompanyProcessCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryOriginKey != widget.primaryOriginKey ||
        oldWidget.config.companyId != widget.config.companyId) {
      _defaultsApplied = false;
      _defaultsQueued = false;
    } else if (widget.config.sourceLocationId != null) {
      _defaultsApplied = true;
    }
  }

  /// No llamar setState del padre durante build; aplicar tras el frame.
  void _queueApplyDefaults(List<StockLocation> locations) {
    if (_defaultsApplied || _defaultsQueued) return;
    _defaultsQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _defaultsQueued = false;
      if (!mounted || _defaultsApplied) return;
      _applyDefaults(locations);
    });
  }

  void _applyDefaults(List<StockLocation> locations) {
    final primary = PrimaryOriginResolver.resolve(
      locations,
      widget.primaryOriginKey,
    );

    var srcId = widget.config.sourceLocationId;
    if (srcId == null && primary != null) {
      srcId = primary.id;
      widget.onSourceChanged(srcId);
    }

    if (widget.config.destLocationId == null) {
      final types = ref
          .read(internalPickingTypesProvider(widget.config.companyId))
          .valueOrNull;
      if (types != null && types.isNotEmpty) {
        final dest = types.first.defaultDestId;
        if (dest != null &&
            dest != srcId &&
            locations.any((l) => l.id == dest)) {
          widget.onDestChanged(dest);
        }
      }
    }

    if (srcId != null) {
      _defaultsApplied = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync =
        ref.watch(internalLocationsProvider(widget.config.companyId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: locationsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => AppErrorBanner(
            message: e is AppException ? e.message : e.toString(),
          ),
          data: (locations) {
            _queueApplyDefaults(locations);
            final resolvedOrigin = PrimaryOriginResolver.resolve(
              locations,
              widget.primaryOriginKey,
            );
            final originMissing = resolvedOrigin == null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CompanyBadge(
                        companyName: widget.config.companyName,
                      ),
                    ),
                    Chip(
                      label: Text('${widget.config.lines.length} productos'),
                    ),
                    if (widget.config.isDone)
                      Icon(
                        Icons.check_circle,
                        color: context.semantic.success,
                      ),
                  ],
                ),
                if (originMissing) ...[
                  const SizedBox(height: 8),
                  AppErrorBanner(
                    message:
                        'No existe ubicacion "${widget.primaryOriginKey}" '
                        'para ${widget.config.companyName}',
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Origen asignado: ${resolvedOrigin.displayLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: widget.config.sourceLocationId,
                  decoration: const InputDecoration(
                    labelText: 'Ubicacion origen *',
                    prefixIcon: Icon(Icons.warehouse_outlined),
                  ),
                  items: locations
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: widget.config.isDone ? null : widget.onSourceChanged,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: widget.config.destLocationId,
                  decoration: const InputDecoration(
                    labelText: 'Ubicacion destino *',
                    prefixIcon: Icon(Icons.move_down),
                  ),
                  items: locations
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: widget.config.isDone ? null : widget.onDestChanged,
                ),
                const SizedBox(height: 16),
                if (widget.config.isDone &&
                    widget.config.createdPickingId != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documento generado',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          widget.config.createdPickingName ??
                              'ID ${widget.config.createdPickingId}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (widget.config.createdPickingStateLabel != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Estado: ${widget.config.createdPickingStateLabel}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.config.isPrinting
                              ? null
                              : widget.onPrint,
                          icon: widget.config.isPrinting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.print_outlined),
                          label: Text(
                            widget.config.isPrinting
                                ? 'Generando PDF...'
                                : 'Imprimir',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '/transfer/${widget.config.createdPickingId}',
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Ver'),
                      ),
                    ],
                  ),
                  if (widget.onCancel != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: widget.config.isCancelling
                          ? null
                          : widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      icon: widget.config.isCancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: Text(
                        widget.config.isCancelling
                            ? 'Cancelando...'
                            : 'Cancelar transferencia',
                      ),
                    ),
                  ],
                ] else
                  FilledButton.icon(
                    onPressed: widget.config.isProcessing ||
                            originMissing
                        ? null
                        : widget.onProcess,
                    icon: widget.config.isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                      widget.config.isProcessing
                          ? 'Procesando...'
                          : 'Procesar movimientos',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
