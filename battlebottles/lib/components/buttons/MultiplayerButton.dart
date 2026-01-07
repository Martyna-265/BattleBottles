import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Image, Draggable;
import '../../BattleShipsGame.dart';
import '../../services/AuthService.dart';
import '../../services/AudioManager.dart';

class MultiplayerButton extends PositionComponent
    with HasGameReference<BattleShipsGame>, TapCallbacks {
  MultiplayerButton() : super(size: Vector2(200, 60));

  final _activePaint = Paint()..color = const Color(0xffFF9800);
  final _disabledPaint = Paint()..color = const Color(0xff9E9E9E);
  final _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 24.0,
      color: Color(0xFFFFFFFF),
      fontFamily: 'Awesome Font',
      fontWeight: FontWeight.bold,
    ),
  );

  final AuthService _auth = AuthService();

  @override
  void render(Canvas canvas) {
    final bool isLoggedIn = _auth.currentUser != null;

    RRect rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(30),
    );
    canvas.drawRRect(rrect, isLoggedIn ? _activePaint : _disabledPaint);
    canvas.drawRRect(rrect, _borderPaint);

    _textPaint.render(
      canvas,
      'MULTIPLAYER',
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) async {
    AudioManager.playClick();
    AudioManager.playBgm();

    final bool isLoggedIn = _auth.currentUser != null;

    if (!isLoggedIn) {
      if (game.buildContext != null) {
        showDialog(
          context: game.buildContext!,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xff003366),
              title: const Text(
                'Log in',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Awesome Font',
                ),
              ),
              content: const Text(
                'You need to be logged in to play in multiplayer.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    bool hasInternet = true;

    if (!kIsWeb) {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          hasInternet = false;
        }
      } on SocketException catch (_) {
        hasInternet = false;
      }
    }

    if (!hasInternet) {
      if (game.buildContext != null) {
        showDialog(
          context: game.buildContext!,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xff003366),
              title: const Text(
                'No Internet',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Awesome Font',
                ),
              ),
              content: const Text(
                'You need an active internet connection to play multiplayer.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    game.openMultiplayerLobby();
  }
}
