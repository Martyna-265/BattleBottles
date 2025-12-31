import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:battlebottles/components/GridElement.dart';

class Water extends GridElement {

  Water(super.gridX, super.gridY, super.opponent)
      : super(condition: Condition.fromInt(3));

  late Sprite? sprite = condition.sprite;

}