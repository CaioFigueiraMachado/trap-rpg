import 'package:flutter/material.dart';

import '../core/game_meta.dart';
import '../core/theme.dart';
import '../models/mission.dart';
import '../models/trapper_card.dart';
import 'status_badge.dart';
import 'trapper_avatar.dart';

/// Cartão de apresentação de uma missão (Home).
class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    required this.enemies,
    this.onTap,
    this.featured = false,
  });

  final Mission mission;
  final List<TrapperCard> enemies;
  final VoidCallback? onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final category = GameMeta.category(mission.category);
    final difficulty = GameMeta.difficulty(mission.difficulty);
    final completed = mission.status == MissionStatus.completed;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: featured ? AppColors.gold : category.color.withValues(alpha: 0.35),
          width: featured ? 2 : 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            category.color.withValues(alpha: featured ? 0.35 : 0.14),
            AppColors.surface,
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Opacity(
            opacity: completed && !featured ? 0.75 : 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (featured) ...[
                    Row(children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 4),
                      Text('MISSÃO EM DESTAQUE',
                          style: AppTheme.display(11, color: AppColors.gold)),
                    ]),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(category.icon, color: category.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mission.title,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(category.label,
                                    style: TextStyle(
                                        fontSize: 12, color: category.color)),
                                InfoChip(
                                  icon: difficulty.icon,
                                  label: difficulty.label,
                                  color: difficulty.color,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: mission.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mission.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('VS ',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: AppColors.danger)),
                      for (final enemy in enemies)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: TrapperAvatar(card: enemy, size: 30, showElement: false),
                        ),
                      const Spacer(),
                      InfoChip(
                        icon: Icons.bolt,
                        label: '+${mission.points} pts',
                        color: AppColors.accent,
                      ),
                    ],
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
