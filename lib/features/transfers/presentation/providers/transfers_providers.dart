import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/stock_picking.dart';
import '../../domain/entities/transfer_catalog.dart';
import '../../domain/primary_origin_resolver.dart';

final companiesProvider = FutureProvider<List<ResCompany>>((ref) async {
  final active = ref.watch(activeSessionProvider);
  if (active == null) throw StateError('Sin sesion');

  final repo = ref.watch(transfersRepositoryProvider);
  final result = await repo.fetchCompanies(
    baseUrl: active.session.baseUrl,
    database: active.session.database,
    uid: active.session.uid,
    password: active.password,
  );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw error,
  };
});

final transferStatsProvider = FutureProvider<TransferStats>((ref) async {
  final active = ref.watch(activeSessionProvider);
  if (active == null) throw StateError('Sin sesion');
  final filter = ref.watch(transfersFilterProvider);

  final repo = ref.watch(transfersRepositoryProvider);
  final result = await repo.fetchStats(
    baseUrl: active.session.baseUrl,
    database: active.session.database,
    uid: active.session.uid,
    password: active.password,
    companyId: filter.companyId,
  );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw error,
  };
});

class TransfersFilter {
  const TransfersFilter({this.state, this.search = '', this.companyId});
  final String? state;
  final String search;
  final int? companyId;
}

final transfersFilterProvider =
    StateProvider<TransfersFilter>((ref) => const TransfersFilter());

final transfersListProvider = FutureProvider<List<StockPicking>>((ref) async {
  final active = ref.watch(activeSessionProvider);
  if (active == null) return [];

  final filter = ref.watch(transfersFilterProvider);
  final repo = ref.watch(transfersRepositoryProvider);

  final result = await repo.fetchPickings(
    baseUrl: active.session.baseUrl,
    database: active.session.database,
    uid: active.session.uid,
    password: active.password,
    stateFilter: filter.state,
    searchQuery: filter.search.isEmpty ? null : filter.search,
    companyId: filter.companyId,
  );

  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw error,
  };
});

final transferDetailProvider =
    FutureProvider.family<StockPicking, int>((ref, id) async {
  final active = ref.watch(activeSessionProvider);
  if (active == null) throw StateError('Sin sesion');

  final repo = ref.watch(transfersRepositoryProvider);
  final result = await repo.fetchPickingById(
    baseUrl: active.session.baseUrl,
    database: active.session.database,
    uid: active.session.uid,
    password: active.password,
    pickingId: id,
  );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw error,
  };
});

final internalPickingTypesProvider =
    FutureProvider.family<List<InternalPickingType>, int?>((ref, companyId) async {
  final active = ref.watch(activeSessionProvider);
  if (active == null) throw StateError('Sin sesion');

  final repo = ref.watch(transfersRepositoryProvider);
  final result = await repo.fetchInternalPickingTypes(
    baseUrl: active.session.baseUrl,
    database: active.session.database,
    uid: active.session.uid,
    password: active.password,
    companyId: companyId,
  );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw error,
  };
});

/// Nombres de ubicacion interna para elegir el origen primario (todas las empresas).
final primaryOriginLocationKeysProvider = FutureProvider<List<String>>((ref) async {
  final locations = await ref.watch(internalLocationsProvider(null).future);
  return PrimaryOriginResolver.uniqueOriginKeys(locations);
});

final internalLocationsProvider =
    FutureProvider.family<List<StockLocation>, int?>((ref, companyId) async {
  final active = ref.watch(activeSessionProvider);
  if (active == null) throw StateError('Sin sesion');

  final repo = ref.watch(transfersRepositoryProvider);
  final result = await repo.fetchInternalLocations(
    baseUrl: active.session.baseUrl,
    database: active.session.database,
    uid: active.session.uid,
    password: active.password,
    companyId: companyId,
  );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw error,
  };
});

final transferLinesProvider =
    FutureProvider.family<List<StockMoveLine>, int>((ref, id) async {
  final active = ref.watch(activeSessionProvider);
  if (active == null) throw StateError('Sin sesion');

  final repo = ref.watch(transfersRepositoryProvider);
  final result = await repo.fetchMoveLines(
    baseUrl: active.session.baseUrl,
    database: active.session.database,
    uid: active.session.uid,
    password: active.password,
    pickingId: id,
  );
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw error,
  };
});
