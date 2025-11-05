import 'dart:ui';

import 'package:battlebottles/TurnManager.dart';
import 'package:battlebottles/components/BattleGrid.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';

import 'components/Buttons/StartButton.dart';

class BattleShipsGame extends FlameGame {

  static const double squareLength = 2.0;
  static final Vector2 squareSize = Vector2(squareLength, squareLength);
  static const int squaresInGrid = 9;
  static const double battleGridWidth = squaresInGrid * squareLength;
  static const double battleGridHeight = squaresInGrid * squareLength;
  static final Vector2 battleGridSize = Vector2(battleGridWidth, battleGridHeight);
  static const double gap = 10.0;

  static const bottleCount = 10;

  late TurnManager turnManager;
  late BattleGrid playersGrid;
  late BattleGrid opponentsGrid;

  @override
  Color backgroundColor() => const Color(0xff84afdb);

  @override
  Future<void> onLoad() async {
    await Flame.images.load('Bottle1x1.png');
    turnManager = TurnManager(2, this);

    playersGrid = BattleGrid(false, bottleCount)
    ..size = battleGridSize
    ..position = Vector2(gap, gap);
    opponentsGrid = BattleGrid(true, bottleCount)
      ..size = battleGridSize
      ..position = Vector2(gap + battleGridWidth + gap, gap);

    world.add(playersGrid);
    world.add(opponentsGrid);

    final startButton = StartButton()
      ..position = Vector2(battleGridWidth + gap, gap / 2)
      ..anchor = Anchor.center;
    world.add(startButton);

    camera.viewfinder.visibleGameSize =
        Vector2(battleGridWidth + 2 * gap, battleGridHeight + 2 * gap);
    camera.viewfinder.position = Vector2(battleGridWidth + gap + gap/2, 0);
    camera.viewfinder.anchor = Anchor.topCenter;

  }

}