import 'package:battlebottles/BattleShipsGame.dart';
import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:battlebottles/components/GridElement.dart';

class Bottle extends GridElement with DragCallbacks{

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
    if(opponent && game.turnManager.currentPlayer == 1) {
      bomb();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    //if (game.turnManager.currentPlayer == 0 && !opponent) {
    if (game.turnManager.currentPlayer == -1 && !opponent) {
      super.onDragStart(event);
      priority = 200;
    }
    else {
      event.handled = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    //if (game.turnManager.currentPlayer == 0 && !opponent) {
    if (game.turnManager.currentPlayer == -1 && !opponent) {
      position += event.localDelta;
    }
  }

}