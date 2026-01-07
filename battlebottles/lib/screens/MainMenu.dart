import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import '../BattleShipsGame.dart';
import '../components/buttons/HelpButton.dart';
import '../components/buttons/MultiplayerButton.dart';
import '../components/buttons/SoundButton.dart';
import 'AccountDropdown.dart';
import '../components/buttons/SingleplayerButton.dart';
import '../services/FirestoreService.dart';

class MainMenu extends PositionComponent
    with HasGameReference<BattleShipsGame> {
  MainMenu() : super();

  late GameTitle _gameTitle;
  late PlaySingleButton playButton;
  late MultiplayerButton multiplayerButton;
  late AccountDropdown accountDropdown;
  late HelpButton helpButton;
  late SoundButton soundButton;

  bool _isInit = false;

  @override
  Future<void> onLoad() async {
    _gameTitle = GameTitle();
    add(_gameTitle);

    playButton = PlaySingleButton()..anchor = Anchor.center;
    add(playButton);

    multiplayerButton = MultiplayerButton()..anchor = Anchor.center;
    add(multiplayerButton);

    accountDropdown = AccountDropdown()..anchor = Anchor.topRight;
    add(accountDropdown);

    helpButton = HelpButton(sideLength: 30)..anchor = Anchor.topLeft;
    add(helpButton);

    soundButton = SoundButton(sideLength: 30)..anchor = Anchor.topLeft;
    add(soundButton);

    FirestoreService().cleanupOldGames();

    _isInit = true;
    _updatePositions();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
    _updatePositions();
  }

  void _updatePositions() {
    if (!_isInit) return;

    final effectiveSize = (size.x == 0 && size.y == 0) ? game.size : size;

    double titleOffset = game.isNarrow ? 80.0 : 80.0;

    _gameTitle.position = Vector2(
      effectiveSize.x / 2,
      effectiveSize.y / 2 - titleOffset,
    );

    playButton.position = Vector2(
      effectiveSize.x / 2,
      effectiveSize.y / 2 + 30,
    );
    multiplayerButton.position = Vector2(
      effectiveSize.x / 2,
      effectiveSize.y / 2 + 110,
    );

    accountDropdown.position = Vector2(effectiveSize.x - 20, 20);
    helpButton.position = Vector2(20, 20);
    soundButton.position = Vector2(60, 20);
  }
}

class GameTitle extends PositionComponent
    with HasGameReference<BattleShipsGame> {
  late TextPaint _titlePaint;

  final _bgPaint = Paint()..color = const Color(0xcc003366);
  final _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke;

  GameTitle() : super(anchor: Anchor.center);

  void _buildText(Vector2 screenSize) {
    bool isNarrow = screenSize.x < screenSize.y * 0.8;

    double fontSize = isNarrow ? 42.0 : 60.0;
    _borderPaint.strokeWidth = isNarrow ? 2.0 : 3.0;

    _titlePaint = TextPaint(
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'Awesome Font',
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(offset: Offset(3, 3), color: Colors.black, blurRadius: 5),
        ],
      ),
    );

    const String text = "BATTLE BOTTLES";
    final textSpan = TextSpan(text: text, style: _titlePaint.style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double paddingX = fontSize * 0.8;
    double paddingY = fontSize * 0.3;

    size = Vector2(textPainter.width + paddingX, textPainter.height + paddingY);
  }

  @override
  Future<void> onLoad() async {
    _buildText(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _buildText(size);
  }

  @override
  void onMount() {
    super.onMount();
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.8, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    RRect rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(30),
    );
    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);

    _titlePaint.render(
      canvas,
      'BATTLE BOTTLES',
      size / 2,
      anchor: Anchor.center,
    );
  }
}
