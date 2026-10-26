import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/game_meta.dart';
import '../core/responsive.dart';
import '../core/router.dart';
import '../core/theme.dart';
import '../models/mission.dart';
import '../models/player.dart';
import '../models/trapper_card.dart';
import '../services/game_repository.dart';
import '../widgets/mission_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/state_views.dart';

class _HomeData {
  const _HomeData(this.stats, this.missions, this.cards);
  final PlayerStats stats;
  final List<Mission> missions;
  final Map<String, TrapperCard> cards;
}

/// Central de missões: saudação, progresso, destaque e lista filtrável.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = GameRepository.instance;
  late Future<_HomeData> _future = _load();

  MissionStatus? _statusFilter;
  String? _categoryFilter;
  String? _difficultyFilter;

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

  Future<_HomeData> _load() async {
    final results = await Future.wait<dynamic>([
      _repo.fetchStats(),
      _repo.fetchMissions(),
      _repo.fetchCards(),
    ]);
    return _HomeData(
      results[0] as PlayerStats,
      results[1] as List<Mission>,
      results[2] as Map<String, TrapperCard>,
    );
  }

  void _reload() {
    if (mounted) setState(() => _future = _load());
  }

  /// Missão em destaque: a marcada como destaque, se ainda não concluída;
  /// senão, a próxima missão não concluída.
  Mission? _featured(List<Mission> missions) {
    final open = missions.where((m) => m.status != MissionStatus.completed);
    for (final m in open) {
      if (m.isFeatured) return m;
    }
    for (final m in open) {
      if (m.status == MissionStatus.inProgress) return m;
    }
    return open.isEmpty ? null : open.first;
  }

  List<TrapperCard> _enemies(Mission m, Map<String, TrapperCard> cards) =>
      [for (final id in m.enemyCards) if (cards[id] != null) cards[id]!];

  void _open(Mission m) => context.push(AppRoutes.mission(m.id), extra: m);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureView<_HomeData>(
          future: _future,
          onRetry: _reload,
          loadingMessage: 'Carregando missões...',
          builder: (context, data) => RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: _buildContent(data),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(_HomeData data) {
    final stats = data.stats;
    final featured = _featured(data.missions);
    final filtered = data.missions.where((m) {
      if (_statusFilter != null && m.status != _statusFilter) return false;
      if (_categoryFilter != null && m.category != _categoryFilter) return false;
      if (_difficultyFilter != null && m.difficulty != _difficultyFilter) return false;
      return true;
    }).toList();

    // Agrupa por categoria, na ordem definida em GameMeta.
    final groups = <String, List<Mission>>{
      for (final key in GameMeta.categories.keys)
        if (filtered.any((m) => m.category == key))
          key: filtered.where((m) => m.category == key).toList(),
    };

    final progress = ProgressCard(
      points: stats.profile.points,
      missionsCompleted: stats.missionsCompleted,
      totalMissions: stats.totalMissions,
      achievementsUnlocked: stats.achievementsUnlocked,
      totalAchievements: stats.totalAchievements,
    );
    final featuredCard = featured == null
        ? const EmptyView(
            message: 'Você concluiu todas as missões! Você é uma lenda do trap.',
            icon: Icons.emoji_events,
          )
        : MissionCard(
            mission: featured,
            enemies: _enemies(featured, data.cards),
            featured: true,
            onTap: () => _open(featured),
          );

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= Breakpoints.tablet;
      return ListView(
      padding: Breakpoints.pagePadding(context, available: constraints.maxWidth, vertical: 12),
      children: [
        // Saudação
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('E aí, ${stats.profile.nickname}!',
                      style: AppTheme.display(22), overflow: TextOverflow.ellipsis),
                  const Text('Pronto pra próxima batalha?',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Perfil',
              onPressed: () => context.go(AppRoutes.profile),
              icon: const Icon(Icons.person),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progresso + destaque: lado a lado em telas largas.
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: progress),
                const SizedBox(width: 16),
                Expanded(child: featuredCard),
              ],
            ),
          )
        else ...[
          progress,
          const SizedBox(height: 20),
          featuredCard,
        ],
        const SizedBox(height: 24),

        // Filtros
        Row(
          children: [
            Text('MISSÕES', style: AppTheme.display(18)),
            const Spacer(),
            PopupMenuButton<String?>(
              tooltip: 'Filtrar por dificuldade',
              initialValue: _difficultyFilter,
              onSelected: (v) => setState(() => _difficultyFilter = v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('Todas as dificuldades')),
                for (final e in GameMeta.difficulties.entries)
                  PopupMenuItem(
                    value: e.key,
                    child: Row(children: [
                      Icon(e.value.icon, color: e.value.color, size: 18),
                      const SizedBox(width: 8),
                      Text(e.value.label),
                    ]),
                  ),
              ],
              child: Chip(
                avatar: const Icon(Icons.tune, size: 16),
                label: Text(_difficultyFilter == null
                    ? 'Dificuldade'
                    : GameMeta.difficulty(_difficultyFilter!).label),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ChipsRow(children: [
          _filterChip('Todas', _statusFilter == null, () => setState(() => _statusFilter = null)),
          for (final s in MissionStatus.values)
            _filterChip(s.label, _statusFilter == s, () => setState(() => _statusFilter = s)),
        ]),
        const SizedBox(height: 6),
        _ChipsRow(children: [
          _filterChip('Todas categorias', _categoryFilter == null,
              () => setState(() => _categoryFilter = null)),
          for (final e in GameMeta.categories.entries)
            _filterChip(e.value.label, _categoryFilter == e.key,
                () => setState(() => _categoryFilter = e.key),
                icon: e.value.icon),
        ]),
        const SizedBox(height: 12),

        // Lista agrupada por categoria
        if (groups.isEmpty)
          const EmptyView(
            message: 'Nenhuma missão encontrada com esses filtros.',
            icon: Icons.search_off,
          )
        else
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Row(children: [
                Icon(GameMeta.category(entry.key).icon,
                    size: 18, color: GameMeta.category(entry.key).color),
                const SizedBox(width: 6),
                Text(GameMeta.category(entry.key).label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text('(${entry.value.length})',
                    style: const TextStyle(color: AppColors.textMuted)),
              ]),
            ),
            ResponsiveGrid(
              children: [
                for (final m in entry.value)
                  MissionCard(
                    mission: m,
                    enemies: _enemies(m, data.cards),
                    onTap: () => _open(m),
                  ),
              ],
            ),
          ],
      ],
    );
    });
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 16),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }
}
