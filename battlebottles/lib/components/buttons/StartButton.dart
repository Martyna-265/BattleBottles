import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import '../../BattleShipsGame.dart';
import '../../services/AudioManager.dart';

class StartButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  StartButton() : super(size: Vector2(6, 2.5));

  final Paint _bgPaint = Paint()..color = const Color(0xFF4CAF50);
  final Paint _shadowPaint = Paint()..color = const Color(0xFF2E7D32);

  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.2,
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

    _textPaint.render(canvas, 'START', Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent event) {
    AudioManager.playClick();
    if (game.turnManager.currentPlayer != 0) return;
    if (game.isMultiplayer){
      game.confirmMultiplayerShips();
    } else {
      game.startSingleplayerGame();
    }
  }
}