import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Logotipo oficial do Trap RPG.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120, this.showSubtitle = true});
  final double size;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'lib/assets/logo.webp',
          width: size,
          height: size,
          cacheWidth: 600,
          semanticLabel: 'Trap RPG',
          errorBuilder: (_, _, _) => Text('TRAP RPG', style: AppTheme.display(size * 0.22)),
        ),
        if (showSubtitle)
          Text(
            'DUELO DE CARTAS',
            style: TextStyle(
              fontSize: (size * 0.08).clamp(10, 16),
              letterSpacing: 4,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
