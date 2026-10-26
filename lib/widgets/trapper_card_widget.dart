import 'package:flutter/material.dart';

import '../core/card_art.dart';
import '../core/game_meta.dart';
import '../core/theme.dart';
import '../models/trapper_card.dart';

/// Carta de RPG de um trapper com a arte completa (coleção, time e recompensas).
/// Use dentro de um espaço com proporção ~2:3.
class TrapperCardWidget extends StatelessWidget {
  const TrapperCardWidget({
    super.key,
    required this.card,
    this.owned = true,
    this.selected = false,
    this.compact = false,
    this.lockedHint,
    this.onTap,
  });

  final TrapperCard card;
  final bool owned;
  final bool selected;
  final bool compact;
  final String? lockedHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final element = GameMeta.element(card.element);
    final rarity = GameMeta.rarity(card.rarity);
    final borderColor = selected ? AppColors.accent : (owned ? rarity.color : Colors.grey.shade800);
    final radius = BorderRadius.circular(compact ? 12 : 16);

    Widget art = Image.asset(
      card.imageAsset,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      cacheWidth: 600,
      errorBuilder: (_, _, _) => Container(
        color: element.color.withValues(alpha: 0.3),
        alignment: Alignment.center,
        child: Text(card.monogram, style: AppTheme.display(32)),
      ),
    );
    if (!owned) art = ColorFiltered(colorFilter: CardArt.grayscale, child: art);

    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: selected ? 0.96 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor, width: selected ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: (selected ? AppColors.accent : rarity.color)
                      .withValues(alpha: owned ? (selected ? 0.6 : 0.3) : 0),
                  blurRadius: selected ? 16 : 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  art,
                  // Escurece a base para dar leitura aos atributos.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.45, 1],
                        colors: [Colors.transparent, Color(0xF2000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 6,
                    child: Row(
                      children: [
                        _Pill(text: rarity.label, color: owned ? rarity.color : Colors.grey),
                        const Spacer(),
                        CircleAvatar(
                          radius: compact ? 10 : 12,
                          backgroundColor: Colors.black87,
                          child: Icon(element.icon,
                              size: compact ? 12 : 14, color: owned ? element.color : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: compact ? 6 : 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.display(compact ? 11 : 15),
                        ),
                        if (!compact)
                          Text(
                            card.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, letterSpacing: 1.5, color: AppColors.textMuted),
                          ),
                        SizedBox(height: compact ? 3 : 6),
                        if (owned)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _Stat(icon: Icons.flash_on, value: card.attack, color: const Color(0xFFFF6B6B), small: compact),
                              _Stat(icon: Icons.shield, value: card.defense, color: const Color(0xFF5BC0EB), small: compact),
                              _Stat(icon: Icons.favorite, value: card.hp, color: AppColors.accent, small: compact),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (!owned)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: compact ? 26 : 36, color: Colors.white70),
                          const SizedBox(height: 8),
                          Text(card.name, style: AppTheme.display(compact ? 11 : 14)),
                          const SizedBox(height: 4),
                          Text(
                            lockedHint ?? 'Bloqueada',
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: compact ? 9 : 11, color: AppColors.textMuted, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  if (selected)
                    const Positioned(
                      top: 30,
                      right: 6,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.accent,
                        child: Icon(Icons.check, size: 16, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.color, required this.small});
  final IconData icon;
  final int value;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: small ? 11 : 13, color: color),
        const SizedBox(width: 2),
        Text('$value', style: TextStyle(fontSize: small ? 10 : 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
