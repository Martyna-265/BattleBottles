import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Image, Draggable;
import '../../screens/BattleShipsGame.dart';
import '../../services/AuthService.dart';

class MultiplayerButton extends PositionComponent with HasGameReference<BattleShipsGame>, TapCallbacks {

  MultiplayerButton() : super(size: Vector2(200, 60));

  final _activePaint = Paint()..color = const Color(0xffFF9800);
  final _disabledPaint = Paint()..color = const Color(0xff9E9E9E);

  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 24.0,
      color: Color(0xFFFFFFFF),
      fontFamily: 'Awesome Font',
    ),
  );

  final AuthService _auth = AuthService();

  @override
  void render(Canvas canvas) {
    // Sprawdzamy stan logowania w każdej klatce rysowania
    // Dzięki temu przycisk zmieni kolor natychmiast po zalogowaniu w tle
    final bool isLoggedIn = _auth.currentUser != null;

    RRect rrect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10));
    canvas.drawRRect(rrect, isLoggedIn ? _activePaint : _disabledPaint);

    _textPaint.render(
      canvas,
      'MULTIPLAYER',
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    final bool isLoggedIn = _auth.currentUser != null;

    if (!isLoggedIn) {
      // --- NIEZALOGOWANY: Pokaż informację ---
      if (game.buildContext != null) {
        showDialog(
          context: game.buildContext!,
          builder: (context) {
            return AlertDialog(
              title: const Text('Log in'),
              content: const Text('You need to be logged in to play in multiplayer. Use the \'My Account\' button in the upper right corner.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // --- ZALOGOWANY: Przejdź do lobby ---
      game.openMultiplayerLobby();
    }
  }
}