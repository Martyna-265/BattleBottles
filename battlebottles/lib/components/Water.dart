import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:battlebottles/components/GridElement.dart';

class Water extends GridElement {

  Water(super.gridX, super.gridY, bool opponent)
      : opponent = opponent,
        super(condition: Condition.fromInt(3));

  final bool opponent;
  late Sprite? sprite = condition.sprite;

  @override
  void onTapUp(TapUpEvent event) {
    if(opponent && game.turnManager.currentPlayer == 1) {
      bomb();
    }
  }

}