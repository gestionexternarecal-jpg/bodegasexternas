import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _dbController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _tryRestoreSession();
  }

  Future<void> _loadPrefs() async {
    final repo = await ref.read(authRepositoryProvider.future);
    final prefs = repo.savedPrefs;
    if (prefs.url != null) _urlController.text = prefs.url!;
    if (prefs.db != null) _dbController.text = prefs.db!;
    if (prefs.login != null) _userController.text = prefs.login!;
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

  Future<void> _submit({bool testOnly = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = await ref.read(authRepositoryProvider.future);

    if (testOnly) {
      final result = await repo.testConnection(
        baseUrl: _urlController.text,
        database: _dbController.text,
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
      baseUrl: _urlController.text,
      database: _dbController.text,
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
    _urlController.dispose();
    _dbController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transferencias internas · Odoo',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL del servidor',
                        hintText: 'https://mi-empresa.odoo.com',
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dbController,
                      decoration: const InputDecoration(
                        labelText: 'Base de datos',
                        prefixIcon: Icon(Icons.storage_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
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
                      onPressed: _loading ? null : () => _submit(),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Iniciar sesion'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loading ? null : () => _submit(testOnly: true),
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
