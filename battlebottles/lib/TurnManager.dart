import 'dart:math';
import 'package:battlebottles/screens/BattleShipsGame.dart';
import 'package:battlebottles/components/GridElement.dart';

class TurnManager {
  int _currentPlayer = 0; // 0=Setup, 1=Player, 2=Enemy, -1=Waiting

  final int totalPlayers;
  final BattleShipsGame game;

  bool hasShipsSynced = false;

  TurnManager(this.totalPlayers, this.game);

  int get currentPlayer => _currentPlayer;

  set currentPlayer(int value) {
    _currentPlayer = value;
  }

  Future<void> nextTurn() async {
    if (game.isMultiplayer) return;

    int nextPlayer = (_currentPlayer == 1) ? 2 : 1;

    _currentPlayer = -1;

    await Future.delayed(Duration(seconds: BattleShipsGame.delay));

    if (!game.isGameRunning) return;

    _currentPlayer = nextPlayer;
    game.updateView();

    if (_currentPlayer == 2) {
      _opponentsTurn();
    }
  }

  Future<void> _opponentsTurn() async {
    // Symulacja myślenia komputera
    await Future.delayed(const Duration(seconds: 1));

    if (!game.isGameRunning) return;

    List<List<GridElement?>> grid = game.playersGrid.grid;
    int n = BattleShipsGame.squaresInGrid;
    Random random = Random();

    int i = random.nextInt(n);
    int j = random.nextInt(n);
    int tries = 0;

    while ((grid[i][j] == null || !grid[i][j]!.bombable) && tries < 100) {
      i = random.nextInt(n);
      j = random.nextInt(n);
      tries++;
    }

    if (grid[i][j] != null && grid[i][j]!.bombable) {
      grid[i][j]!.bomb();
    } else {
      game.turnManager.nextTurn();
    }
  }

  void reset() {
    _currentPlayer = 0;
    hasShipsSynced = false;
  }
}