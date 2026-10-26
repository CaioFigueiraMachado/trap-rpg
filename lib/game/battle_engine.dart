import 'dart:math';

import '../models/trapper_card.dart';

enum BattleOutcome { playerWon, playerLost }

/// Uma carta em campo, com vida e atributos já ajustados pelo nível.
class BattleFighter {
  BattleFighter({required this.card, required this.isPlayer, required double scale})
      : maxHp = (card.hp * scale).round(),
        attack = (card.attack * scale).round(),
        defense = (card.defense * scale).round() {
    hp = maxHp;
  }

  final TrapperCard card;
  final bool isPlayer;
  final int maxHp;
  final int attack;
  final int defense;
  late int hp;
  bool stunned = false;

  /// Último dano/cura recebido (para a animação de números na tela).
  int lastDamage = 0;
  int lastHeal = 0;

  String get name => card.name;
  bool get alive => hp > 0;
  double get hpRatio => hp / maxHp;
}

/// Regras da batalha por turnos. Não depende de Flutter (fácil de testar).
///
/// - O jogador escolhe uma carta para agir e um alvo.
/// - Ataque normal gera 1 de Hype; o Especial custa [hypeCost].
/// - Vantagem de elemento: x1.4 de dano; desvantagem: x0.8.
/// - Carta atordoada perde o próximo turno do seu lado.
class BattleEngine {
  BattleEngine({
    required this.players,
    required this.enemies,
    Random? random,
  }) : _rng = random ?? Random();

  factory BattleEngine.create({
    required List<TrapperCard> playerCards,
    required List<TrapperCard> enemyCards,
    required int playerLevel,
    required int enemyLevel,
    Random? random,
  }) {
    final playerScale = 1 + 0.08 * (playerLevel - 1);
    final enemyScale = 1 + 0.12 * (enemyLevel - 1);
    return BattleEngine(
      players: [
        for (final c in playerCards) BattleFighter(card: c, isPlayer: true, scale: playerScale),
      ],
      enemies: [
        for (final c in enemyCards) BattleFighter(card: c, isPlayer: false, scale: enemyScale),
      ],
      random: random,
    );
  }

  static const hypeCost = 3;
  static const hypeMax = 5;

  /// Quem é forte contra quem.
  static const _strongAgainst = <String, List<String>>{
    'fogo': ['gelo', 'vento'],
    'gelo': ['vento', 'tempestade'],
    'vento': ['terra'],
    'terra': ['tempestade', 'fogo'],
    'tempestade': ['fogo', 'gelo'],
    'sombra': ['luz'],
    'luz': ['sombra'],
    'cosmico': [],
  };

  static double elementMultiplier(String attacker, String defender) {
    if (attacker == 'cosmico') return 1.15;
    if (_strongAgainst[attacker]?.contains(defender) ?? false) return 1.4;
    if (_strongAgainst[defender]?.contains(attacker) ?? false) return 0.8;
    return 1.0;
  }

  final List<BattleFighter> players;
  final List<BattleFighter> enemies;
  final Random _rng;
  final List<String> log = [];
  int playerHype = 0;
  int enemyHype = 0;
  int turn = 1;

  /// Cartas atingidas/curadas na última ação (para animação).
  List<BattleFighter> lastAffected = [];

  BattleOutcome? get outcome {
    if (enemies.every((f) => !f.alive)) return BattleOutcome.playerWon;
    if (players.every((f) => !f.alive)) return BattleOutcome.playerLost;
    return null;
  }

  bool get playerCanAct => players.any((f) => f.alive && !f.stunned);
  bool get playerCanUseSpecial => playerHype >= hypeCost;

  BattleFighter? get firstAliveEnemy => _firstAlive(enemies);
  BattleFighter? get firstReadyPlayer {
    for (final f in players) {
      if (f.alive && !f.stunned) return f;
    }
    return null;
  }

  BattleFighter? _firstAlive(List<BattleFighter> list) {
    for (final f in list) {
      if (f.alive) return f;
    }
    return null;
  }

  /// Turno do jogador.
  void playerAction(BattleFighter actor, BattleFighter target, {required bool special}) {
    if (outcome != null) return;
    if (!actor.isPlayer || !actor.alive || actor.stunned) {
      throw StateError('Essa carta não pode agir agora.');
    }
    if (special && playerHype < hypeCost) throw StateError('Hype insuficiente.');
    final validTarget = target.alive && !target.isPlayer ? target : firstAliveEnemy!;

    _execute(actor, validTarget, special: special);
    playerHype = special ? playerHype - hypeCost : min(hypeMax, playerHype + 1);
    for (final f in players) {
      f.stunned = false;
    }
  }

  /// Quando todas as cartas do jogador estão atordoadas.
  void skipPlayerTurn() {
    log.add('Seu time está atordoado e perdeu a vez!');
    lastAffected = [];
    for (final f in players) {
      f.stunned = false;
    }
  }

  /// Turno do inimigo (IA simples).
  void enemyTurn() {
    if (outcome != null) return;
    final ready = enemies.where((f) => f.alive && !f.stunned).toList();
    for (final f in enemies) {
      f.stunned = false;
    }
    if (ready.isEmpty) {
      log.add('O time rival está atordoado e perdeu a vez!');
      lastAffected = [];
      turn++;
      return;
    }

    final actor = ready[_rng.nextInt(ready.length)];
    final targets = players.where((f) => f.alive).toList()
      ..sort((a, b) => a.hp.compareTo(b.hp));
    // 60% das vezes mira na carta mais fraca, senão em uma aleatória.
    final target =
        _rng.nextDouble() < 0.6 ? targets.first : targets[_rng.nextInt(targets.length)];

    var special = enemyHype >= hypeCost && _rng.nextDouble() < 0.7;
    if (special && actor.card.specialType == 'heal') {
      special = enemies.any((f) => f.alive && f.hpRatio < 0.7);
    }

    _execute(actor, target, special: special);
    enemyHype = special ? enemyHype - hypeCost : min(hypeMax, enemyHype + 1);
    turn++;
  }

  int _damage(BattleFighter attacker, BattleFighter defender, double power, {bool pierce = false}) {
    final mult = elementMultiplier(attacker.card.element, defender.card.element);
    final variance = 0.85 + _rng.nextDouble() * 0.3;
    final raw = attacker.attack * power * mult * variance;
    final reduced = pierce ? raw : raw - defender.defense * 0.6;
    return max(1, reduced.round());
  }

  void _hit(BattleFighter target, int amount) {
    target.hp = max(0, target.hp - amount);
    target.lastDamage = amount;
    target.lastHeal = 0;
    lastAffected.add(target);
  }

  void _heal(BattleFighter target, int amount) {
    final healed = min(amount, target.maxHp - target.hp);
    target.hp += healed;
    target.lastHeal = healed;
    target.lastDamage = 0;
    lastAffected.add(target);
  }

  String _effectiveness(BattleFighter a, BattleFighter d) {
    final m = elementMultiplier(a.card.element, d.card.element);
    if (m >= 1.4) return ' É super efetivo!';
    if (m <= 0.8) return ' Pouco efetivo...';
    return '';
  }

  String _ko(BattleFighter target) => target.alive ? '' : ' ${target.name} foi nocauteado!';

  void _execute(BattleFighter actor, BattleFighter target, {required bool special}) {
    lastAffected = [];
    final allies = actor.isPlayer ? players : enemies;
    final foes = actor.isPlayer ? enemies : players;
    final card = actor.card;
    final power = card.specialPower / 100;

    if (!special) {
      final dmg = _damage(actor, target, 1.0);
      _hit(target, dmg);
      log.add('${actor.name} atacou ${target.name} (-$dmg).${_effectiveness(actor, target)}${_ko(target)}');
      return;
    }

    switch (card.specialType) {
      case 'heal':
        for (final ally in allies.where((f) => f.alive)) {
          _heal(ally, (ally.maxHp * card.specialPower / 100).round());
        }
        log.add('${actor.name} usou ${card.specialName}! O time recuperou vida.');
      case 'aoe':
        final hits = <String>[];
        for (final foe in foes.where((f) => f.alive)) {
          final dmg = _damage(actor, foe, power);
          _hit(foe, dmg);
          hits.add('${foe.name} -$dmg${_ko(foe)}');
        }
        log.add('${actor.name} usou ${card.specialName}! ${hits.join(', ')}');
      case 'drain':
        final dmg = _damage(actor, target, power);
        _hit(target, dmg);
        _heal(actor, dmg ~/ 2);
        log.add('${actor.name} usou ${card.specialName} em ${target.name} (-$dmg) e recuperou ${actor.lastHeal} de vida.${_ko(target)}');
      case 'stun':
        final dmg = _damage(actor, target, power);
        _hit(target, dmg);
        if (target.alive) target.stunned = true;
        log.add('${actor.name} usou ${card.specialName} em ${target.name} (-$dmg)${target.alive ? ' e atordoou!' : '.'}${_ko(target)}');
      case 'pierce':
        final dmg = _damage(actor, target, power, pierce: true);
        _hit(target, dmg);
        log.add('${actor.name} usou ${card.specialName} em ${target.name} (-$dmg, ignora defesa).${_ko(target)}');
      default:
        final dmg = _damage(actor, target, power);
        _hit(target, dmg);
        log.add('${actor.name} usou ${card.specialName} em ${target.name} (-$dmg).${_effectiveness(actor, target)}${_ko(target)}');
    }
  }
}
