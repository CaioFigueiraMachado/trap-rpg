import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/errors.dart';
import '../core/router.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loggedIn = await AuthService.signUp(
        nickname: _nickname.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      if (!loggedIn) {
        // Projeto com confirmação de e-mail ativada.
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirme seu e-mail'),
            content: const Text(
                'Enviamos um link de confirmação para o seu e-mail. Depois de confirmar, faça login.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        if (mounted) context.go(AppRoutes.login);
      }
      // Se entrou direto, o redirect do GoRouter leva para a Home.
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRIAR CONTA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: AuthLayout(
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Monte seu line-up', style: AppTheme.display(22)),
                    const SizedBox(height: 4),
                    const Text(
                      'Você começa com 3 cartas: Fabin, Leviano e Reid. Vença batalhas para recrutar o resto!',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nickname,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Apelido de MC',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.length < 2) return 'Mínimo de 2 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      validator: (v) =>
                          v != _password.text ? 'As senhas não conferem' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBox(message: _error!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('CADASTRAR'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : () => context.go(AppRoutes.login),
                      child: const Text('Já tenho conta. Fazer login'),
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
