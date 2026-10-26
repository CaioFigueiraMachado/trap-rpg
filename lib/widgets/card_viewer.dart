import 'package:flutter/material.dart';

import '../core/game_meta.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/trapper_card.dart';
import 'music_button.dart';

/// Abre a arte completa da carta com atributos, especial e música.
Future<void> showCardViewer(BuildContext context, TrapperCard card) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => _CardViewer(card: card),
  );
}

class _CardViewer extends StatelessWidget {
  const _CardViewer({required this.card});
  final TrapperCard card;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.isTablet(context);
    final size = MediaQuery.sizeOf(context);

    // Reserva o espaço da arte (2:3) enquanto a imagem em alta carrega.
    final poster = AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: AppColors.surfaceHigh,
          child: Image.asset(
            card.imageAsset,
            fit: BoxFit.contain,
            frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: child,
            ),
          ),
        ),
      ),
    );

    final info = _Info(card: card);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.all(wide ? 32 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 980, maxHeight: size.height * 0.92),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(flex: 5, child: poster),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: SingleChildScrollView(child: info)),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [poster, const SizedBox(height: 16), info],
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.card});
  final TrapperCard card;

  @override
  Widget build(BuildContext context) {
    final element = GameMeta.element(card.element);
    final rarity = GameMeta.rarity(card.rarity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.name, style: AppTheme.display(28)),
        Text('CLASSE: ${card.title.toUpperCase()}',
            style: const TextStyle(letterSpacing: 2, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Chip(
            avatar: Icon(element.icon, color: element.color, size: 18),
            label: Text(element.label),
          ),
          Chip(
            avatar: Icon(rarity.icon, color: rarity.color, size: 18),
            label: Text(rarity.label),
          ),
        ]),
        const SizedBox(height: 16),
        if (card.lore.isNotEmpty)
          Text(card.lore, style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4)),
        const SizedBox(height: 16),
        _StatBar(label: 'Ataque', value: card.attack, max: 40, color: const Color(0xFFFF6B6B)),
        _StatBar(label: 'Defesa', value: card.defense, max: 20, color: const Color(0xFF5BC0EB)),
        _StatBar(label: 'Vida', value: card.hp, max: 140, color: AppColors.accent),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ESPECIAL: ${card.specialName.toUpperCase()}',
                  style: AppTheme.display(12, color: AppColors.gold)),
              const SizedBox(height: 4),
              Text(card.specialDesc),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('MÚSICA', style: AppTheme.display(13)),
        const SizedBox(height: 8),
        MusicButtons(card: card),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value, required this.max, required this.color});
  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label, style: const TextStyle(color: AppColors.textMuted))),
          Expanded(
            child: LinearProgressIndicator(
              value: (value / max).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
              color: color,
              backgroundColor: Colors.white10,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text('$value',
                textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
