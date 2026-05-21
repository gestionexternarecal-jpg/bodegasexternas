import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/shell/presentation/screens/main_shell_screen.dart';
import '../../features/transfers/presentation/screens/create_transfer_screen.dart';
import '../../features/transfers/presentation/screens/transfer_detail_screen.dart';
import '../../features/transfers/presentation/screens/transfers_list_screen.dart';
import '../../features/warehouse/presentation/screens/warehouse_bins_screen.dart';
import '../../features/warehouse/presentation/screens/warehouse_home_screen.dart';
import '../../features/warehouse/presentation/screens/warehouse_stock_screen.dart';
import '../providers/app_providers.dart';

/// Ruta para crear transferencia (un solo segmento; compatible con ShellRoute).
const String routeCreateTransfer = '/create-transfer';

/// Modulo Gestion Almacen (Odoo + Firebase).
const String routeWarehouse = '/warehouse';
const String routeWarehouseStock = '/warehouse/stock';
const String routeWarehouseBins = '/warehouse/bins';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(activeSessionProvider);

  return GoRouter(
    initialLocation: session == null ? '/login' : '/',
    refreshListenable: _RouterRefresh(ref),
    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
    redirect: (context, state) {
      final loggedIn = ref.read(activeSessionProvider) != null;
      final onLogin = state.matchedLocation == '/login';
      final path = state.uri.path;

      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/';
      if (path == '/transfer/new' || path == '/transfers/create') {
        return routeCreateTransfer;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TransfersListScreen(),
          ),
          GoRoute(
            path: routeCreateTransfer,
            builder: (context, state) => const CreateTransferScreen(),
          ),
          GoRoute(
            path: '/transfer/:id',
            builder: (context, state) {
              final raw = state.pathParameters['id']!;
              final id = int.tryParse(raw);
              if (id == null) {
                return const _InvalidTransferIdScreen();
              }
              return TransferDetailScreen(pickingId: id);
            },
          ),
          GoRoute(
            path: routeWarehouse,
            builder: (context, state) => const WarehouseHomeScreen(),
            routes: [
              GoRoute(
                path: 'stock',
                builder: (context, state) => const WarehouseStockScreen(),
              ),
              GoRoute(
                path: 'bins',
                builder: (context, state) => const WarehouseBinsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final message = error?.toString() ?? 'Ruta no encontrada';

    return Material(
      color: const Color(0xFF121212),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFB74D),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo abrir la pantalla',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Segoe UI',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Segoe UI',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Volver al listado'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvalidTransferIdScreen extends StatelessWidget {
  const _InvalidTransferIdScreen();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/');
    });
    return const Center(child: CircularProgressIndicator());
  }
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(activeSessionProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}
