import 'package:flutter/material.dart';

import 'theme.dart';

typedef MetaInfo = ({String label, IconData icon, Color color});

/// Textos, ícones e cores dos valores que vêm do banco
/// (elementos, raridades, categorias, dificuldades, conquistas).
class GameMeta {
  static const _fallback = (label: '?', icon: Icons.help_outline, color: AppColors.textMuted);

  static const elements = <String, MetaInfo>{
    'fogo': (label: 'Fogo', icon: Icons.local_fire_department, color: Color(0xFFFF6B35)),
    'gelo': (label: 'Gelo', icon: Icons.ac_unit, color: Color(0xFF5BC0EB)),
    'vento': (label: 'Vento', icon: Icons.air, color: Color(0xFF7BE0AD)),
    'terra': (label: 'Terra', icon: Icons.terrain, color: Color(0xFFB08968)),
    'tempestade': (label: 'Tempestade', icon: Icons.thunderstorm, color: Color(0xFFFFD60A)),
    'sombra': (label: 'Sombra', icon: Icons.dark_mode, color: Color(0xFF8B5CF6)),
    'luz': (label: 'Luz', icon: Icons.wb_sunny, color: Color(0xFFFFF3B0)),
    'cosmico': (label: 'Cósmico', icon: Icons.auto_awesome, color: Color(0xFFFF4FD8)),
  };

  static const rarities = <String, MetaInfo>{
    'comum': (label: 'Comum', icon: Icons.circle, color: Color(0xFF9CA3AF)),
    'rara': (label: 'Rara', icon: Icons.star_half, color: Color(0xFF3B82F6)),
    'epica': (label: 'Épica', icon: Icons.star, color: Color(0xFFA855F7)),
    'lendaria': (label: 'Lendária', icon: Icons.stars, color: AppColors.gold),
  };

  static const categories = <String, MetaInfo>{
    'treino': (label: 'Treino', icon: Icons.fitness_center, color: Color(0xFF22D3EE)),
    'batalha': (label: 'Batalha de Rima', icon: Icons.mic_external_on, color: AppColors.primary),
    'torneio': (label: 'Torneio', icon: Icons.emoji_events, color: Color(0xFFFB923C)),
    'chefe': (label: 'Chefe', icon: Icons.whatshot, color: AppColors.danger),
  };

  static const difficulties = <String, MetaInfo>{
    'facil': (label: 'Fácil', icon: Icons.signal_cellular_alt_1_bar, color: AppColors.accent),
    'medio': (label: 'Médio', icon: Icons.signal_cellular_alt_2_bar, color: Color(0xFFFFD60A)),
    'dificil': (label: 'Difícil', icon: Icons.signal_cellular_alt, color: Color(0xFFFB923C)),
    'lendario': (label: 'Lendário', icon: Icons.local_fire_department, color: AppColors.danger),
  };

  static const achievementIcons = <String, IconData>{
    'mic': Icons.mic,
    'album': Icons.album,
    'calendar': Icons.calendar_month,
    'swords': Icons.sports_kabaddi,
    'skull': Icons.whatshot,
    'gold': Icons.workspace_premium,
    'diamond': Icons.diamond,
    'cards': Icons.style,
    'crown': Icons.military_tech,
    'trophy': Icons.emoji_events,
  };

  static MetaInfo element(String key) => elements[key] ?? _fallback;
  static MetaInfo rarity(String key) => rarities[key] ?? _fallback;
  static MetaInfo category(String key) => categories[key] ?? _fallback;
  static MetaInfo difficulty(String key) => difficulties[key] ?? _fallback;
  static IconData achievementIcon(String key) => achievementIcons[key] ?? Icons.emoji_events;
}

/// Nível do jogador calculado a partir da pontuação.
class PlayerLevel {
  static const pointsPerLevel = 200;
  static const maxLevel = 20;

  static int of(int points) => (points ~/ pointsPerLevel + 1).clamp(1, maxLevel);

  static double progress(int points) =>
      of(points) >= maxLevel ? 1 : (points % pointsPerLevel) / pointsPerLevel;

  static int pointsToNext(int points) =>
      of(points) >= maxLevel ? 0 : pointsPerLevel - points % pointsPerLevel;

  static String title(int level) {
    if (level >= 15) return 'Lenda do Trap';
    if (level >= 10) return 'Headliner';
    if (level >= 6) return 'Hitmaker';
    if (level >= 3) return 'Promessa da Cena';
    return 'Novato do Corre';
  }
}
