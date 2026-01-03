import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:battlebottles/components/gridElements/GridElement.dart';

class Water extends GridElement {

  Water(super.gridX, super.gridY, super.opponent)
      : super(condition: Condition.fromInt(3)) {
    sprite = condition.sprite;
  }

  @override
  void bomb() {
    if (bombable) {
      bool isMyTurn = (game.turnManager.currentPlayer == 1);
      game.actionFeedback.setMessage("miss", !isMyTurn);

      super.bomb();
    }
  }

}