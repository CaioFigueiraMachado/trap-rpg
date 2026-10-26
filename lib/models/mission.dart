enum MissionStatus {
  available('Disponível'),
  inProgress('Em andamento'),
  completed('Concluída');

  const MissionStatus(this.label);
  final String label;

  static MissionStatus fromDb(String? value) => switch (value) {
        'in_progress' => MissionStatus.inProgress,
        'completed' => MissionStatus.completed,
        _ => MissionStatus.available,
      };
}

/// Missão/batalha (tabela `missions`) + status do jogador logado (`user_missions`).
class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.guidance,
    required this.category,
    required this.difficulty,
    required this.points,
    required this.enemyCards,
    required this.enemyLevel,
    required this.rewardCardId,
    required this.isFeatured,
    this.status = MissionStatus.available,
  });

  final int id;
  final String title;
  final String description;
  final String guidance;
  final String category;
  final String difficulty;
  final int points;
  final List<String> enemyCards;
  final int enemyLevel;
  final String? rewardCardId;
  final bool isFeatured;
  final MissionStatus status;

  Mission withStatus(MissionStatus newStatus) => Mission(
        id: id,
        title: title,
        description: description,
        guidance: guidance,
        category: category,
        difficulty: difficulty,
        points: points,
        enemyCards: enemyCards,
        enemyLevel: enemyLevel,
        rewardCardId: rewardCardId,
        isFeatured: isFeatured,
        status: newStatus,
      );

  factory Mission.fromMap(Map<String, dynamic> map) => Mission(
        id: map['id'] as int,
        title: map['title'] as String,
        description: map['description'] as String,
        guidance: map['guidance'] as String,
        category: map['category'] as String,
        difficulty: map['difficulty'] as String,
        points: map['points'] as int,
        enemyCards: List<String>.from(map['enemy_cards'] as List),
        enemyLevel: map['enemy_level'] as int,
        rewardCardId: map['reward_card_id'] as String?,
        isFeatured: (map['is_featured'] as bool?) ?? false,
      );
}

/// Resposta da função `complete_mission` do banco.
class MissionResult {
  const MissionResult({
    required this.alreadyCompleted,
    required this.pointsAwarded,
    required this.newAchievements,
    required this.rewardCardId,
  });

  final bool alreadyCompleted;
  final int pointsAwarded;
  final List<Map<String, dynamic>> newAchievements;
  final String? rewardCardId;

  factory MissionResult.fromMap(Map<String, dynamic> map) => MissionResult(
        alreadyCompleted: (map['already_completed'] as bool?) ?? false,
        pointsAwarded: (map['points_awarded'] as int?) ?? 0,
        newAchievements: [
          for (final a in (map['new_achievements'] as List?) ?? const [])
            Map<String, dynamic>.from(a as Map),
        ],
        rewardCardId: map['reward_card'] as String?,
      );
}

/// Linha do histórico de missões concluídas (perfil).
class MissionHistoryEntry {
  const MissionHistoryEntry({
    required this.title,
    required this.category,
    required this.points,
    required this.completedAt,
  });

  final String title;
  final String category;
  final int points;
  final DateTime completedAt;
}
