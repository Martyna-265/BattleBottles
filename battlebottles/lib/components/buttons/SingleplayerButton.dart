import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import '../../screens/BattleShipsGame.dart';

class PlaySingleButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  PlaySingleButton() : super(size: Vector2(200, 60));

  final _backgroundPaint = Paint()..color = const Color(0xff4CAF50);
  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 24.0,
      color: Color(0xFFFFFFFF),
      fontFamily: 'Awesome Font',
    ),
  );

  @override
  void render(Canvas canvas) {
    RRect rrect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10));
    canvas.drawRRect(rrect, _backgroundPaint);

    _textPaint.render(
      canvas,
      'SINGLEPLAYER',
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.startGame();
  }
}