import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trap_rpg/game/battle_engine.dart';
import 'package:trap_rpg/models/trapper_card.dart';

TrapperCard _card(String id, String element, {String special = 'damage'}) => TrapperCard(
      id: id,
      name: id,
      title: 'Teste',
      element: element,
      rarity: 'comum',
      attack: 20,
      defense: 10,
      hp: 100,
      specialName: 'Especial',
      specialType: special,
      specialPower: 150,
      specialDesc: '',
      lore: '',
      isStarter: false,
    );

void main() {
  test('vantagem de elemento', () {
    expect(BattleEngine.elementMultiplier('fogo', 'gelo'), 1.4);
    expect(BattleEngine.elementMultiplier('gelo', 'fogo'), 0.8);
    expect(BattleEngine.elementMultiplier('luz', 'terra'), 1.0);
    expect(BattleEngine.elementMultiplier('cosmico', 'luz'), 1.15);
  });

  test('batalha sempre termina com um vencedor', () {
    for (var seed = 0; seed < 50; seed++) {
      final engine = BattleEngine.create(
        playerCards: [_card('a', 'fogo'), _card('b', 'terra', special: 'heal')],
        enemyCards: [_card('x', 'gelo', special: 'stun'), _card('y', 'vento', special: 'aoe')],
        playerLevel: 1,
        enemyLevel: 1,
        random: Random(seed),
      );
      var guard = 0;
      while (engine.outcome == null && guard++ < 500) {
        final actor = engine.firstReadyPlayer;
        if (actor == null) {
          engine.skipPlayerTurn();
        } else {
          engine.playerAction(actor, engine.firstAliveEnemy!,
              special: engine.playerCanUseSpecial);
        }
        engine.enemyTurn();
      }
      expect(engine.outcome, isNotNull, reason: 'seed $seed');
    }
  });

  test('cura não passa da vida máxima', () {
    final engine = BattleEngine.create(
      playerCards: [_card('a', 'terra', special: 'heal')],
      enemyCards: [_card('x', 'gelo')],
      playerLevel: 1,
      enemyLevel: 1,
      random: Random(1),
    );
    engine.playerHype = BattleEngine.hypeCost;
    final healer = engine.players.first;
    engine.playerAction(healer, engine.enemies.first, special: true);
    expect(healer.hp, healer.maxHp);
  });
}
