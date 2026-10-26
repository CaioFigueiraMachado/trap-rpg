import 'package:flutter/material.dart';

import '../core/game_meta.dart';
import '../core/theme.dart';
import '../models/achievement.dart';

/// Medalha de conquista. Bloqueada fica cinza com cadeado e barra de progresso.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.progress,
    this.progressLabel,
  });

  final Achievement achievement;

  /// 0..1 — só aparece para conquistas ainda bloqueadas.
  final double? progress;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final icon = GameMeta.achievementIcon(achievement.icon);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked ? AppColors.gold.withValues(alpha: 0.7) : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: unlocked
                      ? const LinearGradient(
                          colors: [AppColors.gold, Color(0xFFFF8A00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: unlocked ? null : AppColors.surfaceHigh,
                  boxShadow: unlocked
                      ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 16)]
                      : null,
                ),
                child: Icon(icon, size: 32, color: unlocked ? Colors.black87 : Colors.white24),
              ),
              if (!unlocked)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.bg,
                    child: Icon(Icons.lock, size: 13, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: unlocked ? Colors.white : Colors.white60,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unlocked ? achievement.description : achievement.conditionLabel,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const Spacer(),
          if (unlocked)
            Text(
              'Desbloqueada em ${_date(achievement.unlockedAt!)}',
              style: const TextStyle(fontSize: 10, color: AppColors.gold),
            )
          else if (progress != null) ...[
            LinearProgressIndicator(
              value: progress!.clamp(0, 1),
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.white10,
              color: AppColors.primary,
            ),
            if (progressLabel != null) ...[
              const SizedBox(height: 4),
              Text(progressLabel!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ],
        ],
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
