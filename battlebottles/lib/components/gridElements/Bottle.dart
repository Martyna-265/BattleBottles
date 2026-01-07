import 'dart:math';

import 'package:battlebottles/components/gridElements/Ship.dart';
import 'package:battlebottles/BattleShipsGame.dart';
import 'package:battlebottles/components/BattleGrid.dart';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:battlebottles/components/gridElements/GridElement.dart';

import '../../animations/ExplosionAnimation.dart';
import '../../services/AudioManager.dart';
import '../../services/StatsService.dart';
import 'Water.dart';

class Bottle extends GridElement with DragCallbacks {
  Bottle(super.gridX, super.gridY, int intSize, super.opponent, this.parentShip)
      : super(condition: Condition.fromInt(0)) {
    sprite = opponent ? Condition.fromInt(5).sprite : condition.sprite;
  }

  final Ship parentShip;
  late final BattleGrid battleGrid =
      opponent ? game.opponentsGrid : game.playersGrid;

  late Vector2 _positionDelta = Vector2(0, 0);
  late Vector2 _startPosition;
  final List<Bottle> _squad = [];
  final List<Vector2> _squadOriginalPositions = [];

  @override
  void onDragStart(DragStartEvent event) {
    if (game.turnManager.currentPlayer == 0 && !opponent) {
      super.onDragStart(event);
      priority = 200;

      _startPosition = position.clone();
      _positionDelta = Vector2.zero();

      _squad.clear();
      _squadOriginalPositions.clear();

      var currentPoints = parentShip.getOccupiedPoints();

      for (var p in currentPoints) {
        var element = battleGrid.grid[p.y][p.x];
        if (element is Bottle && element.parentShip == parentShip) {
          _squad.add(element);
          _squadOriginalPositions.add(element.position.clone());
          element.priority = 200;
        }
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.turnManager.currentPlayer == 0 && !opponent) {
      _positionDelta += event.localDelta;
      for (int i = 0; i < _squad.length; i++) {
        _squad[i].position = _squadOriginalPositions[i] + _positionDelta;
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_squad.isEmpty) return;

    int dx = ((position.x - _startPosition.x) / BattleShipsGame.squareLength)
        .round();
    int dy = ((position.y - _startPosition.y) / BattleShipsGame.squareLength)
        .round();

    int newHeadX = parentShip.x + dx;
    int newHeadY = parentShip.y + dy;

    bool canMove = true;
    List<Point<int>> newPoints = parentShip.type.relativePositions
        .map((p) => Point(newHeadX + p.x, newHeadY + p.y))
        .toList();

    for (var p in newPoints) {
      if (p.x < 0 ||
          p.x >= game.squaresInGrid ||
          p.y < 0 ||
          p.y >= game.squaresInGrid) {
        canMove = false;
        break;
      }

      var target = battleGrid.grid[p.y][p.x];
      if (target != null) {
        if (target is! Water) {
          if (target is Bottle && target.parentShip != parentShip) {
            canMove = false;
            break;
          }
        }
      }

      List<Point<int>> neighbors = [
        Point(p.x, p.y - 1),
        Point(p.x, p.y + 1),
        Point(p.x - 1, p.y),
        Point(p.x + 1, p.y),
      ];

      for (var n in neighbors) {
        if (n.x >= 0 &&
            n.x < game.squaresInGrid &&
            n.y >= 0 &&
            n.y < game.squaresInGrid) {
          var neighbor = battleGrid.grid[n.y][n.x];
          if (neighbor is Bottle && neighbor.parentShip != parentShip) {
            canMove = false;
            break;
          }
        }
      }
      if (!canMove) break;
    }

    if (canMove) {
      List<Point<int>> oldPoints = parentShip.getOccupiedPoints();
      for (var p in oldPoints) {
        if (battleGrid.grid[p.y][p.x] == null ||
            battleGrid.grid[p.y][p.x] is Bottle) {
          Water freshWater = Water(p.x, p.y, opponent);
          freshWater.position = Vector2(
            p.x * BattleShipsGame.squareLength,
            p.y * BattleShipsGame.squareLength,
          );
          battleGrid.add(freshWater);
          battleGrid.grid[p.y][p.x] = freshWater;
        }
      }

      parentShip.x = newHeadX;
      parentShip.y = newHeadY;

      for (var bottle in _squad) {
        int newGridX = bottle.gridX + dx;
        int newGridY = bottle.gridY + dy;

        var target = battleGrid.grid[newGridY][newGridX];
        if (target is Water) {
          battleGrid.remove(target);
        }

        battleGrid.grid[newGridY][newGridX] = bottle;

        bottle.position = Vector2(
          newGridX * BattleShipsGame.squareLength,
          newGridY * BattleShipsGame.squareLength,
        );

        bottle.gridX = newGridX;
        bottle.gridY = newGridY;
      }
    } else {
      for (int i = 0; i < _squad.length; i++) {
        _squad[i].position = _squadOriginalPositions[i];
      }
    }

    for (var b in _squad) {
      b.priority = 0;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (game.turnManager.currentPlayer == 0 && !opponent) {
      battleGrid.rotateShip(parentShip);
    }

    if (game.turnManager.currentPlayer != 0) {
      super.onTapUp(event);
    }
  }

  @override
  void bomb() {
    if (bombable) {
      condition = Condition.fromInt(condition.value + 1);

      if (condition.label == 'down' ||
          condition.label == 'water_down' ||
          condition.label == 'hurt') {
        bombable = false;
      }

      sprite = condition.sprite;

      if (!battleGrid.shipsHurt.contains(parentShip)) {
        battleGrid.shipsHurt.add(parentShip);
      }

      bool isSunk = true;
      List<Point<int>> shipPoints = parentShip.getOccupiedPoints();

      for (var p in shipPoints) {
        var element = battleGrid.grid[p.y][p.x];
        if (element is Bottle) {
          if (element.condition.value == 0) {
            isSunk = false;
            break;
          }
        }
      }

      bool isMyTurn = (game.turnManager.currentPlayer == 1);

      if (isSunk) {
        game.actionFeedback.setMessage("sink", !isMyTurn);
        AudioManager.playSink();
        sinkShip();
      } else {
        double scaledSquareSize = BattleShipsGame.squareLength * game.gridScale;
        Vector2 effectPos = Vector2(
          battleGrid.position.x + (gridX * scaledSquareSize),
          battleGrid.position.y + (gridY * scaledSquareSize),
        );

        game.world.add(
          ExplosionAnimation(
            targetPosition: effectPos,
            cellSize: scaledSquareSize,
          ),
        );
        AudioManager.playExplosion();
        game.actionFeedback.setMessage("hit", !isMyTurn);
      }
    }
  }

  void sinkShip() {
    List<Point<int>> shipPoints = parentShip.getOccupiedPoints();

    for (var p in shipPoints) {
      var element = battleGrid.grid[p.y][p.x];
      if (element is Bottle) {
        element.condition = Condition.fromInt(2);
        element.sprite = element.condition.sprite;
        element.bombable = false;

        double scaledSquareSize = BattleShipsGame.squareLength * game.gridScale;
        Vector2 effectPos = Vector2(
          battleGrid.position.x + (p.x * scaledSquareSize),
          battleGrid.position.y + (p.y * scaledSquareSize),
        );

        game.world.add(
          ExplosionAnimation(
            targetPosition: effectPos,
            cellSize: scaledSquareSize,
          ),
        );

        void markWaterAsHit(int x, int y) {
          if (x >= 0 &&
              x < game.squaresInGrid &&
              y >= 0 &&
              y < game.squaresInGrid) {
            var target = battleGrid.grid[y][x];
            if (target is Water && target.bombable) {
              target.condition = Condition.fromInt(4);
              target.sprite = target.condition.sprite;
              target.bombable = false;
            }
          }
        }

        markWaterAsHit(p.x - 1, p.y);
        markWaterAsHit(p.x + 1, p.y);
        markWaterAsHit(p.x, p.y - 1);
        markWaterAsHit(p.x, p.y + 1);
      }
    }

    if (battleGrid.shipsHurt.contains(parentShip)) {
      battleGrid.shipsHurt.remove(parentShip);
    }
    if (!battleGrid.shipsDown.contains(parentShip)) {
      battleGrid.shipsDown.add(parentShip);
    }

    StatsService().recordSinkedShip(battleGrid.opponent);

    game.checkWinner();
  }
}
