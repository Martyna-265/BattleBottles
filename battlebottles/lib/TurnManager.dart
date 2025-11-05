import 'dart:math';

import 'package:battlebottles/BattleShipsGame.dart';

import 'components/GridElement.dart';

class TurnManager {
  int _currentPlayer = 0;
  final int totalPlayers;
  final BattleShipsGame game;

  TurnManager(this.totalPlayers, this.game);

  int get currentPlayer => _currentPlayer;

  Future<void> nextTurn() async {
    _currentPlayer++;
    if (_currentPlayer > totalPlayers) _currentPlayer = 1;
    if (_currentPlayer == 2) {
      await Future.delayed(const Duration(seconds: 1));
      _opponentsTurn();
    }
  }

  void _opponentsTurn() {
    List<List<GridElement?>> grid = game.playersGrid.grid;
    int n = BattleShipsGame.squaresInGrid;

    Random random = Random();
    int i = random.nextInt(n);
    int j = random.nextInt(n);
    while (!grid[i][j]!.bombable) {
      i = random.nextInt(n);
      j = random.nextInt(n);
    }
    grid[i][j]!.bomb();
  }

}
