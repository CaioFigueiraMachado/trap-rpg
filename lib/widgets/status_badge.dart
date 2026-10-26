import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/mission.dart';

/// Selo do status da missão: disponível / em andamento / concluída.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final MissionStatus status;

  static Color colorOf(MissionStatus status) => switch (status) {
        MissionStatus.available => AppColors.textMuted,
        MissionStatus.inProgress => const Color(0xFFFFD60A),
        MissionStatus.completed => AppColors.accent,
      };

  static IconData iconOf(MissionStatus status) => switch (status) {
        MissionStatus.available => Icons.lock_open_rounded,
        MissionStatus.inProgress => Icons.hourglass_top_rounded,
        MissionStatus.completed => Icons.check_circle_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return InfoChip(icon: iconOf(status), label: status.label, color: colorOf(status));
  }
}

/// Pequena etiqueta com ícone, reutilizada em várias telas.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
