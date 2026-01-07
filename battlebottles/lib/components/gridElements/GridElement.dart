import 'dart:math';
import 'dart:ui';
import 'package:battlebottles/animations/SharkAnimation.dart';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:battlebottles/services/AudioManager.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../BattleShipsGame.dart';
import '../../animations/OctopusHeadAnimation.dart';
import '../../animations/TentacleAnimation.dart';
import '../bottleElements/PowerUpType.dart';
import 'Bottle.dart';
import 'Water.dart';

abstract class GridElement extends PositionComponent
    with HasGameReference<BattleShipsGame>, TapCallbacks {
  int gridX;
  int gridY;
  Condition condition;
  Sprite? sprite;
  bool bombable;
  final bool opponent;

  GridElement(this.gridX, this.gridY, this.opponent, {required this.condition})
    : bombable =
          (condition.label == 'down' ||
              condition.label == 'water_down' ||
              condition.label == 'hurt')
          ? false
          : true,
      super(size: BattleShipsGame.squareSize);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    sprite?.render(
      canvas,
      position: size / 2,
      anchor: Anchor.center,
      size: size * 0.95,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (game.turnManager.currentPlayer != 1) return;

    if (opponent) {
      if (game.tripleShotsLeft > 0) {
        if (!bombable) return;
        _handleTripleShotExecution();
        return;
      }

      if (game.activePowerUp != PowerUpType.none) {
        _handlePowerUpShot();
        return;
      }

      if (!bombable) return;

      if (game.isMultiplayer) {
        int index = gridY * game.squaresInGrid + gridX;
        game.sendMoveToFirebase(index);
      } else {
        bomb();
      }
    }
  }

  void _handlePowerUpShot() {
    switch (game.activePowerUp) {
      case PowerUpType.octopus:
        _handleOctopus();
        game.consumeActivePowerUp();
        break;

      case PowerUpType.triple:
        game.tripleShotsLeft = 3;
        game.consumeActivePowerUp();
        _handleTripleShotExecution();
        break;

      case PowerUpType.shark:
        _handleShark();
        game.consumeActivePowerUp();
        break;

      case PowerUpType.none:
        break;
    }
  }

  void _handleTripleShotExecution() {
    bool wasMultiplayer = game.isMultiplayer;
    game.isMultiplayer = true;

    bool hitFreshShip = false;

    if (this is Bottle && condition.value == 0) {
      hitFreshShip = true;
    }

    bomb();

    game.isMultiplayer = wasMultiplayer;

    int shotIndex = gridY * game.squaresInGrid + gridX;

    if (hitFreshShip) {
      game.actionFeedback.setMessage('hit', false, addition: "Bonus shot!");
      game.turnManager.currentPlayer = 1;

      if (wasMultiplayer) {
        game.sendPowerUpShots([shotIndex], true);
      }
    } else {
      game.tripleShotsLeft--;

      if (game.tripleShotsLeft > 0) {
        String shotsText = game.tripleShotsLeft == 1
            ? "shot left"
            : "shots left";
        game.actionFeedback.setMessage(
          'miss',
          false,
          addition: "${game.tripleShotsLeft} $shotsText",
        );
        game.turnManager.currentPlayer = 1;

        if (wasMultiplayer) {
          game.sendPowerUpShots([shotIndex], true);
        }
      } else {
        game.actionFeedback.setMessage('miss', false, addition: "Turn over");

        if (wasMultiplayer) {
          game.sendPowerUpShots([shotIndex], false);
        } else {
          game.turnManager.nextTurn();
        }
      }
    }
  }

  void _handleOctopus() {
    AudioManager.playMonster();
    Random random = Random();

    List<Point<int>> directions = [
      const Point(-1, -1),
      const Point(0, -1),
      const Point(1, -1),
      const Point(-1, 0),
      const Point(1, 0),
      const Point(-1, 1),
      const Point(0, 1),
      const Point(1, 1),
    ];

    int n = game.squaresInGrid;
    List<Point<int>> neighbors = [];

    for (var dir in directions) {
      int nx = gridX + dir.x;
      int ny = gridY + dir.y;
      if (nx >= 0 && nx < n && ny >= 0 && ny < n) {
        neighbors.add(Point(nx, ny));
      }
    }

    neighbors.shuffle(random);
    List<Point<int>> targets = neighbors.take(4).toList();
    targets.add(Point(gridX, gridY));

    double scaledSquareSize = BattleShipsGame.squareLength * game.gridScale;
    var targetGrid = opponent ? game.opponentsGrid : game.playersGrid;

    // Animation

    Vector2 headPos = Vector2(
      targetGrid.position.x + (gridX * scaledSquareSize),
      targetGrid.position.y + ((gridY - 0.3) * scaledSquareSize),
    );

    game.world.add(
      OctopusHeadAnimation(targetPosition: headPos, cellSize: scaledSquareSize),
    );

    for (var p in targets) {
      if (p.x == gridX && p.y == gridY) {
        continue;
      }
      Vector2 tentaclePos = Vector2(
        targetGrid.position.x + (p.x * scaledSquareSize),
        targetGrid.position.y + ((p.y - 0.3) * scaledSquareSize),
      );

      bool shouldFlip = p.x < gridX;

      game.world.add(
        TentacleAnimation(
          targetPosition: tentaclePos,
          cellSize: scaledSquareSize,
          flip: shouldFlip,
        ),
      );
    }

    // Animation end

    var gridRef = opponent ? game.opponentsGrid.grid : game.playersGrid.grid;
    bool hitAnyFreshShip = false;

    List<int> hitIndices = [];

    bool wasMultiplayer = game.isMultiplayer;
    game.isMultiplayer = true;

    for (var p in targets) {
      var element = gridRef[p.y][p.x];

      hitIndices.add(p.y * n + p.x);

      if (element != null) {
        if (element.bombable) {
          if (element is Bottle && element.condition.value == 0) {
            hitAnyFreshShip = true;
          }
          element.bomb();
        }
      }
    }

    game.isMultiplayer = wasMultiplayer;

    if (hitAnyFreshShip) {
      game.actionFeedback.setMessage("hit", false);
      game.turnManager.currentPlayer = 1;

      if (wasMultiplayer) {
        int centerIndex = gridY * game.squaresInGrid + gridX;
        game.sendSpecialEffect('octopus', centerIndex);
        game.sendPowerUpShots(hitIndices, true);
      }
    } else {
      // No new ships hit -> end of turn

      if (wasMultiplayer) {
        int centerIndex = gridY * game.squaresInGrid + gridX;
        game.sendSpecialEffect('octopus', centerIndex);
        game.sendPowerUpShots(hitIndices, false);
      } else {
        game.turnManager.nextTurn();
      }
    }
  }

  void _handleShark() {
    double scaledSquareSize = BattleShipsGame.squareLength * game.gridScale;
    var targetGrid = game.isNarrow ? game.opponentsGrid : game.playersGrid;
    double rowWorldY = targetGrid.position.y + (gridY * scaledSquareSize);

    double gameWorldWidth = game.isNarrow
        ? game.scaledGridWidth + 10.0
        : (game.scaledGridWidth * 2) + BattleShipsGame.gap + 10.0;

    final shark = SharkAnimation(
      targetY: rowWorldY,
      worldWidth: gameWorldWidth,
      cellSize: scaledSquareSize,
    );

    game.world.add(shark);

    AudioManager.playMonster();
    int n = game.squaresInGrid;

    var enemyGrid = game.opponentsGrid.grid;
    var myGrid = game.playersGrid.grid;

    bool hitAnyFreshOpponentShip = false;

    bool wasMultiplayer = game.isMultiplayer;
    game.isMultiplayer = true;

    for (int x = 0; x < n; x++) {
      var enemyElement = enemyGrid[gridY][x];
      if (enemyElement != null && enemyElement.bombable) {
        if (enemyElement is Bottle && enemyElement.condition.value == 0) {
          hitAnyFreshOpponentShip = true;
        }
        enemyElement.bomb();
      }

      var myElement = myGrid[gridY][x];
      if (myElement != null && myElement.bombable) {
        myElement.bomb();
      }
    }

    game.isMultiplayer = wasMultiplayer;

    if (hitAnyFreshOpponentShip) {
      game.actionFeedback.setMessage("hit", false, addition: "Shark Bonus!");
      game.turnManager.currentPlayer = 1;

      if (wasMultiplayer) {
        game.sendSpecialEffect('shark', gridY);
        game.sendSharkAttack(gridY, true);
      }
    } else {
      game.actionFeedback.setMessage(
        "miss",
        false,
        addition: "Shark attack end",
      );

      if (wasMultiplayer) {
        game.sendSpecialEffect('shark', gridY);
        game.sendSharkAttack(gridY, false);
      } else {
        game.turnManager.nextTurn();
      }
    }
  }

  void bomb() {
    if (bombable) {
      condition = Condition.fromInt(condition.value + 1);
      if (condition.label == 'down' ||
          condition.label == 'water_down' ||
          condition.label == 'hurt') {
        bombable = false;
      }
      sprite = condition.sprite;

      if (!game.isMultiplayer) {
        if (this is Water) {
          game.turnManager.nextTurn();
        }
      }
    }
  }
}
