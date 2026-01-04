import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../../BattleShipsGame.dart';
import '../../services/AudioManager.dart';

class SoundButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {

  SoundButton({double sideLength = 30.0})
      : super(size: Vector2(sideLength, sideLength));

  final Paint _bgPaint = Paint()..color = const Color(0xff004488);
  final Paint _iconPaint = Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.fill;

  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke;

  final Paint _crossPaint = Paint()
    ..color = const Color(0xFFE53935)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    double radius = size.x / 2;
    Offset center = Offset(radius, radius);

    canvas.drawCircle(center, radius, _bgPaint);

    _borderPaint.strokeWidth = size.x * 0.05;
    canvas.drawCircle(center, radius, _borderPaint);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    double scale = size.x * 0.03;
    canvas.scale(scale);

    Path speakerPath = Path();
    speakerPath.moveTo(-6, -4);
    speakerPath.lineTo(-2, -4);
    speakerPath.lineTo(4, -8);
    speakerPath.lineTo(4, 8);
    speakerPath.lineTo(-2, 4);
    speakerPath.lineTo(-6, 4);
    speakerPath.close();
    canvas.drawPath(speakerPath, _iconPaint);

    if (AudioManager.sfxOn) {
      Paint wavePaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(const Rect.fromLTWH(-4, -6, 12, 12), -0.7, 1.4, false, wavePaint);
      canvas.drawArc(const Rect.fromLTWH(-4, -8, 16, 16), -0.7, 1.4, false, wavePaint);
    }

    if (!AudioManager.sfxOn) {
      _crossPaint.strokeWidth = 3;
      canvas.drawLine(const Offset(-8, -8), const Offset(8, 8), _crossPaint);
    }

    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    AudioManager.toggleSound();
  }
}