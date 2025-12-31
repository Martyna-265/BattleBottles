import 'dart:ui';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../screens/BattleShipsGame.dart';

abstract class GridElement extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks{
  final int gridX;
  final int gridY;
  Condition condition;
  Sprite? sprite;
  bool bombable;

  GridElement(this.gridX, this.gridY, {required Condition condition})
      : condition = condition,
        bombable = (condition.label == 'down' || condition.label == 'water_down') ? false : true,
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

  void bomb() {
    if (bombable) {
      condition = Condition.fromInt(condition.value + 1);
      if (condition.label == 'down' || condition.label == 'water_down') {
        bombable = false;
      }
      sprite = condition.sprite;
      game.turnManager.nextTurn();
    }
  }

}
