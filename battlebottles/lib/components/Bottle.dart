import 'dart:ui';
import 'package:battlebottles/BattleShipsGame.dart';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';

class Bottle extends PositionComponent{

  Bottle(int intSize)
      : //condition = Condition.fromInt(intCondition),
        condition = Condition.fromInt(0),
        super(size: BattleShipsGame.bottleSize);

  //final Size/Level size;
  final Condition condition;

  @override
  String toString() {
    return "Bottle with condition " + condition.label;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Sprite sprite = condition.sprite;
    sprite.render(
        canvas,
        position: size / 2,
        anchor: Anchor.center,
        size: size,
      );
  }

}