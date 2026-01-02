import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import '../../screens/BattleShipsGame.dart';

class ActionFeedback extends PositionComponent with HasGameReference<BattleShipsGame> {
  ActionFeedback() : super(size: Vector2(BattleShipsGame.squareLength * 7, BattleShipsGame.squareLength));

  String _message = '';
  double _timer = 0;

  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.2,
      fontFamily: 'Awesome Font',
      color: Color(0xff003366),
      fontWeight: FontWeight.bold,
    ),
  );

  void setMessage(String msg) {
    _message = msg;
    _timer = 2.0;
  }

  void reset() {
    _message = '';
    _timer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_timer > 0) {
      _timer -= dt;
      if (_timer <= 0) {
        _message = '';
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_message.isEmpty) return;

    _textPaint.render(
      canvas,
      _message,
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }
}