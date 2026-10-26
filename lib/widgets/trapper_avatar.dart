import 'package:flutter/material.dart';

import '../core/card_art.dart';
import '../core/game_meta.dart';
import '../core/theme.dart';
import '../models/trapper_card.dart';

/// Avatar circular de um trapper: rosto recortado da arte da carta,
/// borda na cor da raridade e selo do elemento.
class TrapperAvatar extends StatelessWidget {
  const TrapperAvatar({
    super.key,
    required this.card,
    this.size = 48,
    this.locked = false,
    this.showElement = true,
  });

  final TrapperCard card;
  final double size;
  final bool locked;
  final bool showElement;

  @override
  Widget build(BuildContext context) {
    final element = GameMeta.element(card.element);
    final rarity = GameMeta.rarity(card.rarity);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceHigh,
              border: Border.all(
                color: locked ? Colors.grey.shade600 : rarity.color,
                width: (size * 0.05).clamp(1.5, 4),
              ),
              boxShadow: locked
                  ? null
                  : [BoxShadow(color: element.color.withValues(alpha: 0.45), blurRadius: size * 0.25)],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Face(card: card, size: size, grayscale: locked),
                  if (locked)
                    Container(
                      color: Colors.black54,
                      child: Icon(Icons.lock, size: size * 0.38, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),
          if (showElement && !locked && size >= 36)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(size * 0.06),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: element.color, width: 1.5),
                ),
                child: Icon(element.icon, size: size * 0.24, color: element.color),
              ),
            ),
        ],
      ),
    );
  }
}

/// Recorta a arte da carta centralizando o rosto do trapper.
class _Face extends StatelessWidget {
  const _Face({required this.card, required this.size, required this.grayscale});
  final TrapperCard card;
  final double size;
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    final art = CardArt.of(card.id);
    if (art == null) {
      return Center(child: Text(card.monogram, style: AppTheme.display(size * 0.3)));
    }

    final w = size * art.zoom;
    final h = w * art.aspect;
    final left = (size / 2 - art.focus.dx * w).clamp(size - w, 0.0);
    final top = (size / 2 - art.focus.dy * h).clamp(size - h, 0.0);

    Widget image = Image.asset(
      card.imageAsset,
      width: w,
      height: h,
      fit: BoxFit.cover,
      cacheWidth: (w * MediaQuery.devicePixelRatioOf(context)).round().clamp(64, 1024),
      errorBuilder: (_, _, _) =>
          Center(child: Text(card.monogram, style: AppTheme.display(size * 0.3))),
    );
    if (grayscale) image = ColorFiltered(colorFilter: CardArt.grayscale, child: image);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [Positioned(left: left, top: top, width: w, height: h, child: image)],
    );
  }
}
