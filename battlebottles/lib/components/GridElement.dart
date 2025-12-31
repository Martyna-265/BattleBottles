import 'dart:ui';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../screens/BattleShipsGame.dart';

abstract class GridElement extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  final int gridX;
  final int gridY;
  Condition condition;
  Sprite? sprite;
  bool bombable;
  final bool opponent;

  GridElement(this.gridX, this.gridY, this.opponent, {required Condition condition})
      : condition = condition,
        //bombable = (condition.label == 'down' || condition.label == 'water_down') ? false : true,
        bombable = (condition.label == 'down' || condition.label == 'water_down' || condition.label == 'hurt') ? false : true,
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
    // Blokada, gdy nie jest to tura gracza
    if (game.turnManager.currentPlayer != 1) return;

    if (opponent) { // Strzelamy tylko w grid przeciwnika
      if (!bombable) return;

      if (game.isMultiplayer) {
        int index = gridY * BattleShipsGame.squaresInGrid + gridX;
        game.sendMoveToFirebase(index);
      } else {
        bomb();
      }
    }
  }

  void bomb() {
    if (bombable) {
      condition = Condition.fromInt(condition.value + 1);

      //if (condition.label == 'down' || condition.label == 'water_down') {
      if (condition.label == 'down' || condition.label == 'water_down' || condition.label == 'hurt') {
        bombable = false;
      }

      sprite = condition.sprite;

      if (!game.isMultiplayer) {
        game.turnManager.nextTurn();
      }
    }
  }
}