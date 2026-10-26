import 'package:flutter/material.dart';

import '../core/game_meta.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../game/battle_engine.dart';
import '../models/mission.dart';
import '../models/trapper_card.dart';
import '../services/game_repository.dart';
import '../widgets/card_viewer.dart';
import '../widgets/state_views.dart';
import '../widgets/trapper_card_widget.dart';

class _CollectionData {
  const _CollectionData(this.cards, this.owned, this.missions);
  final Map<String, TrapperCard> cards;
  final Set<String> owned;
  final List<Mission> missions;
}

/// Coleção de cartas: desbloqueadas e as que ainda faltam recrutar.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _repo = GameRepository.instance;
  late Future<_CollectionData> _future = _load();

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

  Future<_CollectionData> _load() async {
    final r = await Future.wait<dynamic>([
      _repo.fetchCards(),
      _repo.fetchOwnedCardIds(),
      _repo.fetchMissions(),
    ]);
    return _CollectionData(
      r[0] as Map<String, TrapperCard>,
      r[1] as Set<String>,
      r[2] as List<Mission>,
    );
  }

  void _reload() {
    if (mounted) setState(() => _future = _load());
  }

  String _hint(TrapperCard card, List<Mission> missions) {
    for (final m in missions) {
      if (m.rewardCardId == card.id) return 'Vença "${m.title}"';
    }
    return 'Bloqueada';
  }

  void _showDetails(TrapperCard card) => showCardViewer(context, card);

  void _showElements() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vantagens de elemento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final attacker in GameMeta.elements.keys)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(GameMeta.element(attacker).icon,
                      color: GameMeta.element(attacker).color),
                  title: Text(GameMeta.element(attacker).label),
                  subtitle: Text(attacker == 'cosmico'
                      ? '+15% de dano contra todos'
                      : 'Forte contra: ${GameMeta.elements.keys.where((d) => BattleEngine.elementMultiplier(attacker, d) > 1).map((d) => GameMeta.element(d).label).join(', ')}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COLEÇÃO'),
        actions: [
          IconButton(
            tooltip: 'Vantagens de elemento',
            onPressed: _showElements,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: FutureView<_CollectionData>(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final cards = data.cards.values.toList();
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
                  child: Padding(
                    padding: pad.copyWith(top: 8, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${data.owned.length}/${cards.length} cartas recrutadas',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: cards.isEmpty ? 0 : data.owned.length / cards.length,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.accent,
                          backgroundColor: Colors.white10,
                        ),
                      ],
                    ),
                  ),
                ),
                if (cards.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyView(message: 'Nenhuma carta cadastrada no banco.'),
                  )
                else
                  SliverPadding(
                    padding: pad.copyWith(bottom: 24),
                    // Quantidade de colunas automática: 2 no celular, até 5-6 no computador.
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 230,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 2 / 3,
                      ),
                      delegate: SliverChildListDelegate([
                        for (final card in cards)
                          TrapperCardWidget(
                            card: card,
                            owned: data.owned.contains(card.id),
                            lockedHint: _hint(card, data.missions),
                            onTap: data.owned.contains(card.id) ? () => _showDetails(card) : null,
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
