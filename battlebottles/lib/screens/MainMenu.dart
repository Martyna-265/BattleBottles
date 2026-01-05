import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import '../components/buttons/HelpButton.dart';
import '../components/buttons/MultiplayerButton.dart';
import '../components/buttons/SoundButton.dart';
import 'AccountDropdown.dart';
import '../components/buttons/SingleplayerButton.dart';
import '../services/FirestoreService.dart';
import '../BattleShipsGame.dart';

class MainMenu extends PositionComponent with HasGameReference<BattleShipsGame> {

  MainMenu() : super();

  late PlaySingleButton playButton;
  late MultiplayerButton multiplayerButton;
  late AccountDropdown accountDropdown;
  late HelpButton helpButton;
  late SoundButton soundButton;

  final _titlePaint = TextPaint(
    style: const TextStyle(
      fontSize: 40.0,
      color: Color(0xffffffff),
      fontWeight: FontWeight.bold,
    ),
  );

  final _bgPaint = Paint()..color = const Color(0xcc003366);
  final _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  Future<void> onLoad() async {
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
  }

  @override
  void onMount() {
    super.onMount();
    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;

    playButton.position = Vector2(size.x / 2, size.y / 2 - 20);
    multiplayerButton.position = Vector2(size.x / 2, size.y / 2 + 60);
    accountDropdown.position = Vector2(size.x - 20, 20);

    helpButton.position = Vector2(20, 20);
    soundButton.position = Vector2(60, 20);
  }

  @override
  void render(Canvas canvas) {
    double titleWidth = 400;
    double titleHeight = 60;

    Vector2 centerPos = Vector2(size.x / 2, size.y / 2 - 100);

    Rect rect = Rect.fromCenter(
      center: Offset(centerPos.x, centerPos.y),
      width: titleWidth,
      height: titleHeight,
    );

    RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));

    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);

    _titlePaint.render(
      canvas,
      'BATTLE BOTTLES',
      centerPos,
      anchor: Anchor.center,
    );
  }
}