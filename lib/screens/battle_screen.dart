import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/errors.dart';
import '../core/game_meta.dart';
import '../core/responsive.dart';
import '../core/router.dart';
import '../core/theme.dart';
import '../game/battle_engine.dart';
import '../models/achievement.dart';
import '../models/mission.dart';
import '../models/player.dart';
import '../models/trapper_card.dart';
import '../services/game_repository.dart';
import '../services/music_service.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/card_viewer.dart';
import '../widgets/state_views.dart';
import '../widgets/trapper_avatar.dart';
import '../widgets/trapper_card_widget.dart';

enum _Phase { loading, error, deck, fight, won, lost }

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.missionId, this.initialMission});
  final int missionId;
  final Mission? initialMission;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  static const _maxTeam = 3;
  static const _turnDelay = Duration(milliseconds: 750);

  final _repo = GameRepository.instance;
  _Phase _phase = _Phase.loading;
  Object? _error;

  late Mission _mission;
  Map<String, TrapperCard> _cards = {};
  List<TrapperCard> _owned = [];
  int _playerLevel = 1;
  final List<String> _selected = [];

  BattleEngine? _engine;
  BattleFighter? _actor;
  BattleFighter? _target;
  Set<BattleFighter> _flash = {};
  bool _busy = false;

  MissionResult? _result;
  bool _saving = false;
  Object? _saveError;

  final _music = MusicService.instance;
  String? _themeCardId; // trapper cuja música está tocando na batalha

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (_themeCardId != null) _music.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final results = await Future.wait<dynamic>([
        widget.initialMission != null
            ? Future.value(widget.initialMission)
            : _repo.fetchMission(widget.missionId),
        _repo.fetchCards(),
        _repo.fetchOwnedCardIds(),
        _repo.fetchProfile(),
      ]);
      _mission = results[0] as Mission;
      _cards = results[1] as Map<String, TrapperCard>;
      final owned = results[2] as Set<String>;
      _owned = _cards.values.where((c) => owned.contains(c.id)).toList();
      _playerLevel = PlayerLevel.of((results[3] as PlayerProfile).points);
      _selected
        ..clear()
        ..addAll(_owned.take(_maxTeam).map((c) => c.id));
      setState(() => _phase = _Phase.deck);
    } catch (e) {
      setState(() {
        _error = e;
        _phase = _Phase.error;
      });
    }
  }

  List<TrapperCard> get _enemyCards =>
      [for (final id in _mission.enemyCards) if (_cards[id] != null) _cards[id]!];

  // ------------------------------------------------------------------ batalha

  void _startBattle() {
    final engine = BattleEngine.create(
      playerCards: [for (final id in _selected) _cards[id]!],
      enemyCards: _enemyCards,
      playerLevel: _playerLevel,
      enemyLevel: _mission.enemyLevel,
    );
    engine.log.add('A batalha começou! Toque em uma carta sua e depois em um rival.');
    setState(() {
      _engine = engine;
      _actor = engine.firstReadyPlayer;
      _target = engine.firstAliveEnemy;
      _flash = {};
      _busy = false;
      _phase = _Phase.fight;
    });
    // Trilha da batalha: música de um trapper do seu time (se o arquivo existir).
    _music.playBattleTheme(_selected).then((id) {
      if (mounted) setState(() => _themeCardId = id);
    });
  }

  Future<void> _pause() => Future.delayed(_turnDelay);

  Future<void> _playerAct({required bool special}) async {
    final engine = _engine;
    final actor = _actor;
    final target = _target;
    if (engine == null || actor == null || target == null || _busy) return;

    setState(() {
      _busy = true;
      engine.playerAction(actor, target, special: special);
      _flash = engine.lastAffected.toSet();
    });
    await _pause();
    if (!mounted || _checkEnd()) return;

    // Turno do rival (repete se o time do jogador estiver todo atordoado).
    do {
      setState(() {
        engine.enemyTurn();
        _flash = engine.lastAffected.toSet();
      });
      await _pause();
      if (!mounted || _checkEnd()) return;
      if (!engine.playerCanAct) {
        setState(() {
          engine.skipPlayerTurn();
          _flash = {};
        });
        await _pause();
        if (!mounted) return;
      } else {
        break;
      }
    } while (true);

    setState(() {
      _busy = false;
      _flash = {};
      if (_actor == null || !_actor!.alive || _actor!.stunned) _actor = engine.firstReadyPlayer;
      if (_target == null || !_target!.alive) _target = engine.firstAliveEnemy;
    });
  }

  /// Verifica fim de jogo. Retorna true se a batalha acabou.
  bool _checkEnd() {
    switch (_engine?.outcome) {
      case BattleOutcome.playerWon:
        setState(() => _phase = _Phase.won);
        _saveVictory();
        return true;
      case BattleOutcome.playerLost:
        setState(() => _phase = _Phase.lost);
        return true;
      case null:
        return false;
    }
  }

  /// Registra a vitória no Supabase (pontos e conquistas são calculados no servidor).
  Future<void> _saveVictory() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final result = await _repo.completeMission(_mission.id);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _saveError = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonar batalha?'),
        content: const Text('O progresso desta batalha será perdido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
        ],
      ),
    );
    return leave ?? false;
  }

  void _exit() => context.canPop() ? context.pop() : context.go(AppRoutes.home);

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final fighting = _phase == _Phase.fight;
    return PopScope(
      canPop: !fighting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_phase == _Phase.loading || _phase == _Phase.error
              ? 'BATALHA'
              : _mission.title.toUpperCase()),
          titleTextStyle: AppTheme.display(14),
          actions: [
            if (_themeCardId != null)
              ListenableBuilder(
                listenable: _music,
                builder: (context, _) => IconButton(
                  tooltip: _music.muted
                      ? 'Ligar música'
                      : 'Tocando: ${_cards[_themeCardId]?.name ?? ''} (silenciar)',
                  onPressed: () => _music.setMuted(!_music.muted),
                  icon: Icon(_music.muted ? Icons.volume_off : Icons.music_note),
                ),
              ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (!fighting || await _confirmLeave()) {
                if (mounted) _exit();
              }
            },
          ),
        ),
        body: SafeArea(
          child: ResponsiveCenter(
            maxWidth: _phase == _Phase.deck ? 1100 : 820,
            child: switch (_phase) {
              _Phase.loading => const LoadingView(message: 'Preparando a arena...'),
              _Phase.error => ErrorView(error: _error!, onRetry: _load),
              _Phase.deck => _buildDeck(),
              _Phase.fight => _buildFight(),
              _Phase.won => _buildWon(),
              _Phase.lost => _buildLost(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeck() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('TIME RIVAL • NV ${_mission.enemyLevel}',
                  style: AppTheme.display(14, color: AppColors.danger)),
              const SizedBox(height: 10),
              Row(children: [
                for (final e in _enemyCards)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(children: [
                      TrapperAvatar(card: e, size: 52),
                      const SizedBox(height: 4),
                      Text(e.name, style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 20),
              Text('ESCOLHA SEU TIME (${_selected.length}/$_maxTeam)', style: AppTheme.display(14)),
              const SizedBox(height: 4),
              Text('Suas cartas estão no nível $_playerLevel (bônus de atributos pelo seu nível).',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              if (_owned.isEmpty)
                const EmptyView(message: 'Você ainda não tem cartas.', icon: Icons.style)
              else
                GridView.extent(
                  maxCrossAxisExtent: 170,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2 / 3,
                  children: [
                    for (final card in _owned)
                      TrapperCardWidget(
                        card: card,
                        compact: true,
                        selected: _selected.contains(card.id),
                        onTap: () => setState(() {
                          if (_selected.contains(card.id)) {
                            _selected.remove(card.id);
                          } else if (_selected.length < _maxTeam) {
                            _selected.add(card.id);
                          } else {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(const SnackBar(
                                  content: Text('Máximo de 3 cartas. Remova uma antes.')));
                          }
                        }),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _selected.isEmpty ? null : _startBattle,
            icon: const Icon(Icons.sports_kabaddi),
            label: const Text('COMEÇAR BATALHA'),
          ),
        ),
      ],
    );
  }

  Widget _buildFight() {
    final engine = _engine!;
    final actor = _actor;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: _HypeBar(label: 'Hype rival', value: engine.enemyHype, color: AppColors.danger),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            for (final f in engine.enemies)
              Expanded(
                child: _FighterTile(
                  fighter: f,
                  highlighted: f == _target,
                  highlightColor: AppColors.danger,
                  flashing: _flash.contains(f),
                  onTap: _busy || !f.alive ? null : () => setState(() => _target = f),
                ),
              ),
          ]),
        ),
        // Log da batalha
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: engine.log.length,
              itemBuilder: (context, i) {
                final text = engine.log[engine.log.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: i == 0 ? Colors.white : AppColors.textMuted,
                      fontWeight: i == 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            for (final f in engine.players)
              Expanded(
                child: _FighterTile(
                  fighter: f,
                  highlighted: f == actor,
                  highlightColor: AppColors.accent,
                  flashing: _flash.contains(f),
                  onTap: _busy || !f.alive || f.stunned ? null : () => setState(() => _actor = f),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _HypeBar(label: 'Seu Hype', value: engine.playerHype, color: AppColors.accent),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy || actor == null ? null : () => _playerAct(special: false),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('ATACAR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Tooltip(
                  message: actor?.card.specialDesc ?? '',
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _busy || actor == null || !engine.playerCanUseSpecial
                        ? null
                        : () => _playerAct(special: true),
                    child: FittedBox(
                      child: Text(actor == null
                          ? 'ESPECIAL'
                          : '${actor.card.specialName.toUpperCase()} (${BattleEngine.hypeCost}⚡)'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWon() {
    final result = _result;
    final reward = result?.rewardCardId == null ? null : _cards[result!.rewardCardId];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: const Icon(Icons.emoji_events, size: 110, color: AppColors.gold),
        ),
        Text('VITÓRIA!', textAlign: TextAlign.center, style: AppTheme.display(34, color: AppColors.gold)),
        const SizedBox(height: 16),
        if (_saving)
          const LoadingView(message: 'Registrando vitória no servidor...')
        else if (_saveError != null) ...[
          Text(friendlyError(_saveError!),
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saveVictory,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar salvar de novo'),
          ),
        ] else if (result != null) ...[
          if (result.alreadyCompleted)
            const Text(
              'Revanche vencida! Esta missão já tinha sido concluída, então não gera pontos de novo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            Text('+${result.pointsAwarded} pontos',
                textAlign: TextAlign.center, style: AppTheme.display(26, color: AppColors.accent)),
          if (reward != null) ...[
            const SizedBox(height: 24),
            Text('NOVA CARTA RECRUTADA!', textAlign: TextAlign.center, style: AppTheme.display(14)),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 180,
                height: 270,
                child: TrapperCardWidget(
                  card: reward,
                  onTap: () => showCardViewer(context, reward),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Toque na carta para ver a arte completa e ouvir a música.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          if (result.newAchievements.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('CONQUISTAS DESBLOQUEADAS', textAlign: TextAlign.center, style: AppTheme.display(14)),
            const SizedBox(height: 10),
            for (final a in result.newAchievements)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.scale(scale: 0.8 + 0.2 * v, child: child),
                  ),
                  child: SizedBox(
                    height: 190,
                    child: AchievementBadge(
                      achievement: Achievement(
                        id: a['id'] as String,
                        name: a['name'] as String,
                        description: a['description'] as String,
                        icon: a['icon'] as String,
                        conditionType: '',
                        conditionValue: 1,
                        unlockedAt: DateTime.now(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _saving ? null : () => context.go(AppRoutes.home),
          icon: const Icon(Icons.map),
          label: const Text('VOLTAR ÀS MISSÕES'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _saving ? null : () => context.go(AppRoutes.achievements),
          icon: const Icon(Icons.emoji_events),
          label: const Text('Ver conquistas'),
        ),
      ],
    );
  }

  Widget _buildLost() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.heart_broken, size: 100, color: AppColors.danger),
            Text('DERROTA', style: AppTheme.display(32, color: AppColors.danger)),
            const SizedBox(height: 12),
            const Text(
              'Seu time foi nocauteado. Troque as cartas, aproveite as vantagens de elemento e tente de novo!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => setState(() => _phase = _Phase.deck),
              icon: const Icon(Icons.replay),
              label: const Text('TENTAR DE NOVO'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _exit, child: const Text('Voltar para a missão')),
          ],
        ),
      ),
    );
  }
}

/// Carta em campo: avatar, vida, seleção e efeito de dano/cura.
class _FighterTile extends StatelessWidget {
  const _FighterTile({
    required this.fighter,
    required this.highlighted,
    required this.highlightColor,
    required this.flashing,
    this.onTap,
  });

  final BattleFighter fighter;
  final bool highlighted;
  final Color highlightColor;
  final bool flashing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final f = fighter;
    final healed = flashing && f.lastHeal > 0;
    final damaged = flashing && f.lastDamage > 0 && !healed;
    final hpColor = f.hpRatio > 0.5
        ? AppColors.accent
        : f.hpRatio > 0.25
            ? const Color(0xFFFFD60A)
            : AppColors.danger;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: f.alive ? 1 : 0.35,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: damaged
                ? AppColors.danger.withValues(alpha: 0.35)
                : healed
                    ? AppColors.accent.withValues(alpha: 0.25)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted && f.alive ? highlightColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  TrapperAvatar(
                    card: f.card,
                    size: Breakpoints.isTablet(context) ? 76 : 52,
                    locked: !f.alive,
                  ),
                  if (f.stunned)
                    const Positioned(
                      top: -6,
                      left: -6,
                      child: Icon(Icons.blur_on, color: Color(0xFFFFD60A), size: 22),
                    ),
                  if (damaged || healed)
                    Positioned(
                      top: -10,
                      child: Text(
                        damaged ? '-${f.lastDamage}' : '+${f.lastHeal}',
                        style: AppTheme.display(16,
                            color: damaged ? AppColors.danger : AppColors.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: f.hpRatio),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    color: hpColor,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(f.alive ? '${f.hp}/${f.maxHp}' : 'K.O.',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HypeBar extends StatelessWidget {
  const _HypeBar({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(width: 8),
        for (var i = 0; i < BattleEngine.hypeMax; i++)
          Icon(
            Icons.bolt,
            size: 18,
            color: i < value ? color : Colors.white12,
          ),
        const Spacer(),
        if (value >= BattleEngine.hypeCost)
          Text('ESPECIAL PRONTO', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
