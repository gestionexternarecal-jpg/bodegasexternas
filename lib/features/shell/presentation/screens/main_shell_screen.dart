import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/update_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../widgets/app_about_dialog.dart';
import '../widgets/app_update_dialog.dart';
import '../widgets/shell_header.dart';
import '../widgets/shell_rail.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdatesOnce());
  }

  Future<void> _checkForUpdatesOnce() async {
    if (_updateCheckStarted || !mounted) return;
    _updateCheckStarted = true;

    final manifest =
        await ref.read(updateCheckServiceProvider).checkForUpdate();
    if (!mounted || manifest == null) return;
    await showAppUpdateDialog(context, manifest);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final versionAsync = ref.watch(appVersionLabelProvider);
    final isWide = MediaQuery.sizeOf(context).width > 1100;
    final path = GoRouterState.of(context).uri.path;
    final sessionLine = session != null
        ? '${session.session.login} · ${session.session.database}'
        : null;

    final versionLabel = versionAsync.when(
      data: (v) => v,
      loading: () => '...',
      error: (_, _) => '',
    );

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isWide,
            labelType: isWide
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: shellRailIndexForPath(path),
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                case 1:
                  context.go(routeCreateTransfer);
                case 2:
                  context.go(routeWarehouse);
              }
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  AppLogo(
                    size: isWide ? 56 : 40,
                    borderRadius: 8,
                  ),
                  if (isWide) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
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
              NavigationRailDestination(
                icon: Icon(Icons.warehouse_outlined),
                selectedIcon: Icon(Icons.warehouse),
                label: Text('Almacen'),
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
                      if (isWide && versionLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            versionLabel,
                            style: Theme.of(context).textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Acerca de',
                        onPressed: () => showAppAboutDialog(context, ref),
                        icon: const Icon(Icons.info_outline),
                      ),
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
                ShellHeader(
                  title: shellTitleForPath(path),
                  sessionLine: sessionLine,
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
