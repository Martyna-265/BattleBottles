import 'dart:ui';

import 'package:battlebottles/TurnManager.dart';
import 'package:battlebottles/components/BattleGrid.dart';
import 'package:battlebottles/components/buttons/ReturnToMenuButton.dart';
import 'package:battlebottles/screens/MainMenu.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/text.dart'; // Potrzebne do TextComponent

import '../components/Buttons/RestartButton.dart';
import '../components/Buttons/StartButton.dart';
import '../components/texts/RoundInfo.dart';
import '../services/AuthService.dart'; // Import AuthService do pobrania nazwy użytkownika

class BattleShipsGame extends FlameGame {

  static const double squareLength = 2.0;
  static final Vector2 squareSize = Vector2(squareLength, squareLength);
  static const int squaresInGrid = 9;
  static const double battleGridWidth = squaresInGrid * squareLength;
  static const double battleGridHeight = squaresInGrid * squareLength;
  static final Vector2 battleGridSize = Vector2(battleGridWidth, battleGridHeight);
  static const double gap = 10.0;
  static const int delay = 2;

  static const double maxWidthForNarrow = 800;
  static const int bottleCount = 10;

  late TurnManager turnManager;
  late BattleGrid playersGrid;
  late BattleGrid opponentsGrid;
  late StartButton startButton;
  late RestartButton restartButton;
  late ReturnToMenuButton returnToMenuButton;
  late RoundInfo roundInfo;
  late MainMenu mainMenu;

  // --- NOWE KOMPONENTY TEKSTOWE ---
  late TextComponent playerLabel;
  late TextComponent opponentLabel;

  int visibleCurrentPlayer = 0;

  bool _isLoaded = false;

  bool isGameRunning = false;

  bool get isNarrow => size.x < maxWidthForNarrow;

  @override
  Color backgroundColor() => const Color(0xff84afdb);

  @override
  Future<void> onLoad() async {
    await Flame.images.load('Bottle1x1.png');

    turnManager = TurnManager(2, this);

    playersGrid = BattleGrid(false, bottleCount)..size = battleGridSize;
    opponentsGrid = BattleGrid(true, bottleCount)..size = battleGridSize;

    startButton = StartButton()
      ..position = Vector2(gap, gap / 2)
      ..anchor = Anchor.center;

    restartButton = RestartButton()
      ..position = Vector2(gap + 4 * squareLength, gap / 2)
      ..anchor = Anchor.center;

    returnToMenuButton = ReturnToMenuButton()
      ..position = Vector2(gap + 8 * squareLength, gap / 2)
      ..anchor = Anchor.center;

    roundInfo = RoundInfo()
      ..position = Vector2(2 * gap, 2 * gap + battleGridHeight)
      ..anchor = Anchor.center;

    // --- INICJALIZACJA ETYKIET (bez dodawania do world jeszcze) ---
    // Używamy stylu pasującego do skali gry (fontSize ok. 1.0)
    final labelStyle = TextPaint(
      style: const TextStyle(
        fontSize: 1.2,
        color: Color(0xff003366), // Ciemny granat dla kontrastu
        fontFamily: 'Awesome Font',
        fontWeight: FontWeight.bold,
      ),
    );

    playerLabel = TextComponent(textRenderer: labelStyle)
      ..anchor = Anchor.topCenter; // Centrujemy tekst względem punktu zaczepienia

    opponentLabel = TextComponent(textRenderer: labelStyle)
      ..anchor = Anchor.topCenter;

    mainMenu = MainMenu();

    world.add(mainMenu);

    _isLoaded = true;

    camera.viewfinder.position = Vector2(0,0);
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  void startGame() {
    if (isGameRunning) return;

    // --- USTAWIANIE NAZW UŻYTKOWNIKÓW ---
    final user = AuthService().currentUser;

    // Logika dla gracza: DisplayName -> "You"
    String pName = "You";
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        pName = user.displayName!;
      }
    }
    playerLabel.text = pName;

    // Logika dla przeciwnika (na razie Pirate)
    opponentLabel.text = "Pirate";
    // -------------------------------------

    world.remove(mainMenu);

    world.add(playersGrid);
    world.add(playerLabel); // Dodajemy podpis gracza

    if (!isNarrow) {
      world.add(opponentsGrid);
      world.add(opponentLabel); // Dodajemy podpis przeciwnika (tylko na szerokim na start)
    }

    world.add(startButton);
    world.add(restartButton);
    world.add(returnToMenuButton);
    world.add(roundInfo);

    isGameRunning = true;

    updateView();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    if (!_isLoaded) return;

    if (isGameRunning) {
      updateView();
    } else {
      camera.viewfinder.position = Vector2(0,0);
      camera.viewfinder.anchor = Anchor.topLeft;
    }
  }

  void updateView() {
    if (!_isLoaded) return;

    visibleCurrentPlayer = turnManager.currentPlayer;

    // Helper do pozycjonowania etykiety pod gridem
    // Ustawiamy ją na środku szerokości grida, kawałek (0.5) pod nim
    void positionLabel(BattleGrid grid, TextComponent label) {
      label.position = Vector2(
          grid.position.x + battleGridWidth / 2,
          grid.position.y + battleGridHeight + 0.5
      );
    }

    if (isNarrow) {
      // WĄSKI EKRAN
      if (visibleCurrentPlayer == 0 || visibleCurrentPlayer == 2) {
        // Pokaż GRACZA
        if (!playersGrid.isMounted) world.add(playersGrid);
        if (!playerLabel.isMounted) world.add(playerLabel); // Pokaż podpis gracza

        // Ukryj PRZECIWNIKA
        if (opponentsGrid.isMounted) world.remove(opponentsGrid);
        if (opponentLabel.isMounted) world.remove(opponentLabel); // Ukryj podpis wroga
      }
      else if (visibleCurrentPlayer == 1) {
        // Ukryj GRACZA
        if (playersGrid.isMounted) world.remove(playersGrid);
        if (playerLabel.isMounted) world.remove(playerLabel);

        // Pokaż PRZECIWNIKA
        if (!opponentsGrid.isMounted) world.add(opponentsGrid);
        if (!opponentLabel.isMounted) world.add(opponentLabel);
      }

      if (playersGrid.isMounted) {
        playersGrid.position = Vector2(gap, gap);
        positionLabel(playersGrid, playerLabel);
      }

      if (opponentsGrid.isMounted) {
        opponentsGrid.position = Vector2(gap, gap);
        positionLabel(opponentsGrid, opponentLabel);
      }

    } else {
      // SZEROKI EKRAN
      if (!playersGrid.isMounted) world.add(playersGrid);
      if (!playerLabel.isMounted) world.add(playerLabel);

      if (!opponentsGrid.isMounted) world.add(opponentsGrid);
      if (!opponentLabel.isMounted) world.add(opponentLabel);

      playersGrid.position = Vector2(gap, gap);
      positionLabel(playersGrid, playerLabel);

      opponentsGrid.position = Vector2(gap + battleGridWidth + gap, gap);
      positionLabel(opponentsGrid, opponentLabel);
    }

    _updateCamera();
  }

  void _updateCamera() {
    double totalWidth;
    double totalHeight;

    if (isNarrow) {
      totalWidth = battleGridWidth + 2 * gap;
      // Zwiększamy trochę wysokość, żeby zmieścił się napis pod spodem
      totalHeight = battleGridHeight + 2 * gap + 2.0;

      camera.viewfinder.visibleGameSize = Vector2(totalWidth, totalHeight);
      camera.viewfinder.position = Vector2(totalWidth / 2, 0);
      camera.viewfinder.anchor = Anchor.topCenter;

    } else {
      totalWidth = battleGridWidth * 2 + 3 * gap;
      totalHeight = battleGridHeight + 2 * gap + 2.0;

      camera.viewfinder.visibleGameSize = Vector2(totalWidth, totalHeight);
      camera.viewfinder.position = Vector2(totalWidth / 2, 0);
      camera.viewfinder.anchor = Anchor.topCenter;
    }
  }

  void restartGame() {
    restartGameInternalState();

    if (!startButton.isMounted) {
      world.add(startButton);
    }

    updateView();
  }

  void returnToMenu() {
    if (!isGameRunning) return;

    if (playersGrid.isMounted) world.remove(playersGrid);
    if (opponentsGrid.isMounted) world.remove(opponentsGrid);

    // Usuwamy też etykiety
    if (playerLabel.isMounted) world.remove(playerLabel);
    if (opponentLabel.isMounted) world.remove(opponentLabel);

    if (startButton.isMounted) world.remove(startButton);
    if (restartButton.isMounted) world.remove(restartButton);
    if (returnToMenuButton.isMounted) world.remove(returnToMenuButton);
    if (roundInfo.isMounted) world.remove(roundInfo);

    world.add(mainMenu);

    mainMenu.onGameResize(size);

    camera.viewfinder.position = Vector2(0, 0);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;

    isGameRunning = false;

    restartGameInternalState();
  }

  void restartGameInternalState() {
    turnManager.reset();
    visibleCurrentPlayer = 0;
    playersGrid.regenerateGrid();
    opponentsGrid.regenerateGrid();
  }

  void openMultiplayerLobby() {
    overlays.add('MultiplayerLobby');
  }

}