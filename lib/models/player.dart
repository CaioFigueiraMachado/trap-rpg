/// Perfil do jogador (tabela `profiles`).
class PlayerProfile {
  const PlayerProfile({required this.id, required this.nickname, required this.points});

  final String id;
  final String nickname;
  final int points;

  factory PlayerProfile.fromMap(Map<String, dynamic> map) => PlayerProfile(
        id: map['id'] as String,
        nickname: map['nickname'] as String,
        points: map['points'] as int,
      );
}

/// Números consolidados do jogador (Home, Perfil e progresso das conquistas).
class PlayerStats {
  const PlayerStats({
    required this.profile,
    required this.missionsCompleted,
    required this.totalMissions,
    required this.achievementsUnlocked,
    required this.totalAchievements,
    required this.cardsOwned,
    required this.totalCards,
    required this.distinctDays,
    required this.completedByCategory,
  });

  final PlayerProfile profile;
  final int missionsCompleted;
  final int totalMissions;
  final int achievementsUnlocked;
  final int totalAchievements;
  final int cardsOwned;
  final int totalCards;
  final int distinctDays;
  final Map<String, int> completedByCategory;
}

/// Linha do ranking (função `get_ranking`).
class RankingEntry {
  const RankingEntry({
    required this.position,
    required this.playerId,
    required this.nickname,
    required this.points,
    required this.missionsCompleted,
    required this.isMe,
  });

  final int position;
  final String playerId;
  final String nickname;
  final int points;
  final int missionsCompleted;
  final bool isMe;

  factory RankingEntry.fromMap(Map<String, dynamic> map) => RankingEntry(
        position: (map['rank_position'] as num).toInt(),
        playerId: map['player_id'] as String,
        nickname: map['nickname'] as String,
        points: map['points'] as int,
        missionsCompleted: (map['missions_completed'] as num).toInt(),
        isMe: (map['is_me'] as bool?) ?? false,
      );
}
