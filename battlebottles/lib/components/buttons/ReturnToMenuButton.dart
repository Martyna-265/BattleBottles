import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';

import '../../screens/BattleShipsGame.dart';
import 'ConfirmationDialog.dart';

class ReturnToMenuButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  ReturnToMenuButton()
      : super(size: BattleShipsGame.squareSize * 3);

  final _backgroundPaint = Paint()..color = const Color(0xff003366);
  final _text = TextPaint(
    style: TextStyle(
      fontSize: 1.0,
      fontFamily: 'Awesome Font',
      color: Color(0xFFFFFFFF),
    ),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _backgroundPaint);
    _text.render(canvas, 'MENU', Vector2(0, 0));
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    game.world.add(ConfirmationDialog(
      message: 'Are you sure? Your progress will be lost',
      onConfirm: () {
        game.returnToMenu();
      },
    ));
  }
}