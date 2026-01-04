import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import '../../BattleShipsGame.dart';

class RoundInfo extends PositionComponent with HasGameReference<BattleShipsGame> {
  RoundInfo()
      : super(size: Vector2(BattleShipsGame.squareLength * 7, BattleShipsGame.squareLength));

  final _backgroundPaint = Paint()..color = const Color(0xff003366);
  final _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

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
    RRect rrect = RRect.fromRectAndRadius(
        size.toRect(),
        const Radius.circular(0.4)
    );

    canvas.drawRRect(rrect, _backgroundPaint);
    canvas.drawRRect(rrect, _borderPaint);

    String label = '';

    switch (game.visibleCurrentPlayer) {
      case -1:
        label = 'Waiting...';
        break;
      case 0:
        label = 'Deploy Fleet';
        break;
      case 1:
        label = 'Your Turn';
        break;
      case 2:
        label = 'Enemy Turn';
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