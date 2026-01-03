import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import '../../BattleShipsGame.dart';

class PowerUpButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  final String imageName;
  final String typeKey;
  int count;
  final VoidCallback onTapAction;

  PowerUpButton({
    required this.imageName,
    required this.typeKey,
    required this.count,
    required this.onTapAction,
  }) : super(size: Vector2(3.0, 3.0));

  late Sprite _sprite;
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.1;

  final Paint _bgPaint = Paint()..color = const Color(0x88000000);
  final Paint _badgePaint = Paint()..color = const Color(0xfffad220);

  final TextPaint _counterTextPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.0,
      color: Color(0xFFFFFFFF),
      fontWeight: FontWeight.bold,
      fontFamily: 'Awesome Font',
    ),
  );

  @override
  Future<void> onLoad() async {
    _sprite = await Sprite.load(imageName);
  }

  @override
  void render(Canvas canvas) {
    double radius = size.x / 2;
    canvas.drawCircle(Offset(radius, radius), radius, _bgPaint);

    _sprite.render(
      canvas,
      position: size / 2,
      anchor: Anchor.center,
      size: size * 0.7,
    );

    canvas.drawCircle(Offset(radius, radius), radius, _borderPaint);

    // Badge
    canvas.drawCircle(Offset(size.x - 0.5, 0.5), 0.7, _badgePaint);

    // Liczba
    _counterTextPaint.render(
      canvas,
      count.toString(),
      Vector2(size.x - 0.5, 0.5),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (count > 0) {
      onTapAction();
    }
  }

  void decrement() {
    if (count > 0) count--;
  }
}