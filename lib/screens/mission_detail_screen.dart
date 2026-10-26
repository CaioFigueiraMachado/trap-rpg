import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/errors.dart';
import '../core/game_meta.dart';
import '../core/responsive.dart';
import '../core/router.dart';
import '../core/theme.dart';
import '../models/mission.dart';
import '../models/trapper_card.dart';
import '../services/game_repository.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';
import '../widgets/trapper_avatar.dart';
import '../widgets/trapper_card_widget.dart';

class _DetailData {
  const _DetailData(this.mission, this.cards, this.owned);
  final Mission mission;
  final Map<String, TrapperCard> cards;
  final Set<String> owned;
}

class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({super.key, required this.missionId, this.initialMission});

  final int missionId;

  /// Missão recebida da Home pela rota (evita esperar o carregamento).
  final Mission? initialMission;

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final _repo = GameRepository.instance;
  late Future<_DetailData> _future = _load(useInitial: true);
  bool _starting = false;

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

  Future<_DetailData> _load({bool useInitial = false}) async {
    final initial = useInitial ? widget.initialMission : null;
    final results = await Future.wait<dynamic>([
      if (initial != null) Future.value(initial) else _repo.fetchMission(widget.missionId),
      _repo.fetchCards(),
      _repo.fetchOwnedCardIds(),
    ]);
    return _DetailData(
      results[0] as Mission,
      results[1] as Map<String, TrapperCard>,
      results[2] as Set<String>,
    );
  }

  void _reload() {
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _start(Mission mission) async {
    setState(() => _starting = true);
    try {
      await _repo.startMission(mission.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missão iniciada! Monte seu time e vá para a batalha.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.danger,
        content: Text(friendlyError(e)),
      ));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _goBattle(Mission mission) =>
      context.push(AppRoutes.battle(mission.id), extra: mission);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MISSÃO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: FutureView<_DetailData>(
        future: _future,
        onRetry: _reload,
        builder: (context, data) => _buildBody(data),
      ),
    );
  }

  Widget _buildBody(_DetailData data) {
    final m = data.mission;
    final category = GameMeta.category(m.category);
    final difficulty = GameMeta.difficulty(m.difficulty);
    final enemies = [for (final id in m.enemyCards) if (data.cards[id] != null) data.cards[id]!];
    final reward = m.rewardCardId == null ? null : data.cards[m.rewardCardId];

    return Column(
      children: [
        Expanded(
          child: _TwoColumns(
            main: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [category.color.withValues(alpha: 0.45), AppColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(category.icon, color: category.color),
                      const SizedBox(width: 6),
                      Text(category.label.toUpperCase(),
                          style: TextStyle(
                              color: category.color, fontWeight: FontWeight.w800, fontSize: 12)),
                      const Spacer(),
                      StatusBadge(status: m.status),
                    ]),
                    const SizedBox(height: 12),
                    Text(m.title, style: AppTheme.display(22)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      InfoChip(icon: difficulty.icon, label: difficulty.label, color: difficulty.color),
                      InfoChip(icon: Icons.bolt, label: '+${m.points} pontos', color: AppColors.accent),
                      InfoChip(
                          icon: Icons.trending_up,
                          label: 'Inimigos nv ${m.enemyLevel}',
                          color: AppColors.danger),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(title: 'Descrição', child: Text(m.description, style: const TextStyle(height: 1.4))),
              _Section(
                title: 'Como vencer',
                icon: Icons.lightbulb_outline,
                child: Text(m.guidance,
                    style: const TextStyle(height: 1.4, color: AppColors.textMuted)),
              ),
            ],
            side: [
              _Section(
                title: 'Time rival',
                icon: Icons.groups,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (final e in enemies)
                      Column(children: [
                        TrapperAvatar(card: e, size: 72),
                        const SizedBox(height: 6),
                        Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(GameMeta.element(e.element).label,
                            style: TextStyle(
                                fontSize: 11, color: GameMeta.element(e.element).color)),
                      ]),
                  ],
                ),
              ),
              if (reward != null)
                _Section(
                  title: 'Recompensa',
                  icon: Icons.card_giftcard,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 210,
                        child: TrapperCardWidget(card: reward, compact: true),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          data.owned.contains(reward.id)
                              ? '${reward.name} já está na sua coleção.'
                              : 'Vença para recrutar ${reward.name} para o seu time!',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Ações conforme o status
        SafeArea(
          top: false,
          child: ResponsiveCenter(
            maxWidth: 560,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: switch (m.status) {
              MissionStatus.available => FilledButton.icon(
                  onPressed: _starting ? null : () => _start(m),
                  icon: _starting
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('INICIAR MISSÃO'),
                ),
              MissionStatus.inProgress => FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent, foregroundColor: Colors.black),
                  onPressed: () => _goBattle(m),
                  icon: const Icon(Icons.sports_kabaddi),
                  label: const Text('IR PARA A BATALHA'),
                ),
              MissionStatus.completed => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.accent),
                        SizedBox(width: 6),
                        Text('Missão concluída! Pontos já recebidos.',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _goBattle(m),
                      icon: const Icon(Icons.replay),
                      label: const Text('Revanche (sem pontos)'),
                    ),
                  ],
                ),
            },
          ),
          ),
        ),
      ],
    );
  }
}

/// Celular: uma coluna rolável. Tablet/computador: conteúdo à esquerda e
/// time rival + recompensa à direita.
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.main, required this.side});
  final List<Widget> main;
  final List<Widget> side;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final padding = Breakpoints.pagePadding(context, available: constraints.maxWidth, maxWidth: 1100);
      if (constraints.maxWidth < Breakpoints.tablet) {
        return ListView(padding: padding, children: [...main, ...side]);
      }
      return SingleChildScrollView(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: main)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: side)),
          ],
        ),
      );
    });
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.icon});
  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
