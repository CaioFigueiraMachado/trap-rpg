import 'package:flutter/material.dart';

import '../core/game_meta.dart';
import '../core/theme.dart';

/// Painel de pontuação, nível e progresso do jogador.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.points,
    required this.missionsCompleted,
    required this.totalMissions,
    required this.achievementsUnlocked,
    required this.totalAchievements,
  });

  final int points;
  final int missionsCompleted;
  final int totalMissions;
  final int achievementsUnlocked;
  final int totalAchievements;

  @override
  Widget build(BuildContext context) {
    final level = PlayerLevel.of(points);
    final missionRatio = totalMissions == 0 ? 0.0 : missionsCompleted / totalMissions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFFEC4899)],
        ),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.25),
                  border: Border.all(color: AppColors.gold, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('NV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    Text('$level', style: AppTheme.display(20, color: AppColors.gold)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(PlayerLevel.title(level),
                        style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    Text('$points pts', style: AppTheme.display(26)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: PlayerLevel.progress(points),
              minHeight: 10,
              backgroundColor: Colors.black26,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level >= PlayerLevel.maxLevel
                ? 'Nível máximo alcançado!'
                : 'Faltam ${PlayerLevel.pointsToNext(points)} pts para o nível ${level + 1}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                icon: Icons.flag_rounded,
                label: 'Missões',
                value: '$missionsCompleted/$totalMissions',
                progress: missionRatio,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.emoji_events_rounded,
                label: 'Conquistas',
                value: '$achievementsUnlocked/$totalAchievements',
                progress: totalAchievements == 0 ? 0 : achievementsUnlocked / totalAchievements,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.white12,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
