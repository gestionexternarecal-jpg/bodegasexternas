import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _loadingConnection = true;
  String? _baseUrl;
  String? _database;

  @override
  void initState() {
    super.initState();
    _loadConnection();
    _tryRestoreSession();
  }

  Future<void> _loadConnection() async {
    final repo = await ref.read(authRepositoryProvider.future);
    final prefs = await repo.loadSavedPrefs();
    if (!mounted) return;
    setState(() {
      _baseUrl = prefs.url;
      _database = prefs.db;
      if (prefs.login != null) _userController.text = prefs.login!;
      _loadingConnection = false;
    });
  }

  Future<void> _tryRestoreSession() async {
    final repo = await ref.read(authRepositoryProvider.future);
    final restored = await repo.restoreSession();
    if (!mounted) return;
    switch (restored) {
      case Success(:final value):
        await ref
            .read(activeSessionProvider.notifier)
            .setSession(value.session, value.password);
        if (mounted) context.go('/');
      case Failure():
        break;
    }
  }

  bool get _hasServerConfig {
    final url = _baseUrl?.trim();
    final db = _database?.trim();
    return url != null && url.isNotEmpty && db != null && db.isNotEmpty;
  }

  Future<void> _submit({bool testOnly = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasServerConfig) {
      _showSnack(
        'Servidor Odoo no configurado. Contacte al administrador.',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);
    final repo = await ref.read(authRepositoryProvider.future);
    final baseUrl = _baseUrl!.trim();
    final database = _database!.trim();

    if (testOnly) {
      final result = await repo.testConnection(
        baseUrl: baseUrl,
        database: database,
        username: _userController.text,
        password: _passController.text,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(
        result is Success
            ? 'Conexion exitosa con Odoo'
            : (result as Failure).error.message,
        isError: result is Failure,
      );
      return;
    }

    final result = await repo.login(
      baseUrl: baseUrl,
      database: database,
      username: _userController.text,
      password: _passController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success(:final value):
        await ref
            .read(activeSessionProvider.notifier)
            .setSession(value, _passController.text);
        if (mounted) context.go('/');
      case Failure(:final error):
        _showSnack(error.message, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    AppSnackbar.show(context, message: msg, isError: isError);
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_loading && !_loadingConnection && _hasServerConfig;
    final compact = AppLayout.isCompactHeight(context);
    final logoSize = compact ? 120.0 : 160.0;
    final cardPadding = compact ? 20.0 : 28.0;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: EdgeInsets.all(compact ? 16 : 20),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: AppLogo(size: logoSize)),
                      SizedBox(height: compact ? 12 : 16),
                      Text(
                        'Transferencias internas · Odoo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_loadingConnection) ...[
                        const SizedBox(height: 24),
                        const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ] else if (!_hasServerConfig) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Servidor no configurado. Compile o ejecute la app con '
                          '--dart-define=ODOO_BASE_URL y ODOO_DATABASE '
                          '(ver README).',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _userController,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: canSubmit ? () => _submit() : null,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Iniciar sesion'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: canSubmit
                            ? () => _submit(testOnly: true)
                            : null,
                        child: const Text('Probar conexion'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
