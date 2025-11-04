import 'dart:ui';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../BattleShipsGame.dart';

abstract class GridElement extends PositionComponent with TapCallbacks{
  final int gridX;
  final int gridY;
  Condition condition;
  Sprite? sprite;

  GridElement(this.gridX, this.gridY, {required Condition condition})
      : condition = condition,
        super(size: BattleShipsGame.squareSize);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    sprite?.render(
      canvas,
      position: size / 2,
      anchor: Anchor.center,
      size: size * 0.99,
    );
  }

}
