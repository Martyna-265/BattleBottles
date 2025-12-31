import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import '../../screens/BattleShipsGame.dart';

class RoundInfo extends PositionComponent with HasGameReference<BattleShipsGame> {
  RoundInfo()
      : super(size: Vector2(BattleShipsGame.squareLength * 7, BattleShipsGame.squareLength));

  final _backgroundPaint = Paint()..color = const Color(0xff003366);

  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.0,
      fontFamily: 'Awesome Font',
      color: Color(0xFFFFFFFF),
    ),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _backgroundPaint);

    String label = '';

    switch (game.visibleCurrentPlayer) {
      case -1:
        label = 'Waiting for opponent...';
        break;
      case 0:
        label = 'Set your bottles';
        break;
      case 1:
        label = 'Your move!';
        break;
      case 2:
        label = 'Opponent\'s move';
        break;
      default:
        label = '';
    }

    _textPaint.render(
      canvas,
      label,
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }
}