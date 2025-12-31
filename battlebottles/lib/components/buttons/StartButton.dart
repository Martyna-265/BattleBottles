import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import '../../screens/BattleShipsGame.dart';

class StartButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  StartButton()
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
    _text.render(canvas, 'START', Vector2(0, 0));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.turnManager.currentPlayer != 0) return;

    if (game.isMultiplayer){
      game.startGame();
    }
    else {
      game.startSingleplayerGame();
    }
  }
}