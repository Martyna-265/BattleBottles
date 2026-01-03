import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import '../../BattleShipsGame.dart';
import '../../services/AudioManager.dart';
import 'ConfirmationDialog.dart';

class ReturnToMenuButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  ReturnToMenuButton() : super(size: Vector2(6, 2.5));

  final Paint _bgPaint = Paint()..color = const Color(0xFFD32F2F);
  final Paint _shadowPaint = Paint()..color = const Color(0xFFB71C1C);

  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.0,
      fontFamily: 'Awesome Font',
      color: Color(0xFFFFFFFF),
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0.2, size.x, size.y), const Radius.circular(10)),
        _shadowPaint
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10)),
        _bgPaint
    );
    _textPaint.render(canvas, 'MENU', Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    AudioManager.playClick();
    game.world.add(ConfirmationDialog(
      message: 'Return to Menu?',
      onConfirm: () { game.returnToMenu(); },
    ));
  }
}