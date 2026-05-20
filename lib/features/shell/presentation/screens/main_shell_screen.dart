import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/app_providers.dart';

int _railIndex(String path) {
  if (path == routeCreateTransfer ||
      path == '/transfer/new' ||
      path == '/transfers/create') {
    return 1;
  }
  return 0;
}

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final isWide = MediaQuery.sizeOf(context).width > 1100;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isWide,
            // Con extended=true, Flutter exige labelType none o null.
            labelType: isWide
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: _railIndex(GoRouterState.of(context).uri.path),
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                case 1:
                  context.go(routeCreateTransfer);
              }
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(Icons.swap_horiz),
                label: Text('Listado'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(Icons.add_box),
                label: Text('Nueva'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Tema',
                        onPressed: () {
                          final next = switch (themeMode) {
                            AppThemeMode.light => AppThemeMode.dark,
                            AppThemeMode.dark => AppThemeMode.system,
                            AppThemeMode.system => AppThemeMode.light,
                          };
                          ref.read(appThemeModeProvider.notifier).setMode(next);
                        },
                        icon: Icon(switch (themeMode) {
                          AppThemeMode.dark => Icons.dark_mode,
                          AppThemeMode.light => Icons.light_mode,
                          AppThemeMode.system => Icons.brightness_auto,
                        }),
                      ),
                      IconButton(
                        tooltip: 'Cerrar sesion',
                        onPressed: () async {
                          await ref.read(activeSessionProvider.notifier).clear();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Transferencias internas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        if (session != null)
                          Text(
                            '${session.session.login} · ${session.session.database}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
