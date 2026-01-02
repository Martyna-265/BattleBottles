import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import '../../BattleShipsGame.dart';

class DialogButton extends PositionComponent with TapCallbacks {
  final String text;
  final VoidCallback onTapAction;
  final Color color;

  DialogButton(this.text, this.color, this.onTapAction)
      : super(size: Vector2(6, 2.5));

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = color);

    TextPaint(
      style: const TextStyle(
        fontSize: 0.8,
        color: Color(0xFFFFFFFF),
        fontFamily: 'Awesome Font',
      ),
    ).render(
        canvas,
        text,
        Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapAction();
    event.handled = true;
  }
}

class ConfirmationDialog extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {
  final String message;
  final VoidCallback onConfirm;

  final Vector2 _boxSize = Vector2(20, 8);

  ConfirmationDialog({
    required this.message,
    required this.onConfirm,
  });

  final _overlayPaint = Paint()..color = const Color(0xAA000000);
  final _bgPaint = Paint()..color = const Color(0xFF222222);
  final _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.1;

  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1,
      color: Color(0xFFFFFFFF),
      fontFamily: 'Awesome Font',
    ),
  );

  @override
  Future<void> onLoad() async {
    priority = 1000;

    final visibleRect = game.camera.visibleWorldRect;

    size = visibleRect.size.toVector2();
    position = visibleRect.center.toVector2();
    anchor = Anchor.center;

    final center = size / 2;
    final boxHalfHeight = _boxSize.y / 2;

    final buttonY = center.y + boxHalfHeight - 2.5;
    const buttonOffsetX = 4.5;

    add(DialogButton('YES', const Color(0xFF4CAF50), () {
      onConfirm();
      removeFromParent();
    })
      ..position = Vector2(center.x - buttonOffsetX, buttonY)
      ..anchor = Anchor.center
    );

    add(DialogButton('NO', const Color(0xFFF44336), () {
      removeFromParent();
    })
      ..position = Vector2(center.x + buttonOffsetX, buttonY)
      ..anchor = Anchor.center
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _overlayPaint);

    final center = size.toOffset() / 2;
    final boxRect = Rect.fromCenter(
        center: center,
        width: _boxSize.x,
        height: _boxSize.y
    );

    canvas.drawRect(boxRect, _bgPaint);
    canvas.drawRect(boxRect, _borderPaint);

    _textPaint.render(
        canvas,
        message,
        Vector2(center.dx, center.dy - _boxSize.y / 2 + 1.5),
        anchor: Anchor.center
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    event.handled = true;
  }
}