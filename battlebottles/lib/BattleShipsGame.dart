import 'dart:math';
import 'dart:ui';

import 'package:battlebottles/components/BattleGrid.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';

import 'components/Bottle.dart';

class BattleShipsGame extends FlameGame {

  static const double squareLength = 2.0;
  static final Vector2 squareSize = Vector2(squareLength, squareLength);
  static const int squaresInGrid = 9;
  static const double battleGridWidth = squaresInGrid * squareLength;
  static const double battleGridHeight = squaresInGrid * squareLength;
  static final Vector2 battleGridSize = Vector2(battleGridWidth, battleGridHeight);
  static const double gap = 10.0;

  @override
  Color backgroundColor() => const Color(0xff84afdb);


  @override
  Future<void> onLoad() async {
    await Flame.images.load('Bottle1x1.png');

    final BattleGrid playersGrid = BattleGrid(false)
    ..size = battleGridSize
    ..position = Vector2(gap, gap);
    final BattleGrid opponentsGrid = BattleGrid(true)
      ..size = battleGridSize
      ..position = Vector2(gap + battleGridWidth + gap, gap);

    world.add(playersGrid);
    world.add(opponentsGrid);

    camera.viewfinder.visibleGameSize =
        Vector2(battleGridWidth + 2 * gap, battleGridHeight + 2 * gap);
    camera.viewfinder.position = Vector2(battleGridWidth + gap + gap/2, 0);
    camera.viewfinder.anchor = Anchor.topCenter;

    // final random = Random();
    // for (var i = 0; i < 7; i++) {
    //     final bottle = Bottle(1)
    //       ..position = opponentsGrid.position +
    //           Vector2(random.nextInt(squaresInGrid) * squareLength, random.nextInt(squaresInGrid) * squareLength)
    //       ..addToParent(world);
    //     print(bottle.position);
    // }

  }

}