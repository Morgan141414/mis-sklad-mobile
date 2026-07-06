import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../data/auth_repository.dart';

final _authRepo = Provider((_) => AuthRepository());

final _loginStateProvider =
    StateNotifierProvider<_LoginNotifier, _LoginState>(
  (ref) => _LoginNotifier(ref.read(_authRepo)),
);

class _LoginState {
  final bool loading;
  final String? error;
  const _LoginState({this.loading = false, this.error});
  _LoginState copyWith({bool? loading, String? error}) =>
      _LoginState(loading: loading ?? this.loading, error: error);
}

class _LoginNotifier extends StateNotifier<_LoginState> {
  final AuthRepository _repo;
  _LoginNotifier(this._repo) : super(const _LoginState());

  Future<void> login(
    String email,
    String password,
    String orgId,
    VoidCallback onSuccess,
  ) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.login(email: email, password: password, orgId: orgId);
      onSuccess();
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.statusCode == 401
            ? 'Неверный email или пароль'
            : 'Ошибка сервера: ${e.message}',
      );
    } catch (_) {
      state = state.copyWith(
          loading: false, error: 'Нет соединения с сервером');
    }
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _orgId = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _orgId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_loginStateProvider);
    final notifier = ref.read(_loginStateProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Logo / brand
                  Icon(Icons.warehouse_rounded,
                      size: 64, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text('Склад МИС',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Вход в систему',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 36),

                  // Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        v != null && v.contains('@') ? null : 'Введите email',
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        v != null && v.length >= 4 ? null : 'Введите пароль',
                  ),
                  const SizedBox(height: 16),

                  // Org ID (UUID компании в МИС)
                  TextFormField(
                    controller: _orgId,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'ID клиники (UUID)',
                      prefixIcon: Icon(Icons.business_outlined),
                      hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                    ),
                    validator: (v) =>
                        v != null && v.length > 10 ? null : 'Введите ID клиники',
                    onFieldSubmitted: (_) => _submit(notifier),
                  ),
                  const SizedBox(height: 28),

                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),

                  FilledButton(
                    onPressed:
                        state.loading ? null : () => _submit(notifier),
                    style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16)),
                    child: state.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text('Войти',
                            style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(_LoginNotifier notifier) {
    if (!_formKey.currentState!.validate()) return;
    notifier.login(
      _email.text.trim(),
      _password.text,
      _orgId.text.trim(),
      () => context.go('/stock'),
    );
  }
}
