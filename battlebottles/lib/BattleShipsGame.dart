import 'package:battlebottles/TurnManager.dart';
import 'package:battlebottles/components/BattleGrid.dart';
import 'package:battlebottles/components/buttons/ReturnToMenuButton.dart';
import 'package:battlebottles/screens/MainMenu.dart';
import 'package:battlebottles/services/AudioManager.dart';
import 'package:battlebottles/services/StatsService.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/text.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;
import '../components/buttons/RestartButton.dart';
import '../components/buttons/StartButton.dart';
import '../components/texts/ActionFeedback.dart';
import '../components/texts/RoundInfo.dart';
import '../components/gridElements/Bottle.dart';
import '../components/gridElements/GridElement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../components/texts/ShipsCounter.dart';
import 'animations/OctopusHeadAnimation.dart';
import 'animations/SharkAnimation.dart';
import 'animations/TentacleAnimation.dart';
import 'components/buttons/HelpButton.dart';
import 'components/buttons/PowerUpButton.dart';
import 'components/bottleElements/PowerUpType.dart';
import 'components/buttons/SoundButton.dart';

class BattleShipsGame extends FlameGame
    with TapCallbacks, WidgetsBindingObserver {
  static const double squareLength = 2.0;
  static final Vector2 squareSize = Vector2(squareLength, squareLength);
  static const double gap = 15.0;
  static const int delay = 2;
  static const int bottleCount = 10;

  int squaresInGrid = 10;
  double battleGridWidth = 20.0;
  double battleGridHeight = 20.0;
  static final Vector2 battleGridSize = Vector2(20.0, 20.0);

  double gridScale = 1.0;
  double get scaledGridWidth => battleGridWidth * gridScale;
  double get scaledGridHeight => battleGridHeight * gridScale;

  int gameSessionId = 0;

  int limitOctopus = 1;
  int limitTriple = 1;
  int limitShark = 1;
  int tripleShotsLeft = 0;
  PowerUpType activePowerUp = PowerUpType.none;
  String lastSpecialAttackId = '';

  String opponentName = "Pirate";

  late TurnManager turnManager;
  late BattleGrid playersGrid;
  late BattleGrid opponentsGrid;

  late StartButton startButton;
  late RestartButton restartButton;
  late ReturnToMenuButton returnToMenuButton;
  late HelpButton helpButton;
  late SoundButton soundButton;
  late RoundInfo roundInfo;
  late ActionFeedback actionFeedback;

  late PowerUpButton octopusBtn;
  late PowerUpButton tripleBtn;
  late PowerUpButton sharkBtn;

  late MainMenu mainMenu;

  late ShipsCounter playerCounter;
  late ShipsCounter opponentCounter;

  late PlayerLabel playerLabel;
  late PlayerLabel opponentLabel;

  String winnerMessage = '';

  bool isMultiplayer = false;
  String? multiplayerGameId;
  String? myUserId;
  bool amIHost = false;
  StreamSubscription? gameStream;

  int lastProcessedP1Shots = 0;
  int lastProcessedP2Shots = 0;

  int visibleCurrentPlayer = 0;
  bool _isLoaded = false;
  bool isGameRunning = false;

  bool isInMenu = true;

  bool tempIsMultiplayer = false;
  String? tempGameId;

  bool get isNarrow => size.x < size.y * 0.8;

  @override
  Color backgroundColor() => const Color(0x00000000);

  void _updateGridDimensions(int gridSize) {
    squaresInGrid = gridSize;
    battleGridWidth = squaresInGrid * squareLength;
    battleGridHeight = squaresInGrid * squareLength;
    gridScale = 20.0 / battleGridWidth;
  }

  @override
  Future<void> onLoad() async {
    await Flame.images.loadAll([
      'grid_element_sheet.png',
      'octopus.png',
      'bombs.png',
      'shark.png',
    ]);

    WidgetsBinding.instance.addObserver(this);

    _updateGridDimensions(10);

    turnManager = TurnManager(2, this);

    playersGrid = BattleGrid(false, {'1': 1})
      ..size = Vector2(battleGridWidth, battleGridHeight);
    opponentsGrid = BattleGrid(true, {'1': 1})
      ..size = Vector2(battleGridWidth, battleGridHeight);

    playerCounter = ShipsCounter(playersGrid);
    opponentCounter = ShipsCounter(opponentsGrid);

    startButton = StartButton()..anchor = Anchor.center;
    restartButton = RestartButton()..anchor = Anchor.center;
    returnToMenuButton = ReturnToMenuButton()..anchor = Anchor.center;

    helpButton = HelpButton(sideLength: squareLength)..anchor = Anchor.topLeft;
    soundButton = SoundButton(sideLength: squareLength)
      ..anchor = Anchor.topLeft;

    octopusBtn = PowerUpButton(
      imageName: 'octopus.png',
      type: PowerUpType.octopus,
      count: limitOctopus,
    );
    tripleBtn = PowerUpButton(
      imageName: 'bombs.png',
      type: PowerUpType.triple,
      count: limitTriple,
    );
    sharkBtn = PowerUpButton(
      imageName: 'shark.png',
      type: PowerUpType.shark,
      count: limitShark,
    );

    octopusBtn.anchor = Anchor.center;
    tripleBtn.anchor = Anchor.center;
    sharkBtn.anchor = Anchor.center;

    roundInfo = RoundInfo()..anchor = Anchor.center;
    actionFeedback = ActionFeedback()..anchor = Anchor.center;

    final labelStyle = TextPaint(
      style: const TextStyle(
        fontSize: 1.1,
        color: Color(0xffffffff),
        fontFamily: 'Awesome Font',
        fontWeight: FontWeight.bold,
      ),
    );

    playerLabel = PlayerLabel(textRenderer: labelStyle)..anchor = Anchor.center;
    opponentLabel = PlayerLabel(textRenderer: labelStyle)
      ..anchor = Anchor.center;

    mainMenu = MainMenu();
    world.add(mainMenu);
    isInMenu = true;
    _isLoaded = true;

    camera.viewfinder.position = Vector2(0, 0);
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  void resetPowerUps() {
    activePowerUp = PowerUpType.none;
    tripleShotsLeft = 0;
    if (_isLoaded) {
      octopusBtn.count = limitOctopus;
      tripleBtn.count = limitTriple;
      sharkBtn.count = limitShark;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      AudioManager.pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      AudioManager.resumeBgm();
    }
  }

  void togglePowerUp(PowerUpType type) {
    if (tripleShotsLeft > 0) return;
    if (activePowerUp == type) {
      activePowerUp = PowerUpType.none;
    } else {
      activePowerUp = type;
    }
  }

  void consumeActivePowerUp() {
    String? statKey;

    switch (activePowerUp) {
      case PowerUpType.octopus:
        octopusBtn.decrement();
        statKey = 'octopus';
        break;
      case PowerUpType.triple:
        tripleBtn.decrement();
        statKey = 'triple_shot';
        break;
      case PowerUpType.shark:
        sharkBtn.decrement();
        statKey = 'shark';
        break;
      case PowerUpType.none:
        break;
    }

    if (statKey != null) {
      StatsService().recordPowerUpUse(statKey);
    }

    activePowerUp = PowerUpType.none;
  }

  void openGameOptions({required bool isMultiplayer, String? gameId}) {
    tempIsMultiplayer = isMultiplayer;
    tempGameId = gameId;
    overlays.add('GameOptionsScreen');
  }

  void startGame({int gridSize = 10, Map<String, int>? fleetCounts}) async {
    if (isGameRunning && !isMultiplayer) return;
    AudioManager.playStart();

    _updateGridDimensions(gridSize);
    _clearWorldForGame();

    opponentName = "Pirate";

    final fleet = fleetCounts ?? {'4': 1, '3': 2, '2': 3, '1': 4};
    playersGrid = BattleGrid(false, fleet)
      ..size = Vector2(battleGridWidth, battleGridHeight)
      ..scale = Vector2.all(gridScale);
    opponentsGrid = BattleGrid(true, fleet)
      ..size = Vector2(battleGridWidth, battleGridHeight)
      ..scale = Vector2.all(gridScale);
    playerCounter = ShipsCounter(playersGrid);
    opponentCounter = ShipsCounter(opponentsGrid);

    resetPowerUps();
    turnManager.reset();
    turnManager.currentPlayer = 0;
    lastProcessedP1Shots = 0;
    lastProcessedP2Shots = 0;
    winnerMessage = '';
    if (actionFeedback.isMounted) actionFeedback.reset();

    if (mainMenu.isMounted) world.remove(mainMenu);
    isInMenu = false;
    isMultiplayer = false;

    world.add(playersGrid);
    world.add(playerLabel);
    playerLabel.text = "You";
    world.add(playerCounter);

    if (!isNarrow) {
      world.add(opponentsGrid);
      world.add(opponentLabel);
      opponentLabel.text = opponentName;
      world.add(opponentCounter);
    }

    world.add(startButton);
    world.add(restartButton);
    world.add(returnToMenuButton);
    world.add(roundInfo);
    world.add(actionFeedback);

    world.add(octopusBtn);
    world.add(tripleBtn);
    world.add(sharkBtn);

    if (!helpButton.isMounted) world.add(helpButton);
    if (!soundButton.isMounted) world.add(soundButton);

    isGameRunning = true;

    _updateUiPositions();
    onGameResize(size);
    updateView();
  }

  void startSingleplayerGame() {
    if (turnManager.currentPlayer != 0) return;
    if (startButton.isMounted) world.remove(startButton);
    if (!restartButton.isMounted) world.add(restartButton);
    AudioManager.playStart();

    turnManager.nextTurn();
    updateView();
  }

  void startMultiplayerGame(
    String gameId, {
    int gridSize = 10,
    Map<String, int>? fleetCounts,
    Map<String, int>? powerUps,
    required String p1Name,
    required String? p2Name,
    required String p1Id,
  }) {
    if (isGameRunning) return;
    AudioManager.playStart();
    overlays.remove('MultiplayerLobby');
    overlays.remove('GameOptionsScreen');

    isMultiplayer = true;
    multiplayerGameId = gameId;
    myUserId = FirebaseAuth.instance.currentUser?.uid;
    amIHost = (myUserId == p1Id);

    if (amIHost) {
      opponentName = p2Name ?? "Opponent";
    } else {
      opponentName = p1Name;
    }

    if (powerUps != null) {
      limitOctopus = powerUps['octopus'] ?? 1;
      limitTriple = powerUps['triple'] ?? 1;
      limitShark = powerUps['shark'] ?? 1;
    }

    _updateGridDimensions(gridSize);
    _clearWorldForGame();

    final fleet = fleetCounts ?? {'4': 1, '3': 2, '2': 3, '1': 4};
    playersGrid = BattleGrid(false, fleet)
      ..size = Vector2(battleGridWidth, battleGridHeight)
      ..scale = Vector2.all(gridScale);
    opponentsGrid = BattleGrid(true, fleet)
      ..size = Vector2(battleGridWidth, battleGridHeight)
      ..scale = Vector2.all(gridScale);
    playerCounter = ShipsCounter(playersGrid);
    opponentCounter = ShipsCounter(opponentsGrid);

    resetPowerUps();
    turnManager.reset();
    turnManager.currentPlayer = 0;
    lastProcessedP1Shots = 0;
    lastProcessedP2Shots = 0;
    winnerMessage = '';
    if (actionFeedback.isMounted) actionFeedback.reset();

    if (mainMenu.isMounted) world.remove(mainMenu);
    isInMenu = false;

    world.add(playersGrid);
    world.add(playerLabel);

    if (amIHost) {
      playerLabel.text = "You ($p1Name)";
    } else {
      playerLabel.text = "You (${p2Name ?? 'Guest'})";
    }

    world.add(playerCounter);

    if (!isNarrow) {
      world.add(opponentsGrid);
      world.add(opponentLabel);
      opponentLabel.text = opponentName;
      world.add(opponentCounter);
    }

    world.add(startButton);
    world.add(returnToMenuButton);
    world.add(roundInfo);
    world.add(actionFeedback);

    world.add(octopusBtn);
    world.add(tripleBtn);
    world.add(sharkBtn);

    if (!helpButton.isMounted) world.add(helpButton);
    if (!soundButton.isMounted) world.add(soundButton);

    _updateUiPositions();
    onGameResize(size);
    updateView();
    _listenToMultiplayerChanges();
  }

  void _clearWorldForGame() {
    final componentsToRemove = [
      playersGrid,
      opponentsGrid,
      playerCounter,
      opponentCounter,
      playerLabel,
      opponentLabel,
      startButton,
      restartButton,
      returnToMenuButton,
      octopusBtn,
      tripleBtn,
      sharkBtn,
      roundInfo,
      actionFeedback,
    ];
    world.removeAll(componentsToRemove.where((c) => c.isMounted));
  }

  void _updateUiPositions() {
    double uiCenterX;
    if (isNarrow) {
      uiCenterX = scaledGridWidth / 2;
    } else {
      uiCenterX = (scaledGridWidth * 2 + gap) / 2;
    }

    double roundInfoY = -7.5;
    double feedbackY = -5.0;

    roundInfo.position = Vector2(uiCenterX, roundInfoY);
    actionFeedback.position = Vector2(uiCenterX, feedbackY);

    double roundInfoWidth = 7 * squareLength;
    double roundInfoLeftEdge = uiCenterX - (roundInfoWidth / 2);
    double buttonSize = helpButton.size.x;
    double padding = 0.5;

    soundButton.position = Vector2(
      roundInfoLeftEdge - padding - buttonSize,
      roundInfoY - (buttonSize / 2),
    );

    helpButton.position = Vector2(
      soundButton.position.x - padding - buttonSize,
      roundInfoY - (buttonSize / 2),
    );

    double powerUpY = scaledGridHeight + 7.5;

    double spacing = 4.0;
    octopusBtn.position = Vector2(uiCenterX - spacing, powerUpY);
    tripleBtn.position = Vector2(uiCenterX, powerUpY);
    sharkBtn.position = Vector2(uiCenterX + spacing, powerUpY);

    double buttonsY = powerUpY + 4.5;
    double btnSpacing = 6.5;

    returnToMenuButton.position = Vector2(uiCenterX, buttonsY);
    if (turnManager.currentPlayer == 0) {
      startButton.position = Vector2(uiCenterX - btnSpacing, buttonsY);
    }
    restartButton.position = Vector2(uiCenterX + btnSpacing, buttonsY);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_isLoaded) return;

    if (isInMenu) {
      camera.viewfinder.visibleGameSize = size;
      camera.viewfinder.position = Vector2(0, 0);
      camera.viewfinder.anchor = Anchor.topLeft;
    } else {
      _updateUiPositions();
      updateView();
      _updateCamera();
    }
  }

  void updateView() {
    if (!_isLoaded) return;
    if (isInMenu) return;

    visibleCurrentPlayer = turnManager.currentPlayer;

    void positionLabel(BattleGrid grid, PlayerLabel label) {
      label.position = Vector2(
        grid.position.x + scaledGridWidth / 2,
        grid.position.y - 2.5,
      );
    }

    void positionCounter(BattleGrid grid, ShipsCounter counter) {
      counter.position = Vector2(
        grid.position.x,
        grid.position.y + scaledGridHeight + 0.5,
      );
    }

    _updateUiPositions();

    if (isNarrow) {
      // Narrow
      bool showOpponent =
          (!isGameRunning && !isInMenu && visibleCurrentPlayer != 0) ||
              (visibleCurrentPlayer == 1);

      if (showOpponent) {
        // Show opponent
        if (opponentsGrid.parent == null) world.add(opponentsGrid);
        opponentsGrid.scale = Vector2.all(gridScale);

        if (opponentLabel.parent == null) world.add(opponentLabel);
        opponentLabel.text = opponentName;

        if (opponentCounter.parent == null) world.add(opponentCounter);

        // Hide player
        if (playersGrid.parent != null) playersGrid.removeFromParent();
        if (playerLabel.parent != null) playerLabel.removeFromParent();
        if (playerCounter.parent != null) playerCounter.removeFromParent();

        opponentsGrid.position = Vector2(0, 0);
        positionLabel(opponentsGrid, opponentLabel);
        positionCounter(opponentsGrid, opponentCounter);
      } else {
        // Show player
        if (playersGrid.parent == null) world.add(playersGrid);
        playersGrid.scale = Vector2.all(gridScale);

        if (playerLabel.parent == null) world.add(playerLabel);
        if (playerCounter.parent == null) world.add(playerCounter);

        // Hide opponent
        if (opponentsGrid.parent != null) opponentsGrid.removeFromParent();
        if (opponentLabel.parent != null) opponentLabel.removeFromParent();
        if (opponentCounter.parent != null) opponentCounter.removeFromParent();

        playersGrid.position = Vector2(0, 0);
        positionLabel(playersGrid, playerLabel);
        positionCounter(playersGrid, playerCounter);
      }
    } else {
      // Wide
      if (playersGrid.parent == null) world.add(playersGrid);
      playersGrid.scale = Vector2.all(gridScale);

      if (playerLabel.parent == null) world.add(playerLabel);
      if (playerCounter.parent == null) world.add(playerCounter);

      if (opponentsGrid.parent == null) world.add(opponentsGrid);
      opponentsGrid.scale = Vector2.all(gridScale);

      if (opponentLabel.parent == null) world.add(opponentLabel);
      opponentLabel.text = opponentName;

      if (opponentCounter.parent == null) world.add(opponentCounter);

      playersGrid.position = Vector2(0, 0);
      positionLabel(playersGrid, playerLabel);
      positionCounter(playersGrid, playerCounter);

      opponentsGrid.position = Vector2(scaledGridWidth + gap, 0);
      positionLabel(opponentsGrid, opponentLabel);
      positionCounter(opponentsGrid, opponentCounter);
    }
    _updateCamera();
  }

  void _updateCamera() {
    double topMargin = 10.0;
    double bottomMargin = 18.0;
    double sideMargin = 2.0;

    double minVisibleWidth = 29.0;
    double minVisibleHeight = 45.0;

    double calculatedHeight = scaledGridHeight + topMargin + bottomMargin;
    double visibleHeight = math.max(calculatedHeight, minVisibleHeight);

    if (isNarrow) {
      double gridWidthWithMargins = scaledGridWidth + (sideMargin * 2);
      double visibleWidth = math.max(gridWidthWithMargins, minVisibleWidth);

      camera.viewfinder.visibleGameSize = Vector2(visibleWidth, visibleHeight);
      camera.viewfinder.position = Vector2(
        scaledGridWidth / 2,
        scaledGridHeight / 2 + 1.0,
      );
    } else {
      double totalContentWidth = scaledGridWidth * 2 + gap;
      double gridWidthWithMargins = totalContentWidth + (sideMargin * 4);
      double visibleWidth = math.max(gridWidthWithMargins, minVisibleWidth);

      camera.viewfinder.visibleGameSize = Vector2(visibleWidth, visibleHeight);
      camera.viewfinder.position = Vector2(
        totalContentWidth / 2,
        scaledGridHeight / 2 + 1.0,
      );
    }
    camera.viewfinder.anchor = Anchor.center;
  }

  void restartGame() {
    isGameRunning = true;
    restartGameInternalState();

    if (overlays.isActive('WinnerConfetti')) {
      overlays.remove('WinnerConfetti');
    }

    if (!startButton.isMounted) world.add(startButton);
    if (!restartButton.isMounted) world.add(restartButton);
    if (!returnToMenuButton.isMounted) world.add(returnToMenuButton);
    if (!roundInfo.isMounted) world.add(roundInfo);
    if (!actionFeedback.isMounted) world.add(actionFeedback);

    _updateUiPositions();
    updateView();
    _updateCamera();
  }

  void returnToMenu() {
    gameStream?.cancel();
    isMultiplayer = false;
    isGameRunning = false;

    if (overlays.isActive('WinnerConfetti')) {
      overlays.remove('WinnerConfetti');
    }

    _clearWorldForGame();
    if (helpButton.isMounted) world.remove(helpButton);
    if (actionFeedback.isMounted) actionFeedback.reset();
    world.add(mainMenu);
    isInMenu = true;
    camera.viewfinder.position = Vector2(0, 0);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;
    camera.viewfinder.visibleGameSize = size;
    mainMenu.onGameResize(size);
    turnManager.reset();
  }

  void restartGameInternalState() {
    gameSessionId++;
    turnManager.reset();
    visibleCurrentPlayer = 0;

    resetPowerUps();

    if (playersGrid.isMounted) playersGrid.regenerateGrid();
    if (opponentsGrid.isMounted) opponentsGrid.regenerateGrid();
    lastProcessedP1Shots = 0;
    lastProcessedP2Shots = 0;
    if (actionFeedback.isMounted) actionFeedback.reset();
  }

  void openMultiplayerLobby() {
    overlays.add('MultiplayerLobby');
  }

  @override
  void onDetach() {
    WidgetsBinding.instance.removeObserver(this);
    AudioManager.stopBgm();
    gameStream?.cancel();
    super.onDetach();
  }

  void confirmMultiplayerShips() async {
    if (multiplayerGameId == null) return;
    List<Map<String, dynamic>> myShipsData = playersGrid.getShipsData();
    String readyField = amIHost ? 'player1Ready' : 'player2Ready';
    String shipsField = amIHost ? 'ships_p1' : 'ships_p2';
    await FirebaseFirestore.instance
        .collection('battles')
        .doc(multiplayerGameId)
        .update({readyField: true, shipsField: myShipsData});
    turnManager.currentPlayer = -1;
    if (startButton.isMounted) world.remove(startButton);
    updateView();
  }

  void _listenToMultiplayerChanges() {
    if (multiplayerGameId == null) return;
    gameStream = FirebaseFirestore.instance
        .collection('battles')
        .doc(multiplayerGameId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      if (data['player1Id'] == myUserId) {
        amIHost = true;
      } else {
        amIHost = false;
      }

      String p1Name = data['player1Name'] ?? 'Player 1';
      String p2Name = data['player2Name'] ?? 'Player 2';

      if (amIHost) {
        opponentName = p2Name;
      } else {
        opponentName = p1Name;
      }

      if (playerLabel.isMounted) {
        if (amIHost) {
          playerLabel.text = "You ($p1Name)";
        } else {
          playerLabel.text = "You ($p2Name)";
        }
      }

      bool p1Ready = data['player1Ready'] ?? false;
      bool p2Ready = data['player2Ready'] ?? false;

      if (p1Ready && p2Ready) {
        if (!turnManager.hasShipsSynced) {
          List<dynamic> enemyShipsPositions =
              amIHost ? (data['ships_p2'] ?? []) : (data['ships_p1'] ?? []);
          if (enemyShipsPositions.isNotEmpty) {
            opponentsGrid.setEnemyShips(enemyShipsPositions);
            turnManager.hasShipsSynced = true;
            isGameRunning = true;
          }
        }
        if (startButton.isMounted) world.remove(startButton);

        _syncShots(data);

        if (data.containsKey('lastSpecialAttack')) {
          var attackData = data['lastSpecialAttack'] as Map<String, dynamic>;
          String attackId = attackData['id'];
          String attackerId = attackData['attacker'];

          if (attackId != lastSpecialAttackId && attackerId != myUserId) {
            lastSpecialAttackId = attackId;
            _playEnemySpecialAnimation(
              attackData['type'],
              attackData['target'],
            );
          }
        }

        String currentTurnUserId = data['currentTurn'];
        int newPlayerState = (currentTurnUserId == myUserId) ? 1 : 2;

        if (turnManager.currentPlayer != newPlayerState &&
            turnManager.currentPlayer != -1 &&
            isGameRunning) {
          await Future.delayed(const Duration(seconds: delay));
        }
        turnManager.currentPlayer = newPlayerState;
      } else {
        String myReadyField = amIHost ? 'player1Ready' : 'player2Ready';
        bool amIReady = data[myReadyField] ?? false;

        if (amIReady && turnManager.currentPlayer == 0) {
          turnManager.currentPlayer = -1; // Waiting state
        }
      }

      updateView();
    });
  }

  void _playEnemySpecialAnimation(String type, int target) {
    double scaledSquareSize = BattleShipsGame.squareLength * gridScale;

    BattleGrid myGrid = playersGrid;

    if (type == 'shark') {
      int rowY = target;
      double rowWorldY = myGrid.position.y + (rowY * scaledSquareSize);

      double gameWorldWidth = isNarrow
          ? scaledGridWidth + 10.0
          : (scaledGridWidth * 2) + gap + 10.0;

      world.add(
        SharkAnimation(
          targetY: rowWorldY,
          worldWidth: gameWorldWidth,
          cellSize: scaledSquareSize,
        ),
      );
      AudioManager.playMonster();
    } else if (type == 'octopus') {
      int gridX = target % squaresInGrid;
      int gridY = target ~/ squaresInGrid;

      Vector2 headPos = Vector2(
        myGrid.position.x + (gridX * scaledSquareSize),
        myGrid.position.y + ((gridY - 0.3) * scaledSquareSize),
      );

      world.add(
        OctopusHeadAnimation(
          targetPosition: headPos,
          cellSize: scaledSquareSize,
        ),
      );

      List<math.Point<int>> offsets = [
        const math.Point(0, -1),
        const math.Point(0, 1),
        const math.Point(-1, 0),
        const math.Point(1, 0),
      ];

      for (var offset in offsets) {
        Vector2 tentaclePos = Vector2(
          myGrid.position.x + ((gridX + offset.x) * scaledSquareSize),
          myGrid.position.y + (((gridY + offset.y) - 0.3) * scaledSquareSize),
        );
        if (gridX + offset.x >= 0 && gridX + offset.x < squaresInGrid) {
          world.add(
            TentacleAnimation(
              targetPosition: tentaclePos,
              cellSize: scaledSquareSize,
              flip: offset.x < 0,
            ),
          );
        }
      }
      AudioManager.playMonster();
    }
  }

  Future<void> sendPowerUpShots(List<int> indices, bool keepTurn) async {
    if (multiplayerGameId == null) return;

    String fieldToUpdate = amIHost ? 'shots_p1' : 'shots_p2';
    final gameRef =
        FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(gameRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      if (data['currentTurn'] != myUserId) return;

      Map<String, dynamic> updates = {
        fieldToUpdate: FieldValue.arrayUnion(indices),
      };

      if (!keepTurn) {
        String p1 = data['player1Id'];
        String p2 = data['player2Id'] ?? '';
        String nextTurnUser = (myUserId == p1) ? p2 : p1;
        updates['currentTurn'] = nextTurnUser;
      }

      transaction.update(gameRef, updates);
    });
  }

  Future<void> sendMoveToFirebase(int index) async {
    if (multiplayerGameId == null) return;
    String fieldToUpdate = amIHost ? 'shots_p1' : 'shots_p2';
    final gameRef =
        FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId);
    int gridY = index ~/ squaresInGrid;
    int gridX = index % squaresInGrid;
    bool isHit = false;
    if (gridY < squaresInGrid && gridX < squaresInGrid) {
      var element = opponentsGrid.grid[gridY][gridX];
      if (element is Bottle) {
        isHit = true;
      }
    }
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(gameRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      if (data['currentTurn'] != myUserId) return;
      String p1 = data['player1Id'];
      String p2 = data['player2Id'] ?? '';
      String nextTurnUser = (myUserId == p1) ? p2 : p1;
      Map<String, dynamic> updates = {
        fieldToUpdate: FieldValue.arrayUnion([index]),
      };
      if (!isHit) {
        updates['currentTurn'] = nextTurnUser;
      }
      transaction.update(gameRef, updates);
    });
  }

  Future<void> sendSpecialEffect(String type, int indexOrRow) async {
    if (multiplayerGameId == null) return;

    final gameRef =
        FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId);

    String attackId = DateTime.now().millisecondsSinceEpoch.toString();

    await gameRef.update({
      'lastSpecialAttack': {
        'id': attackId,
        'attacker': myUserId,
        'type': type,
        'target': indexOrRow,
      },
    });
  }

  void _syncShots(Map<String, dynamic> data) {
    List<dynamic> rawShotsP1 = data['shots_p1'] ?? [];
    List<dynamic> rawShotsP2 = data['shots_p2'] ?? [];
    List<dynamic> myShots = amIHost ? rawShotsP1 : rawShotsP2;
    List<dynamic> enemyShots = amIHost ? rawShotsP2 : rawShotsP1;
    int myCount = amIHost ? lastProcessedP1Shots : lastProcessedP2Shots;
    int enemyCount = amIHost ? lastProcessedP2Shots : lastProcessedP1Shots;
    if (myShots.length > myCount) {
      for (int i = myCount; i < myShots.length; i++) {
        if (myShots[i] is int) opponentsGrid.visualizeHit(myShots[i]);
      }
      if (amIHost) {
        lastProcessedP1Shots = myShots.length;
      } else {
        lastProcessedP2Shots = myShots.length;
      }
    }
    if (enemyShots.length > enemyCount) {
      for (int i = enemyCount; i < enemyShots.length; i++) {
        if (enemyShots[i] is int) playersGrid.visualizeHit(enemyShots[i]);
      }
      if (amIHost) {
        lastProcessedP2Shots = enemyShots.length;
      } else {
        lastProcessedP1Shots = enemyShots.length;
      }
    }
  }

  void checkWinner() {
    if (playersGrid.ships.isEmpty || opponentsGrid.ships.isEmpty) return;

    if (winnerMessage.isNotEmpty && !isGameRunning) return;

    bool playerLost = playersGrid.ships.length == playersGrid.shipsDown.length;
    bool enemyLost =
        opponentsGrid.ships.length == opponentsGrid.shipsDown.length;

    if (playerLost || enemyLost) {
      isGameRunning = false;
      turnManager.currentPlayer = -1;
      StatsService().recordGameResult(!playerLost, isMultiplayer);

      overlays.add('GameOverMenu');

      if (playerLost) {
        winnerMessage = "You Lost!";
        AudioManager.playLoss();
      } else {
        winnerMessage = "You Won!";
        AudioManager.playWin();

        overlays.add('WinnerConfetti');
      }

      updateView();
    }
  }

  void revealAllShips() {
    AudioManager.playBgm();
    for (var row in opponentsGrid.grid) {
      for (GridElement? element in row) {
        if (element is Bottle && element.condition.value == 0) {
          element.sprite = element.condition.sprite;
        }
      }
    }
    if (startButton.isMounted) world.remove(startButton);
    if (roundInfo.isMounted) world.remove(roundInfo);
    if (!returnToMenuButton.isMounted) world.add(returnToMenuButton);
  }

  Future<void> sendSharkAttack(int rowY, bool keepTurn) async {
    if (multiplayerGameId == null) return;

    final gameRef =
        FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId);

    List<int> rowIndices = List.generate(
      squaresInGrid,
      (x) => rowY * squaresInGrid + x,
    );

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(gameRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      if (data['currentTurn'] != myUserId) return;

      Map<String, dynamic> updates = {
        'shots_p1': FieldValue.arrayUnion(rowIndices),
        'shots_p2': FieldValue.arrayUnion(rowIndices),
      };

      if (!keepTurn) {
        String p1 = data['player1Id'];
        String p2 = data['player2Id'] ?? '';
        String nextTurnUser = (myUserId == p1) ? p2 : p1;
        updates['currentTurn'] = nextTurnUser;
      }

      transaction.update(gameRef, updates);
    });
  }

  @override
  void onTapDown(TapDownEvent event) {
    AudioManager.playBgm();
  }
}

class PlayerLabel extends PositionComponent {
  String _text = "";
  final TextPaint _textPaint;
  final Paint _bgPaint = Paint()..color = const Color(0xcc003366);
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  PlayerLabel({required TextPaint textRenderer})
      : _textPaint = textRenderer,
        super(priority: 10);

  set text(String value) {
    _text = value;
  }

  @override
  void render(Canvas canvas) {
    if (_text.isEmpty) return;

    final textSpan = TextSpan(text: _text, style: _textPaint.style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double width = textPainter.width;
    double height = textPainter.height;
    double padding = 1.0;

    Rect bgRect = Rect.fromCenter(
      center: Offset.zero,
      width: width + padding * 2,
      height: height + padding,
    );

    RRect rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(0.5));

    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);

    _textPaint.render(canvas, _text, Vector2.zero(), anchor: Anchor.center);
  }
}
