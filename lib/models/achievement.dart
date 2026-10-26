import '../core/game_meta.dart';

/// Conquista (tabela `achievements`) + data de desbloqueio do jogador.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.conditionType,
    required this.conditionValue,
    this.conditionCategory,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final String conditionType;
  final int conditionValue;
  final String? conditionCategory;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  /// Texto da condição de desbloqueio exibido no app.
  String get conditionLabel => switch (conditionType) {
        'missions_completed' =>
          'Conclua $conditionValue ${conditionValue == 1 ? 'missão' : 'missões'}',
        'distinct_days' => 'Conclua missões em $conditionValue dias diferentes',
        'category_completed' =>
          'Conclua $conditionValue missões de ${GameMeta.category(conditionCategory ?? '').label}',
        'points' => 'Alcance $conditionValue pontos',
        'cards_owned' => 'Tenha $conditionValue cartas na coleção',
        _ => description,
      };

  Achievement copyWithUnlocked(DateTime? date) => Achievement(
        id: id,
        name: name,
        description: description,
        icon: icon,
        conditionType: conditionType,
        conditionValue: conditionValue,
        conditionCategory: conditionCategory,
        unlockedAt: date,
      );

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        icon: map['icon'] as String,
        conditionType: (map['condition_type'] as String?) ?? '',
        conditionValue: (map['condition_value'] as int?) ?? 1,
        conditionCategory: map['condition_category'] as String?,
      );
}
