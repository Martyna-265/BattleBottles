import 'dart:ui';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:battlebottles/components/GridElement.dart';

class Bottle extends GridElement{

  Bottle(super.gridX, super.gridY, int intSize, bool opponent)
      : //condition = Condition.fromInt(intCondition),
        opponent = opponent,
        super(condition: Condition.fromInt(0));

  //final Size/Level size;
  final bool opponent;
  late Sprite? sprite = opponent ? Condition.fromInt(3).sprite : condition.sprite;

  @override
  String toString() {
    return "Bottle with condition " + condition.label;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (condition.value < 2) {
      condition = Condition.fromInt(condition.value + 1);
      sprite = condition.sprite;
    }
  }

}