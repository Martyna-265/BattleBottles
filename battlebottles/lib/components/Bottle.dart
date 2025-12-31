import 'package:battlebottles/screens/BattleShipsGame.dart';
import 'package:battlebottles/components/BattleGrid.dart';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:battlebottles/components/GridElement.dart';

class Bottle extends GridElement with DragCallbacks{

  Bottle(super.gridX, super.gridY, int intSize, super.opponent)
      : //condition = Condition.fromInt(intCondition),
        super(condition: Condition.fromInt(0));

  //final Size/Level size;
  late final BattleGrid battleGrid = opponent ? game.opponentsGrid : game.playersGrid;
  late Sprite? sprite = opponent ? Condition.fromInt(3).sprite : condition.sprite;
  late Vector2 _positionDelta = Vector2(0, 0);
  late Vector2 _lastPosition = position;

  @override
  String toString() {
    return "Bottle with condition " + condition.label;
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (game.turnManager.currentPlayer == 0 && !opponent) {
      _lastPosition = position.clone();
      super.onDragStart(event);
      priority = 200;
    }
    else {
      event.handled = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.turnManager.currentPlayer == 0 && !opponent) {
      _positionDelta += event.localDelta;
      if (position.x > 0 && _positionDelta.x < -BattleShipsGame.squareLength) {
        position.x -= BattleShipsGame.squareLength;
        _positionDelta.x += BattleShipsGame.squareLength;
      }
      if (position.x < BattleShipsGame.battleGridWidth-BattleShipsGame.squareLength
          && _positionDelta.x > BattleShipsGame.squareLength) {
        position.x += BattleShipsGame.squareLength;
        _positionDelta.x -= BattleShipsGame.squareLength;
      }
      if (position.y > 0 && _positionDelta.y < -BattleShipsGame.squareLength) {
        position.y -= BattleShipsGame.squareLength;
        _positionDelta.y += BattleShipsGame.squareLength;
      }
      if (position.y < BattleShipsGame.battleGridHeight-BattleShipsGame.squareLength
          && _positionDelta.y > BattleShipsGame.squareLength) {
        position.y += BattleShipsGame.squareLength;
        _positionDelta.y -= BattleShipsGame.squareLength;
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    int newX = (position.x ~/ BattleShipsGame.squareLength);
    int newY = (position.y ~/ BattleShipsGame.squareLength);
    int oldX = (_lastPosition.x ~/ BattleShipsGame.squareLength);
    int oldY = (_lastPosition.y ~/ BattleShipsGame.squareLength);

    if (newX < 0 || newY < 0 ||
        newX >= BattleShipsGame.squaresInGrid ||
        newY >= BattleShipsGame.squaresInGrid) {
      position = _lastPosition;
      return;
    }

    GridElement? target = battleGrid.grid[newY][newX];

    if (target != null && target != this) {
      battleGrid.grid[newY][newX] = this;
      battleGrid.grid[oldY][oldX] = target;

      target.position = Vector2(
        oldX * BattleShipsGame.squareLength,
        oldY * BattleShipsGame.squareLength,
      );

      position = Vector2(
        newX * BattleShipsGame.squareLength,
        newY * BattleShipsGame.squareLength,
      );
    } else {
      position = _lastPosition;
    }

    priority = 0;
  }

}