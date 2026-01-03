import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import '../../BattleShipsGame.dart';

class ActionFeedback extends PositionComponent with HasGameReference<BattleShipsGame> {
  ActionFeedback() : super(size: Vector2(BattleShipsGame.squareLength * 7, BattleShipsGame.squareLength));

  String _mainText = '';
  String _subText = '';
  double _timer = 0;
  final Random _rng = Random();

  static final Map<bool, Map<String, List<String>>> _messageLibrary = {
    // GRACZ
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
    // PRZECIWNIK
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

  final _mainTextPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.0,
      fontFamily: 'Awesome Font',
      color: Color(0xff003366),
      fontWeight: FontWeight.bold,
    ),
  );

  final _subTextPaint = TextPaint(
    style: const TextStyle(
      fontSize: 0.8,
      fontFamily: 'Awesome Font',
      color: Color(0xff4a6fa5),
      fontWeight: FontWeight.bold,
    ),
  );

  void setMessage(String condition, bool isOpponent, {String? addition}) {
    final actorLibrary = _messageLibrary[isOpponent];

    if (actorLibrary != null && actorLibrary.containsKey(condition)) {
      final texts = actorLibrary[condition];
      if (texts != null && texts.isNotEmpty) {
        _mainText = texts[_rng.nextInt(texts.length)];
      }
    } else {
      _mainText = condition;
    }

    if (addition != null && addition.isNotEmpty) {
      _subText = "($addition)";
    } else {
      _subText = '';
    }

    _timer = 2.0;
  }

  void reset() {
    _mainText = '';
    _subText = '';
    _timer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_timer > 0) {
      _timer -= dt;
      if (_timer <= 0) {
        _mainText = '';
        _subText = '';
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_mainText.isEmpty) return;

    double centerX = size.x / 2;

    if (_subText.isEmpty) {
      _mainTextPaint.render(
        canvas,
        _mainText,
        Vector2(centerX, size.y / 2),
        anchor: Anchor.center,
      );
    } else {

      _mainTextPaint.render(
        canvas,
        _mainText,
        Vector2(centerX, size.y * 0.35),
        anchor: Anchor.center,
      );

      _subTextPaint.render(
        canvas,
        _subText,
        Vector2(centerX, size.y * 0.85),
        anchor: Anchor.center,
      );
    }
  }
}