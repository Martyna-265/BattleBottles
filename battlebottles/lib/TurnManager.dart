import 'dart:math';
import 'package:battlebottles/screens/BattleShipsGame.dart';
import 'package:battlebottles/components/GridElement.dart';

class TurnManager {
  int _currentPlayer = 0;
  final int totalPlayers;
  final BattleShipsGame game;

  TurnManager(this.totalPlayers, this.game);

  int get currentPlayer => _currentPlayer;

  Future<void> nextTurn() async {
    _currentPlayer++;
    if (_currentPlayer > totalPlayers) _currentPlayer = 1;

    await Future.delayed(Duration(seconds: BattleShipsGame.delay));

    game.updateView();

    if (_currentPlayer == 2) {
      _opponentsTurn();
    }
  }

  Future<void> _opponentsTurn() async {
    await Future.delayed(const Duration(seconds: 1));

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

  void reset() {
    _currentPlayer = 0;
  }
}