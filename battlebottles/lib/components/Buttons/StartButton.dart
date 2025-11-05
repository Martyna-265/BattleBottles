import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';

import '../../BattleShipsGame.dart';

class StartButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  StartButton()
      : super(size: BattleShipsGame.squareSize * 3);

  final _backgroundPaint = Paint()..color = const Color(0xff003366);
  final _text = TextPaint(
    style: TextStyle(
      fontSize: 1.0,
      fontFamily: 'Awesome Font',
    ),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _backgroundPaint);
    _text.render(canvas, 'START', Vector2(0, 0));
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.turnManager.nextTurn();
    this.removeFromParent();
  }
}