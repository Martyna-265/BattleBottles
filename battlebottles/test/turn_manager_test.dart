// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:battlebottles/TurnManager.dart';
import 'package:battlebottles/BattleShipsGame.dart';

class FakeBattleShipsGame extends Fake implements BattleShipsGame {
  @override
  int get squaresInGrid => 10;

  @override
  bool isMultiplayer = false;
}

void main() {
  group('TurnManager Tests', () {
    test('reset() should set currentPlayer to 0', () {
      final game = FakeBattleShipsGame();
      final turnManager = TurnManager(2, game);

      turnManager.currentPlayer = 1;

      turnManager.reset();

      expect(turnManager.currentPlayer, 0);
    });

    test('nextTurn() should not change turns when game is in multiplayer', () {
      final fakeGame = FakeBattleShipsGame();

      fakeGame.isMultiplayer = true;
      final turnManager = TurnManager(2, fakeGame);
      turnManager.currentPlayer = 1;

      turnManager.nextTurn();

      expect(turnManager.currentPlayer, 1);
    });
  });
}
