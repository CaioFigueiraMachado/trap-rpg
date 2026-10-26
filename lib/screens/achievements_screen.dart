import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/achievement.dart';
import '../models/player.dart';
import '../services/game_repository.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/state_views.dart';

class _AchievementsData {
  const _AchievementsData(this.achievements, this.stats);
  final List<Achievement> achievements;
  final PlayerStats stats;
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repo = GameRepository.instance;
  late Future<_AchievementsData> _future = _load();

  @override
  void initState() {
    super.initState();
    _repo.addListener(_reload);
  }

  @override
  void dispose() {
    _repo.removeListener(_reload);
    super.dispose();
  }

  Future<_AchievementsData> _load() async {
    final r = await Future.wait<dynamic>([_repo.fetchAchievements(), _repo.fetchStats()]);
    return _AchievementsData(r[0] as List<Achievement>, r[1] as PlayerStats);
  }

  void _reload() {
    if (mounted) setState(() => _future = _load());
  }

  /// Valor atual do jogador para a condição da conquista.
  int _current(Achievement a, PlayerStats s) => switch (a.conditionType) {
        'missions_completed' => s.missionsCompleted,
        'distinct_days' => s.distinctDays,
        'category_completed' => s.completedByCategory[a.conditionCategory] ?? 0,
        'points' => s.profile.points,
        'cards_owned' => s.cardsOwned,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CONQUISTAS')),
      body: FutureView<_AchievementsData>(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final list = data.achievements;
          final unlocked = list.where((a) => a.isUnlocked).length;
          // Desbloqueadas primeiro.
          final sorted = [
            ...list.where((a) => a.isUnlocked),
            ...list.where((a) => !a.isUnlocked),
          ];

          return LayoutBuilder(builder: (context, constraints) {
          final pad = Breakpoints.pagePadding(context, available: constraints.maxWidth, vertical: 0);
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: pad.copyWith(top: 8, bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: AppColors.gold, size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$unlocked de ${list.length}', style: AppTheme.display(20)),
                              const Text('conquistas desbloqueadas',
                                  style: TextStyle(color: AppColors.textMuted)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: list.isEmpty ? 0 : unlocked / list.length,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                                color: AppColors.gold,
                                backgroundColor: Colors.white10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (list.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyView(message: 'Nenhuma conquista cadastrada.'),
                  )
                else
                  SliverPadding(
                    padding: pad.copyWith(bottom: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 236,
                      ),
                      delegate: SliverChildListDelegate([
                        for (final a in sorted)
                          AchievementBadge(
                            achievement: a,
                            progress: _current(a, data.stats) / a.conditionValue,
                            progressLabel:
                                '${_current(a, data.stats).clamp(0, a.conditionValue)}/${a.conditionValue}',
                          ),
                      ]),
                    ),
                  ),
              ],
            ),
          );
          });
        },
      ),
    );
  }
}
