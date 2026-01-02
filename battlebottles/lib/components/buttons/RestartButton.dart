import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';

import '../../BattleShipsGame.dart';
import 'ConfirmationDialog.dart';

class RestartButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  RestartButton()
      : super(size: BattleShipsGame.squareSize * 3);

  final _backgroundPaint = Paint()..color = const Color(0xff003366);
  final _text = TextPaint(
    style: const TextStyle(
      fontSize: 1.0,
      fontFamily: 'Awesome Font',
      color: Color(0xFFFFFFFF),
    ),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _backgroundPaint);
    _text.render(canvas, 'RESTART', Vector2(0, 0));
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    game.world.add(ConfirmationDialog(
      message: 'Are you sure? Your progress will be lost',
      onConfirm: () {
        game.restartGame();
      },
    ));
  }
}