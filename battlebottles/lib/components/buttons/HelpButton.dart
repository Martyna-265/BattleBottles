import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import '../../BattleShipsGame.dart';

class HelpButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {

  static const double _baseFontSize = 60.0;

  HelpButton({double sideLength = 30.0})
      : super(size: Vector2(sideLength, sideLength)) {

    _textPaint = TextPaint(
      style: const TextStyle(
        fontSize: _baseFontSize,
        fontFamily: 'Awesome Font',
        color: Color(0xFFFFFFFF),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  final _bgPaint = Paint()..color = const Color(0xff004488);
  final _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  late final TextPaint _textPaint;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _bgPaint);
    _borderPaint.strokeWidth = size.x * 0.06;
    canvas.drawRect(size.toRect(), _borderPaint);
    double scaleFactor = (size.y * 0.6) / _baseFontSize;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scaleFactor);

    _textPaint.render(
      canvas,
      '?',
      Vector2.zero(),
      anchor: Anchor.center,
    );

    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.overlays.add('HelpScreen');
  }
}