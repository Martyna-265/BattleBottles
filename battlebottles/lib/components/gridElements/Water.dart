import 'package:battlebottles/components/bottleElements/Condition.dart';
import 'package:battlebottles/components/gridElements/GridElement.dart';
import 'package:flame/components.dart';

import '../../BattleShipsGame.dart';
import '../../animations/SplashAnimation.dart';
import '../../services/AudioManager.dart';

class Water extends GridElement {
  Water(super.gridX, super.gridY, super.opponent)
      : super(condition: Condition.fromInt(3)) {
    sprite = opponent ? Condition.fromInt(5).sprite : condition.sprite;
  }

  @override
  void bomb() {
    if (bombable) {
      var targetGrid = opponent ? game.opponentsGrid : game.playersGrid;
      double scaledSquareSize = BattleShipsGame.squareLength * game.gridScale;

      Vector2 effectPos = Vector2(
        targetGrid.position.x + (gridX * scaledSquareSize),
        targetGrid.position.y + (gridY * scaledSquareSize),
      );

      game.world.add(
        SplashAnimation(targetPosition: effectPos, cellSize: scaledSquareSize),
      );

      bool isMyTurn = (game.turnManager.currentPlayer == 1);
      game.actionFeedback.setMessage("miss", !isMyTurn);
      AudioManager.playSplash();

      super.bomb();
    }
  }
}
