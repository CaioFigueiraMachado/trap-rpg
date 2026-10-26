import 'dart:math';

import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import 'app_logo.dart';

/// Layout das telas de login/cadastro.
/// Computador: painel com logo e cartas à esquerda + formulário à direita.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Breakpoints.isDesktop(context)) return child;
    return Row(
      children: [
        const Expanded(flex: 6, child: _AuthHero()),
        Expanded(flex: 5, child: child),
      ],
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    Widget poster(String id, double angle, double dx) => Transform.translate(
          offset: Offset(dx, angle.abs() * 60),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: 190,
              height: 285,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 24)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset('lib/assets/cards/$id.webp', fit: BoxFit.cover, cacheWidth: 400),
              ),
            ),
          ),
        );

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.0,
          colors: [Color(0xFF2E1065), AppColors.bg],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 240),
              const SizedBox(height: 24),
              SizedBox(
                height: 320,
                width: 520,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    poster('teto', -pi / 12, -150),
                    poster('alee', pi / 12, 150),
                    poster('matue', 0, 0),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Monte seu line-up. Vença batalhas. Domine o ranking.',
                  textAlign: TextAlign.center,
                  style: AppTheme.display(16, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Digite seu e-mail';
  if (!_emailRegex.hasMatch(v)) return 'E-mail inválido';
  return null;
}

/// Caixa vermelha com a mensagem de erro de autenticação.
class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
