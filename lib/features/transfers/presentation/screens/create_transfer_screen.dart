import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../data/repositories/transfers_repository.dart';
import '../../domain/entities/transfer_catalog.dart';
import '../providers/transfers_providers.dart';
import '../widgets/bulk_upload_section.dart';
import '../widgets/company_process_panel.dart';
import '../widgets/product_entry_grid.dart';

class CreateTransferScreen extends ConsumerStatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  ConsumerState<CreateTransferScreen> createState() =>
      _CreateTransferScreenState();
}

class _CreateTransferScreenState extends ConsumerState<CreateTransferScreen> {
  final _gridKey = GlobalKey<ProductEntryGridState>();
  final _documentOriginController = TextEditingController();
  List<TransferLineDraft> _lines = [];
  bool _showProcessPanel = false;
  List<CompanyProcessConfig>? _processConfigs;
  String? _primaryOriginKey;

  TransfersRepository get _repo => ref.read(transfersRepositoryProvider);

  ActiveSession? get _active => ref.read(activeSessionProvider);

  @override
  void dispose() {
    _documentOriginController.dispose();
    super.dispose();
  }

  String? get _documentOrigin {
    final t = _documentOriginController.text.trim();
    return t.isEmpty ? null : t;
  }

  Map<int, List<TransferLineDraft>> _groupByCompany(List<TransferLineDraft> lines) {
    final map = <int, List<TransferLineDraft>>{};
    for (final line in lines) {
      final cid = line.companyId;
      if (cid == null) continue;
      map.putIfAbsent(cid, () => []).add(line);
    }
    return map;
  }

  void _openProcessPanel() {
    if (_primaryOriginKey == null || _primaryOriginKey!.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Seleccione la ubicacion de origen primaria',
        isError: true,
      );
      return;
    }

    if (_gridKey.currentState?.hasBlockingStockIssues == true) {
      AppSnackbar.show(
        context,
        message:
            'Hay productos sin stock suficiente en la ubicacion de origen',
        isError: true,
      );
      return;
    }

    final valid = _lines.where((l) => l.companyId != null).toList();
    if (valid.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Ingrese codigos validos con empresa identificada',
        isError: true,
      );
      return;
    }

    final grouped = _groupByCompany(valid);
    final configs = grouped.entries
        .map(
          (e) => CompanyProcessConfig(
            companyId: e.key,
            companyName: e.value.first.companyName ?? 'Empresa ${e.key}',
            lines: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.companyName.compareTo(b.companyName));

    for (final c in configs) {
      ref.invalidate(internalLocationsProvider(c.companyId));
      ref.invalidate(internalPickingTypesProvider(c.companyId));
    }

    setState(() {
      _showProcessPanel = true;
      _processConfigs = configs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);
    final originKeysAsync = ref.watch(primaryOriginLocationKeysProvider);
    final active = _active;

    return companiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: AppErrorBanner(
          message: e is AppException ? e.message : e.toString(),
        ),
      ),
      data: (companies) {
        if (active == null) {
          return const Center(child: Text('Sesion no disponible'));
        }

        final session = (
          baseUrl: active.session.baseUrl,
          database: active.session.database,
          uid: active.session.uid,
          password: active.password,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, 8, AppLayout.pagePadding(context).right, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_showProcessPanel) {
                        setState(() => _showProcessPanel = false);
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      _showProcessPanel
                          ? 'Procesar por empresa'
                          : 'Nueva transferencia — captura rapida',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppLayout.pagePadding(context),
                child: _showProcessPanel && _processConfigs != null
                    ? CompanyProcessPanel(
                        configs: _processConfigs!,
                        primaryOriginKey: _primaryOriginKey!,
                        documentOrigin: _documentOrigin,
                        onBack: () => setState(() => _showProcessPanel = false),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          originKeysAsync.when(
                            loading: () => Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            error: (e, _) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: AppErrorBanner(
                                  message: e is AppException
                                      ? e.message
                                      : e.toString(),
                                ),
                              ),
                            ),
                            data: (keys) {
                              final stackOriginAndBulk =
                                  AppLayout.isCompactWidth(context);
                              final originCard = Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'BODEGA DE ORIGEN',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Autocomplete<String>(
                                        initialValue: _primaryOriginKey == null
                                            ? null
                                            : TextEditingValue(
                                                text: _primaryOriginKey!,
                                              ),
                                        optionsBuilder: (text) {
                                          final q =
                                              text.text.trim().toLowerCase();
                                          if (q.isEmpty) return keys;
                                          return keys.where(
                                            (k) => k.toLowerCase().contains(q),
                                          );
                                        },
                                        onSelected: (v) {
                                          setState(
                                            () => _primaryOriginKey = v,
                                          );
                                        },
                                        fieldViewBuilder: (
                                          context,
                                          controller,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          if (_primaryOriginKey != null &&
                                              controller.text.isEmpty) {
                                            controller.text =
                                                _primaryOriginKey!;
                                          }
                                          return TextFormField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Ej. Casa de la moneda',
                                              prefixIcon: Icon(
                                                Icons.pin_drop_outlined,
                                              ),
                                              isDense: true,
                                            ),
                                            onChanged: (v) {
                                              final trimmed = v.trim();
                                              setState(() {
                                                _primaryOriginKey =
                                                    trimmed.isEmpty
                                                        ? null
                                                        : trimmed;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              final bulkCard = BulkUploadSection(
                                gridKey: _gridKey,
                                onImportFinished: () {
                                  setState(() {
                                    _lines = _gridKey
                                            .currentState
                                            ?.validatedLinesSnapshot ??
                                        _lines;
                                  });
                                },
                              );
                              if (stackOriginAndBulk) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    originCard,
                                    const SizedBox(height: 12),
                                    bulkCard,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: originCard),
                                  const SizedBox(width: 12),
                                  Expanded(child: bulkCard),
                                ],
                              );
                            },
                          ),
                          SizedBox(
                            height: AppLayout.isCompactHeight(context) ? 10 : 16,
                          ),
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: ProductEntryGrid(
                              key: _gridKey,
                              repo: _repo,
                              session: session,
                              fallbackCompanies: companies,
                              primaryOriginKey: _primaryOriginKey,
                              documentOriginController:
                                  _documentOriginController,
                              onLinesChanged: (lines) {
                                setState(() => _lines = lines);
                              },
                            ),
                          ),
                          SizedBox(
                            height: AppLayout.isCompactHeight(context) ? 12 : 20,
                          ),
                          FilledButton.icon(
                            onPressed: _lines.isEmpty ||
                                    _primaryOriginKey == null ||
                                    _primaryOriginKey!.isEmpty
                                ? null
                                : _openProcessPanel,
                            icon: const Icon(Icons.play_circle_outline),
                            label: Text(
                              _lines.isEmpty
                                  ? 'Ingrese productos en la tabla'
                                  : 'Procesar movimientos — '
                                      '${_groupByCompany(_lines).length} empresa(s)',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
