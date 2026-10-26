import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/achievement.dart';
import '../models/mission.dart';
import '../models/player.dart';
import '../models/trapper_card.dart';

/// Toda a comunicação do jogo com o Supabase fica aqui.
///
/// É um [ChangeNotifier]: quando uma missão é iniciada/concluída ou o perfil
/// muda, as telas que estão ouvindo recarregam seus dados automaticamente.
class GameRepository extends ChangeNotifier {
  GameRepository._();
  static final instance = GameRepository._();

  SupabaseClient get _db => Supabase.instance.client;

  String get _uid {
    final user = _db.auth.currentUser;
    if (user == null) throw AuthException('Sessão expirada. Faça login novamente.');
    return user.id;
  }

  String? get email => _db.auth.currentUser?.email;

  // As cartas são um catálogo fixo: buscamos uma vez e guardamos.
  Map<String, TrapperCard>? _cardsCache;

  void clearCache() => _cardsCache = null;

  // ---------------------------------------------------------------- cartas

  Future<Map<String, TrapperCard>> fetchCards() async {
    final cached = _cardsCache;
    if (cached != null) return cached;
    final rows = await _db.from('cards').select().order('sort_order');
    return _cardsCache = {
      for (final row in rows) row['id'] as String: TrapperCard.fromMap(row),
    };
  }

  Future<Set<String>> fetchOwnedCardIds() async {
    final rows = await _db.from('user_cards').select('card_id').eq('user_id', _uid);
    return {for (final row in rows) row['card_id'] as String};
  }

  // ---------------------------------------------------------------- perfil

  Future<PlayerProfile> fetchProfile() async {
    final row = await _db
        .from('profiles')
        .select('id, nickname, points')
        .eq('id', _uid)
        .maybeSingle();
    if (row == null) {
      throw Exception('Perfil não encontrado. Verifique se o script do banco foi executado.');
    }
    return PlayerProfile.fromMap(row);
  }

  /// Só o apelido pode ser alterado pelo app (a pontuação é protegida no banco).
  Future<void> updateNickname(String nickname) async {
    await _db.from('profiles').update({'nickname': nickname.trim()}).eq('id', _uid);
    notifyListeners();
  }

  Future<PlayerStats> fetchStats() async {
    final uid = _uid;
    final results = await Future.wait<dynamic>([
      fetchProfile(),
      _db
          .from('user_missions')
          .select('completed_at, missions(category)')
          .eq('user_id', uid)
          .eq('status', 'completed'),
      _db.from('missions').select('id'),
      _db.from('user_achievements').select('achievement_id').eq('user_id', uid),
      _db.from('achievements').select('id'),
      fetchOwnedCardIds(),
      fetchCards(),
    ]);

    final completedRows = results[1] as List;
    final days = <String>{};
    final byCategory = <String, int>{};
    for (final row in completedRows) {
      final date = DateTime.parse(row['completed_at'] as String).toLocal();
      days.add('${date.year}-${date.month}-${date.day}');
      final category = (row['missions'] as Map?)?['category'] as String?;
      if (category != null) byCategory[category] = (byCategory[category] ?? 0) + 1;
    }

    return PlayerStats(
      profile: results[0] as PlayerProfile,
      missionsCompleted: completedRows.length,
      totalMissions: (results[2] as List).length,
      achievementsUnlocked: (results[3] as List).length,
      totalAchievements: (results[4] as List).length,
      cardsOwned: (results[5] as Set<String>).length,
      totalCards: (results[6] as Map<String, TrapperCard>).length,
      distinctDays: days.length,
      completedByCategory: byCategory,
    );
  }

  // ---------------------------------------------------------------- missões

  Future<List<Mission>> fetchMissions() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      _db.from('missions').select().order('sort_order'),
      _db.from('user_missions').select('mission_id, status').eq('user_id', _uid),
    ]);
    final statusById = {
      for (final row in results[1]) row['mission_id'] as int: row['status'] as String,
    };
    return [
      for (final row in results[0])
        Mission.fromMap(row).withStatus(MissionStatus.fromDb(statusById[row['id']])),
    ];
  }

  Future<Mission> fetchMission(int id) async {
    final results = await Future.wait<Map<String, dynamic>?>([
      _db.from('missions').select().eq('id', id).maybeSingle(),
      _db
          .from('user_missions')
          .select('status')
          .eq('user_id', _uid)
          .eq('mission_id', id)
          .maybeSingle(),
    ]);
    final missionRow = results[0];
    if (missionRow == null) throw Exception('Missão não encontrada.');
    return Mission.fromMap(missionRow)
        .withStatus(MissionStatus.fromDb(results[1]?['status'] as String?));
  }

  /// Marca a missão como "em andamento" (função `start_mission` no banco).
  Future<void> startMission(int missionId) async {
    await _db.rpc('start_mission', params: {'p_mission_id': missionId});
    notifyListeners();
  }

  /// Conclui a missão. Os pontos são somados no servidor, apenas uma vez.
  Future<MissionResult> completeMission(int missionId) async {
    final data = await _db.rpc('complete_mission', params: {'p_mission_id': missionId});
    notifyListeners();
    return MissionResult.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<List<MissionHistoryEntry>> fetchHistory() async {
    final rows = await _db
        .from('user_missions')
        .select('points_awarded, completed_at, missions(title, category)')
        .eq('user_id', _uid)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);
    return [
      for (final row in rows)
        MissionHistoryEntry(
          title: (row['missions'] as Map?)?['title'] as String? ?? 'Missão',
          category: (row['missions'] as Map?)?['category'] as String? ?? '',
          points: row['points_awarded'] as int,
          completedAt: DateTime.parse(row['completed_at'] as String).toLocal(),
        ),
    ];
  }

  // ---------------------------------------------------------------- conquistas

  Future<List<Achievement>> fetchAchievements() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      _db.from('achievements').select().order('sort_order'),
      _db.from('user_achievements').select('achievement_id, unlocked_at').eq('user_id', _uid),
    ]);
    final unlocked = {
      for (final row in results[1])
        row['achievement_id'] as String: DateTime.parse(row['unlocked_at'] as String).toLocal(),
    };
    return [
      for (final row in results[0])
        Achievement.fromMap(row).copyWithUnlocked(unlocked[row['id']]),
    ];
  }

  // ---------------------------------------------------------------- ranking

  /// Ranking calculado no banco (função `get_ranking`) a partir dos pontos salvos.
  Future<List<RankingEntry>> fetchRanking({int limit = 50}) async {
    final rows = await _db.rpc('get_ranking', params: {'p_limit': limit});
    return [
      for (final row in rows as List) RankingEntry.fromMap(Map<String, dynamic>.from(row as Map)),
    ];
  }
}
