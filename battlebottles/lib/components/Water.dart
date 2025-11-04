import 'dart:ui';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:battlebottles/components/GridElement.dart';

class Water extends GridElement{

  Water(super.gridX, super.gridY)
      : super(condition: Condition.fromInt(3));

  late Sprite? sprite = condition.sprite;

  @override
  void onTapUp(TapUpEvent event) {
    if (condition.value < 4) {
      condition = Condition.fromInt(condition.value + 1);
      sprite = condition.sprite;
    }
  }

}