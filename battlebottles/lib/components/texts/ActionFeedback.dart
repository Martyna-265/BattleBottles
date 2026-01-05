import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import '../../BattleShipsGame.dart';

class ActionFeedback extends PositionComponent with HasGameReference<BattleShipsGame> {
  ActionFeedback()
      : super(size: Vector2(BattleShipsGame.squareLength * 7, BattleShipsGame.squareLength * 1.3));

  late TextPaint _mainTextPaint;
  late TextPaint _subTextPaint;

  String _mainText = "";
  String _subText = "";
  double _timer = 0;
  final Random _rng = Random();

  final _backgroundPaint = Paint()..color = const Color(0xdd003366);
  final _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  static final Map<bool, Map<String, List<String>>> _messageLibrary = {
    false: {
      'miss': [
        "Miss...",
        "Just water",
        "Splash!",
        "Nothing there",
        "Empty coordinates"
      ],
      'hit': [
        "Hit! Shoot again",
        "Direct hit! Keep going",
        "Nice shot! Keep going",
        "Target damaged!",
        "Boom! Keep going"
      ],
      'sink': [
        "You sunk a ship!",
        "Enemy vessel down!",
        "That's a kill!",
        "Blub blub blub...",
        "One less problem!"
      ]
    },
    true: {
      'miss': [
        "Opponent missed!",
        "Close call!",
        "We are safe",
        "They hit water",
        "Lucky us!"
      ],
      'hit': [
        "Opponent hit your ship!",
        "We're taking damage!",
        "Hull breached!",
        "They have another shot",
        "Watch out!"
      ],
      'sink': [
        "Opponent sunk your ship!",
        "Men overboard!",
        "We lost a vessel!",
        "Critical damage!",
        "They are winning..."
      ]
    }
  };

  @override
  Future<void> onLoad() async {
    _mainTextPaint = TextPaint(
      style: const TextStyle(
        fontSize: 1.2,
        fontFamily: 'Awesome Font',
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    _subTextPaint = TextPaint(
      style: const TextStyle(
        fontSize: 0.8,
        fontFamily: 'Awesome Font',
        color: Colors.white70,
      ),
    );
  }

  void setMessage(String type, bool isEnemy, {String addition = ""}) {
    Color mainColor = Colors.white;
    String lookupKey = type;

    if (type == "hit") {
      mainColor = Colors.redAccent;
    } else if (type == "sunk" || type == "sink") {
      mainColor = Colors.red;
      lookupKey = "sink";
    } else {
      mainColor = Colors.white;
      lookupKey = "miss";
    }

    final actorLibrary = _messageLibrary[isEnemy];

    if (actorLibrary != null && actorLibrary.containsKey(lookupKey)) {
      final texts = actorLibrary[lookupKey];
      if (texts != null && texts.isNotEmpty) {
        _mainText = texts[_rng.nextInt(texts.length)];
      } else {
        _mainText = type.toUpperCase();
      }
    } else {
      _mainText = type.toUpperCase();
    }

    _subText = addition;

    _mainTextPaint = TextPaint(style: _mainTextPaint.style.copyWith(color: mainColor));

    _timer = 2.0;
  }

  void reset() {
    _mainText = "";
    _subText = "";
    _timer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_timer > 0) {
      _timer -= dt;
      if (_timer <= 0) {
        _mainText = "";
        _subText = "";
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_mainText.isEmpty && _subText.isEmpty) return;

    RRect rrect = RRect.fromRectAndRadius(
        size.toRect(),
        const Radius.circular(0.4)
    );

    canvas.drawRRect(rrect, _backgroundPaint);
    canvas.drawRRect(rrect, _borderPaint);

    double centerY = size.y / 2;
    double offset = _subText.isNotEmpty ? 0.4 : 0.0;

    _mainTextPaint.render(
      canvas,
      _mainText,
      Vector2(size.x / 2, centerY - offset),
      anchor: Anchor.center,
    );

    if (_subText.isNotEmpty) {
      _subTextPaint.render(
        canvas,
        _subText,
        Vector2(size.x / 2, centerY + 0.5),
        anchor: Anchor.center,
      );
    }
  }
}