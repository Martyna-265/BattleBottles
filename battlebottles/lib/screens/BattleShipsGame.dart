import 'dart:ui';
import 'package:battlebottles/TurnManager.dart';
import 'package:battlebottles/components/BattleGrid.dart';
import 'package:battlebottles/components/buttons/ReturnToMenuButton.dart';
import 'package:battlebottles/screens/MainMenu.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/text.dart';
import '../components/Buttons/RestartButton.dart';
import '../components/Buttons/StartButton.dart';
import '../components/texts/RoundInfo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class BattleShipsGame extends FlameGame {

  static const double squareLength = 2.0;
  static final Vector2 squareSize = Vector2(squareLength, squareLength);
  static const int squaresInGrid = 9;
  static const double battleGridWidth = squaresInGrid * squareLength;
  static const double battleGridHeight = squaresInGrid * squareLength;
  static final Vector2 battleGridSize = Vector2(battleGridWidth, battleGridHeight);
  static const double gap = 10.0;
  static const int delay = 2;
  //static const double maxWidthForNarrow = 800;
  static const int bottleCount = 10;

  late TurnManager turnManager;
  late BattleGrid playersGrid;
  late BattleGrid opponentsGrid;
  late StartButton startButton;
  late RestartButton restartButton;
  late ReturnToMenuButton returnToMenuButton;
  late RoundInfo roundInfo;
  late MainMenu mainMenu;

  late TextComponent playerLabel;
  late TextComponent opponentLabel;

  // MULTIPLAYER
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

  bool get isNarrow => size.x < size.y;

  @override
  Color backgroundColor() => const Color(0xff84afdb);

  @override
  Future<void> onLoad() async {
    await Flame.images.load('Bottle1x1.png');

    turnManager = TurnManager(2, this);

    playersGrid = BattleGrid(false, bottleCount)..size = battleGridSize;
    opponentsGrid = BattleGrid(true, bottleCount)..size = battleGridSize;

    startButton = StartButton()..position = Vector2(gap, gap / 2)..anchor = Anchor.center;
    restartButton = RestartButton()..position = Vector2(gap + 4 * squareLength, gap / 2)..anchor = Anchor.center;
    returnToMenuButton = ReturnToMenuButton()..position = Vector2(gap + 8 * squareLength, gap / 2)..anchor = Anchor.center;
    roundInfo = RoundInfo()..position = Vector2(2 * gap, 2 * gap + battleGridHeight)..anchor = Anchor.center;

    final labelStyle = TextPaint(
      style: const TextStyle(fontSize: 1.2, color: Color(0xff003366), fontFamily: 'Awesome Font', fontWeight: FontWeight.bold),
    );

    playerLabel = TextComponent(textRenderer: labelStyle)..anchor = Anchor.topCenter;
    opponentLabel = TextComponent(textRenderer: labelStyle)..anchor = Anchor.topCenter;

    mainMenu = MainMenu();
    world.add(mainMenu);
    _isLoaded = true;

    camera.viewfinder.position = Vector2(0,0);
    camera.viewfinder.anchor = Anchor.topLeft;

  }

  void startGame() async {
    if (isGameRunning && !isMultiplayer) return;

    if (isMultiplayer) {
      if (multiplayerGameId == null) return;

      List<int> myShips = playersGrid.getShipPositions();
      String readyField = amIHost ? 'player1Ready' : 'player2Ready';
      String shipsField = amIHost ? 'ships_p1' : 'ships_p2';

      await FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId).update({
        readyField: true,
        shipsField: myShips,
      });

      if (turnManager.currentPlayer == 1 || turnManager.currentPlayer == 2) {
        return;
      }

      turnManager.currentPlayer = -1;
      if (startButton.isMounted) world.remove(startButton);
      updateView();

    } else {
      // SINGLEPLAYER START
      world.remove(mainMenu);
      world.add(playersGrid);
      world.add(playerLabel); playerLabel.text = "You";
      if (!isNarrow) { world.add(opponentsGrid); world.add(opponentLabel); opponentLabel.text = "Pirate"; }

      turnManager.currentPlayer = 0;
      world.add(startButton);
      world.add(restartButton);
      world.add(returnToMenuButton);
      world.add(roundInfo);

      isGameRunning = true;
      updateView();
    }
  }

  void startSingleplayerGame() {
    if (turnManager.currentPlayer != 0) return;

    if (startButton.isMounted) world.remove(startButton);
    turnManager.nextTurn();
    updateView();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    if (!_isLoaded) return;

    if (isGameRunning) {
      updateView();
    } else {
      camera.viewfinder.visibleGameSize = newSize;
      camera.viewfinder.position = Vector2(0,0);
      camera.viewfinder.anchor = Anchor.topLeft;
    }
  }

  void updateView() {
    if (!_isLoaded) return;
    if (!isGameRunning) return;

    visibleCurrentPlayer = turnManager.currentPlayer;

    void positionLabel(BattleGrid grid, TextComponent label) {
      label.position = Vector2(grid.position.x + battleGridWidth / 2, grid.position.y + battleGridHeight + 0.5);
    }

    if (isNarrow) {

      if (visibleCurrentPlayer == 1) {
        // TURA GRACZA -> POKAŻ GRID PRZECIWNIKA
        if (!opponentsGrid.isMounted) world.add(opponentsGrid);
        if (!opponentLabel.isMounted) world.add(opponentLabel);

        if (playersGrid.isMounted) world.remove(playersGrid);
        if (playerLabel.isMounted) world.remove(playerLabel);

        opponentsGrid.position = Vector2(gap, gap);
        positionLabel(opponentsGrid, opponentLabel);

      } else {
        // SETUP / OCZEKIWANIE / TURA WROGA -> POKAŻ MÓJ GRID

        if (!playersGrid.isMounted) world.add(playersGrid);
        if (!playerLabel.isMounted) world.add(playerLabel);

        if (opponentsGrid.isMounted) world.remove(opponentsGrid);
        if (opponentLabel.isMounted) world.remove(opponentLabel);

        playersGrid.position = Vector2(gap, gap);
        positionLabel(playersGrid, playerLabel);
      }

    } else {
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
    double totalWidth; double totalHeight;
    if (isNarrow) {
      totalWidth = battleGridWidth + 2 * gap;
      totalHeight = battleGridHeight + 2 * gap + 2.0;
      camera.viewfinder.visibleGameSize = Vector2(totalWidth, totalHeight);
      camera.viewfinder.position = Vector2(totalWidth / 2, 0); camera.viewfinder.anchor = Anchor.topCenter;
    } else {
      totalWidth = battleGridWidth * 2 + 3 * gap;
      totalHeight = battleGridHeight + 2 * gap + 2.0;
      camera.viewfinder.visibleGameSize = Vector2(totalWidth, totalHeight);
      camera.viewfinder.position = Vector2(totalWidth / 2, 0); camera.viewfinder.anchor = Anchor.topCenter;
    }
  }

  void restartGame() { restartGameInternalState(); if (!startButton.isMounted) world.add(startButton); updateView(); }

  void returnToMenu() {
    if (!isGameRunning) return;
    gameStream?.cancel();
    isMultiplayer = false;

    final componentsToRemove = [
      playersGrid,
      opponentsGrid,
      playerLabel,
      opponentLabel,
      startButton,
      restartButton,
      returnToMenuButton,
      roundInfo
    ];

    world.removeAll(componentsToRemove.where((c) => c.isMounted));

    world.add(mainMenu);

    camera.viewfinder.position = Vector2(0, 0);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;
    camera.viewfinder.visibleGameSize = size;

    mainMenu.onGameResize(size);

    isGameRunning = false;
    restartGameInternalState();
  }

  void restartGameInternalState() {
    turnManager.reset();
    visibleCurrentPlayer = 0;
    playersGrid.regenerateGrid();
    opponentsGrid.regenerateGrid();
    lastProcessedP1Shots = 0;
    lastProcessedP2Shots = 0;
  }

  void openMultiplayerLobby() { overlays.add('MultiplayerLobby'); }

  void startMultiplayerGame(String gameId) {
    if (isGameRunning) return;
    overlays.remove('MultiplayerLobby');
    isMultiplayer = true;
    multiplayerGameId = gameId;
    myUserId = FirebaseAuth.instance.currentUser?.uid;

    restartGameInternalState();
    world.remove(mainMenu);
    world.add(playersGrid); world.add(playerLabel);
    if (!isNarrow) { world.add(opponentsGrid); world.add(opponentLabel); }
    world.add(startButton);
    world.add(returnToMenuButton);
    world.add(roundInfo);
    isGameRunning = true;
    updateView();
    _listenToMultiplayerChanges();
  }

  @override
  void onDetach() { gameStream?.cancel(); super.onDetach(); }

  Future<void> sendMoveToFirebase(int index) async {
    if (multiplayerGameId == null) return;
    String fieldToUpdate = amIHost ? 'shots_p1' : 'shots_p2';
    final gameRef = FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(gameRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;

      if (data['currentTurn'] != myUserId) return;

      String p1 = data['player1Id']; String p2 = data['player2Id'];
      String nextTurnUser = (myUserId == p1) ? p2 : p1;
      transaction.update(gameRef, { fieldToUpdate: FieldValue.arrayUnion([index]), 'currentTurn': nextTurnUser });
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
      for (int i = myCount; i < myShots.length; i++) { if (myShots[i] is int) opponentsGrid.visualizeHit(myShots[i]); }
      if (amIHost) lastProcessedP1Shots = myShots.length; else lastProcessedP2Shots = myShots.length;
    }
    if (enemyShots.length > enemyCount) {
      for (int i = enemyCount; i < enemyShots.length; i++) { if (enemyShots[i] is int) playersGrid.visualizeHit(enemyShots[i]); }
      if (amIHost) lastProcessedP2Shots = enemyShots.length; else lastProcessedP1Shots = enemyShots.length;
    }
  }

  void _listenToMultiplayerChanges() {
    if (multiplayerGameId == null) return;

    gameStream = FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      if (data['player1Id'] == myUserId) amIHost = true; else amIHost = false;

      String p1Name = data['player1Name'] ?? 'Player 1';
      String p2Name = data['player2Name'] ?? 'Player 2';
      if (amIHost) { playerLabel.text = "You ($p1Name)"; opponentLabel.text = p2Name; }
      else { playerLabel.text = "You ($p2Name)"; opponentLabel.text = p1Name; }

      bool p1Ready = data['player1Ready'] ?? false;
      bool p2Ready = data['player2Ready'] ?? false;

      if (p1Ready && p2Ready) {
        if (!turnManager.hasShipsSynced) {
          List<dynamic> enemyShipsPositions = amIHost ? (data['ships_p2'] ?? []) : (data['ships_p1'] ?? []);
          opponentsGrid.setEnemyShips(enemyShipsPositions);
          turnManager.hasShipsSynced = true;
        }

        String currentTurnUserId = data['currentTurn'];
        if (currentTurnUserId == myUserId) {
          turnManager.currentPlayer = 1;
        } else {
          turnManager.currentPlayer = 2;
        }

        if (startButton.isMounted) world.remove(startButton);
        isGameRunning = true;
        updateView();

      } else {
        if (turnManager.currentPlayer != 0) {
          turnManager.currentPlayer = -1;
          updateView();
        }
      }

      _syncShots(data);
    });
  }
}