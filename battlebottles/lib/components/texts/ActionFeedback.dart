import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import '../../BattleShipsGame.dart';

class ActionFeedback extends PositionComponent with HasGameReference<BattleShipsGame> {
  ActionFeedback() : super(size: Vector2(BattleShipsGame.squareLength * 7, BattleShipsGame.squareLength));

  String _message = '';
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
        "Direct hit! Shoot again",
        "Nice shot! Keep going",
        "Target damaged! Shoot again",
        "Boom! Keep going"
      ],
      'sink': [
        "You sunk a ship! Shoot again",
        "Enemy vessel down! Shoot again",
        "That's a kill! Keep going",
        "Blub blub blub... Shoot again",
        "One less problem! Keep going"
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

  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.2,
      fontFamily: 'Awesome Font',
      color: Color(0xff003366),
      fontWeight: FontWeight.bold,
    ),
  );

  void setMessage(String condition, bool isOpponent) {
    final actorLibrary = _messageLibrary[isOpponent];

    if (actorLibrary != null) {
      final texts = actorLibrary[condition];

      if (texts != null && texts.isNotEmpty) {
        _message = texts[_rng.nextInt(texts.length)];
        _timer = 2.0;
      }
    }
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