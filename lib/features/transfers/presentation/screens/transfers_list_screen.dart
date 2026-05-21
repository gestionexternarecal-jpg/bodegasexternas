import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/ecuador_datetime.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../shared/widgets/company_badge.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/state_chip.dart';
import '../providers/transfers_providers.dart';

class TransfersListScreen extends ConsumerStatefulWidget {
  const TransfersListScreen({super.key});

  @override
  ConsumerState<TransfersListScreen> createState() =>
      _TransfersListScreenState();
}

class _TransfersListScreenState extends ConsumerState<TransfersListScreen> {
  final _searchController = TextEditingController();
  String? _stateFilter;
  int? _companyFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(transfersFilterProvider.notifier).state = TransfersFilter(
      state: _stateFilter,
      search: _searchController.text,
      companyId: _companyFilter,
    );
    ref.invalidate(transfersListProvider);
    ref.invalidate(transferStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final statsAsync = ref.watch(transferStatsProvider);
    final listAsync = ref.watch(transfersListProvider);
    final companiesAsync = ref.watch(companiesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(routeCreateTransfer),
        icon: const Icon(Icons.add),
        label: const Text('Nueva transferencia'),
      ),
      body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statsAsync.when(
            data: (stats) => LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  StatCard(
                    title: 'Pendientes',
                    value: stats.pending,
                    icon: Icons.schedule,
                    color: semantic.pending,
                    onTap: () {
                      setState(() => _stateFilter = 'draft');
                      _applyFilters();
                    },
                  ),
                  StatCard(
                    title: 'En proceso',
                    value: stats.inProgress,
                    icon: Icons.local_shipping_outlined,
                    color: semantic.info,
                    onTap: () {
                      setState(() => _stateFilter = 'assigned');
                      _applyFilters();
                    },
                  ),
                  StatCard(
                    title: 'Completadas',
                    value: stats.done,
                    icon: Icons.check_circle_outline,
                    color: semantic.success,
                    onTap: () {
                      setState(() => _stateFilter = 'done');
                      _applyFilters();
                    },
                  ),
                  StatCard(
                    title: 'Canceladas',
                    value: stats.cancelled,
                    icon: Icons.cancel_outlined,
                    color: semantic.danger,
                    onTap: () {
                      setState(() => _stateFilter = 'cancel');
                      _applyFilters();
                    },
                  ),
                ];

                if (constraints.maxWidth > 900) {
                  return SizedBox(
                    height: 88,
                    child: Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: cards[i]),
                        ],
                      ],
                    ),
                  );
                }

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.1,
                  children: cards,
                );
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => AppErrorBanner(
              message: e is AppException ? e.message : e.toString(),
            ),
          ),
          const SizedBox(height: 16),
          companiesAsync.when(
            data: (companies) {
              if (companies.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int?>(
                  initialValue: _companyFilter,
                  decoration: const InputDecoration(
                    labelText: 'Empresa / Compania',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas las empresas'),
                    ),
                    ...companies.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _companyFilter = v);
                    _applyFilters();
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar documento, origen...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _stateFilter,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'draft', child: Text('Borrador')),
                    DropdownMenuItem(value: 'waiting', child: Text('En espera')),
                    DropdownMenuItem(
                      value: 'confirmed',
                      child: Text('Confirmado'),
                    ),
                    DropdownMenuItem(value: 'assigned', child: Text('Listo')),
                    DropdownMenuItem(value: 'done', child: Text('Hecho')),
                    DropdownMenuItem(value: 'cancel', child: Text('Cancelado')),
                  ],
                  onChanged: (v) {
                    setState(() => _stateFilter = v);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () {
                  ref.invalidate(transferStatsProvider);
                  ref.invalidate(transfersListProvider);
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: listAsync.when(
                data: (pickings) {
                  if (pickings.isEmpty) {
                    return const Center(
                      child: Text('No hay transferencias internas'),
                    );
                  }
                  return DataTable2(
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    minWidth: 1100,
                    columns: const [
                      DataColumn2(
                        label: Text('Empresa'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(label: Text('Documento'), size: ColumnSize.M),
                      DataColumn2(label: Text('Estado'), size: ColumnSize.S),
                      DataColumn2(label: Text('Origen'), size: ColumnSize.L),
                      DataColumn2(label: Text('Destino'), size: ColumnSize.L),
                      DataColumn2(label: Text('Fecha'), size: ColumnSize.M),
                      DataColumn2(label: Text('Usuario'), size: ColumnSize.M),
                    ],
                    rows: pickings.map((p) {
                      return DataRow(
                        onSelectChanged: (_) =>
                            context.go('/transfer/${p.id}'),
                        cells: [
                          DataCell(
                            p.companyName != null && p.companyName!.isNotEmpty
                                ? CompanyBadge(
                                    companyName: p.companyName!,
                                    compact: true,
                                  )
                                : const Text(
                                    'Sin empresa',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                          ),
                          DataCell(Text(p.name)),
                          DataCell(PickingStateChip(state: p.state)),
                          DataCell(Text(p.locationName ?? '-')),
                          DataCell(Text(p.locationDestName ?? '-')),
                          DataCell(
                            Text(
                              EcuadorDateTime.formatDateTime(p.scheduledDate),
                            ),
                          ),
                          DataCell(Text(p.userName ?? '-')),
                        ],
                      );
                    }).toList(),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: AppErrorBanner(
                    message: e is AppException ? e.message : e.toString(),
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
}

