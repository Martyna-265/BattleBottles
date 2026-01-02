import 'dart:math';
import 'package:battlebottles/screens/BattleShipsGame.dart';
import 'package:battlebottles/components/gridElements/GridElement.dart';

import 'components/gridElements/Bottle.dart';
import 'components/gridElements/Ship.dart';

class TurnManager {
  int currentPlayer = 0; // 0=Setup, 1=Player, 2=Enemy, -1=Waiting

  final int totalPlayers;
  final BattleShipsGame game;

  bool hasShipsSynced = false;

  final List<Point<int>> _availableMoves = [];

  TurnManager(this.totalPlayers, this.game) {
    _resetAvailableMoves();
  }

  void _resetAvailableMoves() {
    _availableMoves.clear();
    for (int y = 0; y < BattleShipsGame.squaresInGrid; y++) {
      for (int x = 0; x < BattleShipsGame.squaresInGrid; x++) {
        _availableMoves.add(Point(x, y));
      }
    }
  }

  Future<void> nextTurn() async {
    if (game.isMultiplayer) return;

    int nextPlayer = (currentPlayer == 1) ? 2 : 1;

    currentPlayer = -1;

    await Future.delayed(Duration(seconds: BattleShipsGame.delay));

    if (!game.isGameRunning) return;

    currentPlayer = nextPlayer;
    game.updateView();

    if (currentPlayer == 2) {
      _opponentsTurn();
    }
  }

  Future<void> _opponentsTurn() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!game.isGameRunning) return;

    List<List<GridElement?>> grid = game.playersGrid.grid;
    int n = BattleShipsGame.squaresInGrid;
    Random random = Random();

    List<Ship> shipsHurt = game.playersGrid.shipsHurt;

    int targetX = -1;
    int targetY = -1;

    // Gdy jest jakiś zraniony statek
    if (shipsHurt.isNotEmpty) {
      Ship ship = shipsHurt.first;
      List<Point<int>> hitParts = [];
      for (var p in ship.getOccupiedPoints()) {
        if (p.x >= 0 && p.x < n && p.y >= 0 && p.y < n) {
          var element = grid[p.y][p.x];
          if (element is Bottle && element.condition.value == 1) {
            hitParts.add(Point(element.gridX, element.gridY));
          }
        }
      }

      List<Point<int>> candidates = [];
      for (var part in hitParts) {
        candidates.add(Point(part.x, part.y - 1));
        candidates.add(Point(part.x, part.y + 1));
        candidates.add(Point(part.x - 1, part.y));
        candidates.add(Point(part.x + 1, part.y));
      }

      List<Point<int>> validCandidates = [];
      for (var c in candidates) {
        if (c.x >= 0 && c.x < n && c.y >= 0 && c.y < n) {
          if (grid[c.y][c.x] != null && grid[c.y][c.x]!.bombable) {
            if (!validCandidates.any((vc) => vc.x == c.x && vc.y == c.y)) {
              validCandidates.add(c);
            }
          }
        }
      }

      if (validCandidates.isNotEmpty) {
        var chosen = validCandidates[random.nextInt(validCandidates.length)];
        targetX = chosen.x;
        targetY = chosen.y;
      }
    }

    // Gdy nie ma zranionego statku - losujemy
    if (targetX == -1) {
      while (targetX == -1 && _availableMoves.isNotEmpty) {
        int index = random.nextInt(_availableMoves.length);
        Point<int> move = _availableMoves[index];

        _availableMoves.removeAt(index);

        if (grid[move.y][move.x] != null && grid[move.y][move.x]!.bombable) {
          targetX = move.x;
          targetY = move.y;
        }
      }
    }

    // Wykonanie strzału
    if (targetX != -1 && targetY != -1) {
      _availableMoves.remove(Point(targetX, targetY));

      var targetElement = grid[targetY][targetX]!;
      targetElement.bomb();

      if (targetElement is Bottle) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (game.isGameRunning && currentPlayer == 2) {
          _opponentsTurn();
        }
      }
    } else {
      game.turnManager.nextTurn();
    }
  }

  void reset() {
    currentPlayer = 0;
    hasShipsSynced = false;
    _resetAvailableMoves();
  }
}