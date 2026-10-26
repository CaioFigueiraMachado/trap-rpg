import 'package:flutter/material.dart';

import '../core/game_meta.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/player.dart';
import '../services/game_repository.dart';
import '../widgets/state_views.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _repo = GameRepository.instance;
  late Future<List<RankingEntry>> _future = _repo.fetchRanking();

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

  void _reload() {
    if (mounted) setState(() => _future = _repo.fetchRanking());
  }

  static Color medalColor(int position) => switch (position) {
        1 => AppColors.gold,
        2 => AppColors.silver,
        3 => AppColors.bronze,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RANKING')),
      body: FutureView<List<RankingEntry>>(
        future: _future,
        onRetry: _reload,
        loadingMessage: 'Calculando ranking...',
        builder: (context, entries) {
          if (entries.isEmpty) {
            return const EmptyView(message: 'Ninguém pontuou ainda. Seja o primeiro!', icon: Icons.leaderboard);
          }
          final me = entries.where((e) => e.isMe).firstOrNull;
          final top3 = entries.where((e) => e.position <= 3).toList();
          final rest = entries.where((e) => e.position > 3).toList();

          return LayoutBuilder(builder: (context, constraints) => RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: Breakpoints.pagePadding(context, maxWidth: 760, available: constraints.maxWidth)
                  .copyWith(top: 8, bottom: 24),
              children: [
                if (me != null) _MyPosition(entry: me),
                const SizedBox(height: 20),
                _Podium(entries: top3),
                const SizedBox(height: 20),
                for (final e in rest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RankTile(entry: e),
                  ),
              ],
            ),
          ));
        },
      ),
    );
  }
}

class _MyPosition extends StatelessWidget {
  const _MyPosition({required this.entry});
  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
      ),
      child: Row(
        children: [
          Text('#${entry.position}', style: AppTheme.display(30, color: AppColors.gold)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sua posição', style: TextStyle(color: Colors.white70)),
                Text(entry.nickname,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('${entry.points} pts', style: AppTheme.display(16)),
        ],
      ),
    );
  }
}

/// Pódio com destaque visual para os 3 primeiros (2º, 1º, 3º).
class _Podium extends StatelessWidget {
  const _Podium({required this.entries});
  final List<RankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    RankingEntry? at(int pos) => entries.where((e) => e.position == pos).firstOrNull;

    Widget column(int pos, double height) {
      final e = at(pos);
      final color = _RankingScreenState.medalColor(pos);
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (pos == 1) const Icon(Icons.workspace_premium, color: AppColors.gold, size: 30),
            CircleAvatar(
              radius: pos == 1 ? 32 : 26,
              backgroundColor: color,
              child: CircleAvatar(
                radius: pos == 1 ? 29 : 23,
                backgroundColor: AppColors.surfaceHigh,
                child: Text(
                  e == null ? '-' : e.nickname.substring(0, 1).toUpperCase(),
                  style: AppTheme.display(pos == 1 ? 22 : 18, color: color),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              e?.nickname ?? '---',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: e?.isMe ?? false ? AppColors.accent : Colors.white,
              ),
            ),
            Text(e == null ? '' : '${e.points} pts',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Container(
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.15)],
                ),
              ),
              child: Text('$pos', style: AppTheme.display(28)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [column(2, 80), column(1, 110), column(3, 60)],
      ),
    );
  }
}

/// Linha do ranking (posições 4+).
class RankTile extends StatelessWidget {
  const RankTile({super.key, required this.entry});
  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isMe ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: entry.isMe ? Border.all(color: AppColors.accent) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('#${entry.position}', style: AppTheme.display(14, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.isMe ? '${entry.nickname} (você)' : entry.nickname,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  'Nv ${PlayerLevel.of(entry.points)} • ${entry.missionsCompleted} missões',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text('${entry.points} pts', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
