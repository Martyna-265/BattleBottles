import 'dart:ui';
import 'package:battlebottles/TurnManager.dart';
import 'package:battlebottles/components/BattleGrid.dart';
import 'package:battlebottles/components/buttons/ReturnToMenuButton.dart';
import 'package:battlebottles/screens/MainMenu.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/text.dart';
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

class BattleShipsGame extends FlameGame {

  static const double squareLength = 2.0;
  static final Vector2 squareSize = Vector2(squareLength, squareLength);
  static const int squaresInGrid = 9;
  static const double battleGridWidth = squaresInGrid * squareLength;
  static const double battleGridHeight = squaresInGrid * squareLength;
  static final Vector2 battleGridSize = Vector2(battleGridWidth, battleGridHeight);
  static const double gap = 10.0;
  static const int delay = 2;
  static const int bottleCount = 10;

  late TurnManager turnManager;
  late BattleGrid playersGrid;
  late BattleGrid opponentsGrid;
  late StartButton startButton;
  late RestartButton restartButton;
  late ReturnToMenuButton returnToMenuButton;
  late RoundInfo roundInfo;
  late ActionFeedback actionFeedback;
  late MainMenu mainMenu;

  late ShipsCounter playerCounter;
  late ShipsCounter opponentCounter;

  late TextComponent playerLabel;
  late TextComponent opponentLabel;

  String winnerMessage = '';

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

  bool isInMenu = true;

  bool get isNarrow => size.x < size.y;

  @override
  Color backgroundColor() => const Color(0xff84afdb);

  @override
  Future<void> onLoad() async {
    await Flame.images.load('Bottle1x1.png');

    turnManager = TurnManager(2, this);

    playersGrid = BattleGrid(false, bottleCount)..size = battleGridSize;
    opponentsGrid = BattleGrid(true, bottleCount)..size = battleGridSize;

    playerCounter = ShipsCounter(playersGrid);
    opponentCounter = ShipsCounter(opponentsGrid);

    startButton = StartButton()..position = Vector2(gap, gap / 2)..anchor = Anchor.center;
    restartButton = RestartButton()..position = Vector2(gap + 4 * squareLength, gap / 2)..anchor = Anchor.center;
    returnToMenuButton = ReturnToMenuButton()..position = Vector2(gap + 8 * squareLength, gap / 2)..anchor = Anchor.center;

    roundInfo = RoundInfo()..position = Vector2(2 * gap, 2 * gap + battleGridHeight)..anchor = Anchor.center;
    actionFeedback = ActionFeedback()
      ..position = Vector2(2 * gap, 2 * gap + battleGridHeight + 3.0)
      ..anchor = Anchor.center;

    final labelStyle = TextPaint(
      style: const TextStyle(fontSize: 1.2, color: Color(0xff003366), fontFamily: 'Awesome Font', fontWeight: FontWeight.bold),
    );

    playerLabel = TextComponent(textRenderer: labelStyle)..anchor = Anchor.topCenter;
    opponentLabel = TextComponent(textRenderer: labelStyle)..anchor = Anchor.topCenter;

    mainMenu = MainMenu();
    world.add(mainMenu);
    isInMenu = true;
    _isLoaded = true;

    camera.viewfinder.position = Vector2(0,0);
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  void startGame() async {
    if (isGameRunning && !isMultiplayer) return;

    if (isMultiplayer) {
      if (multiplayerGameId == null) return;

      List<Map<String, dynamic>> myShipsData = playersGrid.getShipsData();
      if (myShipsData.isEmpty) return;

      String readyField = amIHost ? 'player1Ready' : 'player2Ready';
      String shipsField = amIHost ? 'ships_p1' : 'ships_p2';

      await FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId).update({
        readyField: true,
        shipsField: myShipsData,
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
      isInMenu = false;

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
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_isLoaded) return;

    if (isInMenu) {
      camera.viewfinder.visibleGameSize = size;
      camera.viewfinder.position = Vector2(0,0);
      camera.viewfinder.anchor = Anchor.topLeft;
    } else {
      updateView();
      _updateCamera();
    }
  }

  void updateView() {
    if (!_isLoaded) return;
    if (isInMenu) return;

    visibleCurrentPlayer = turnManager.currentPlayer;

    void positionLabel(BattleGrid grid, TextComponent label) {
      label.position = Vector2(grid.position.x + battleGridWidth / 2, grid.position.y + battleGridHeight + 0.5);
    }

    void positionCounter(BattleGrid grid, ShipsCounter counter) {
      counter.position = Vector2(grid.position.x, grid.position.y + battleGridHeight + gap/4);
    }

    // WĄSKI EKRAN
    if (isNarrow) {
      bool showOpponent = (!isGameRunning && !isInMenu && visibleCurrentPlayer != 0) || (visibleCurrentPlayer == 1);

      if (showOpponent) {
        // Pokaż Grid Przeciwnika (Strzelanie lub Game Over)
        if (!actionFeedback.isMounted) world.add(actionFeedback);
        if (!opponentsGrid.isMounted) world.add(opponentsGrid);
        if (!opponentLabel.isMounted) world.add(opponentLabel);
        if (!opponentCounter.isMounted) world.add(opponentCounter);
        if (playersGrid.isMounted) world.remove(playersGrid);
        if (playerLabel.isMounted) world.remove(playerLabel);
        if (playerCounter.isMounted) world.remove(playerCounter);
        opponentsGrid.position = Vector2(gap, gap);
        positionLabel(opponentsGrid, opponentLabel);
        positionCounter(opponentsGrid, opponentCounter);
      } else {
        // Pokaż Mój Grid (Tura Wroga, Setup)
        if (!actionFeedback.isMounted) world.add(actionFeedback);
        if (!playersGrid.isMounted) world.add(playersGrid);
        if (!playerLabel.isMounted) world.add(playerLabel);
        if (!playerCounter.isMounted) world.add(playerCounter);
        if (opponentsGrid.isMounted) world.remove(opponentsGrid);
        if (opponentLabel.isMounted) world.remove(opponentLabel);
        if (opponentCounter.isMounted) world.remove(opponentCounter);
        playersGrid.position = Vector2(gap, gap);
        positionLabel(playersGrid, playerLabel);
        positionCounter(playersGrid, playerCounter);
      }
    } else {
      // Szeroki ekran - zawsze oba
      if (!actionFeedback.isMounted) world.add(actionFeedback);
      if (!playersGrid.isMounted) world.add(playersGrid);
      if (!playerLabel.isMounted) world.add(playerLabel);
      if (!playerCounter.isMounted) world.add(playerCounter);
      if (!opponentsGrid.isMounted) world.add(opponentsGrid);
      if (!opponentLabel.isMounted) world.add(opponentLabel);
      if (!opponentCounter.isMounted) world.add(opponentCounter);

      playersGrid.position = Vector2(gap, gap);
      positionLabel(playersGrid, playerLabel);
      positionCounter(playersGrid, playerCounter);

      opponentsGrid.position = Vector2(gap + battleGridWidth + gap, gap);
      positionLabel(opponentsGrid, opponentLabel);
      positionCounter(opponentsGrid, opponentCounter);
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

  void restartGame() {
    isGameRunning = true;
    restartGameInternalState();

    if (!startButton.isMounted) world.add(startButton);
    if (!restartButton.isMounted) world.add(restartButton);
    if (!returnToMenuButton.isMounted) world.add(returnToMenuButton);
    if (!roundInfo.isMounted) world.add(roundInfo);

    updateView();
    _updateCamera();
  }

  void returnToMenu() {
    gameStream?.cancel();
    isMultiplayer = false;
    isGameRunning = false;

    final componentsToRemove = [
      playersGrid,
      opponentsGrid,
      playerLabel,
      opponentLabel,
      startButton,
      restartButton,
      returnToMenuButton,
      roundInfo,
      playerCounter,
      opponentCounter
    ];

    world.removeAll(componentsToRemove.where((c) => c.isMounted));

    if (actionFeedback.isMounted) actionFeedback.reset();

    world.add(mainMenu);
    isInMenu = true;

    camera.viewfinder.position = Vector2(0, 0);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;
    camera.viewfinder.visibleGameSize = size;

    mainMenu.onGameResize(size);

    restartGameInternalState();
  }

  void restartGameInternalState() {
    turnManager.reset();
    visibleCurrentPlayer = 0;
    playersGrid.regenerateGrid();
    opponentsGrid.regenerateGrid();
    lastProcessedP1Shots = 0;
    lastProcessedP2Shots = 0;
    if (actionFeedback.isMounted) actionFeedback.reset();
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
    isInMenu = false;

    world.add(playersGrid);
    world.add(playerLabel);
    world.add(playerCounter);
    if (!isNarrow) {
      world.add(opponentsGrid);
      world.add(opponentLabel);
      world.add(opponentCounter);
    }
    world.add(startButton);
    world.add(returnToMenuButton);
    world.add(roundInfo);
    updateView();
    _listenToMultiplayerChanges();
  }

  @override
  void onDetach() { gameStream?.cancel(); super.onDetach(); }

  Future<void> sendMoveToFirebase(int index) async {
    if (multiplayerGameId == null) return;

    String fieldToUpdate = amIHost ? 'shots_p1' : 'shots_p2';
    final gameRef = FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId);

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

      // Zabezpieczenie: strzelaj tylko w swojej turze
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

  void _syncShots(Map<String, dynamic> data) {
    List<dynamic> rawShotsP1 = data['shots_p1'] ?? [];
    List<dynamic> rawShotsP2 = data['shots_p2'] ?? [];

    List<dynamic> myShots = amIHost ? rawShotsP1 : rawShotsP2;
    List<dynamic> enemyShots = amIHost ? rawShotsP2 : rawShotsP1;

    int myCount = amIHost ? lastProcessedP1Shots : lastProcessedP2Shots;
    int enemyCount = amIHost ? lastProcessedP2Shots : lastProcessedP1Shots;

    if (myShots.length > myCount) {
      for (int i = myCount; i < myShots.length; i++) { if (myShots[i] is int) opponentsGrid.visualizeHit(myShots[i]); }
      if (amIHost) {
        lastProcessedP1Shots = myShots.length;
      } else {
        lastProcessedP2Shots = myShots.length;
      }
    }
    if (enemyShots.length > enemyCount) {
      for (int i = enemyCount; i < enemyShots.length; i++) { if (enemyShots[i] is int) playersGrid.visualizeHit(enemyShots[i]); }
      if (amIHost) {
        lastProcessedP2Shots = enemyShots.length;
      } else {
        lastProcessedP1Shots = enemyShots.length;
      }
    }
  }

  void _listenToMultiplayerChanges() {
    if (multiplayerGameId == null) return;

    gameStream = FirebaseFirestore.instance.collection('battles').doc(multiplayerGameId).snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      if (data['player1Id'] == myUserId) {
        amIHost = true;
      } else {
        amIHost = false;

        String p1Name = data['player1Name'] ?? 'Player 1';
        String p2Name = data['player2Name'] ?? 'Player 2';
        if (amIHost) { playerLabel.text = "You ($p1Name)"; opponentLabel.text = p2Name; }
        else { playerLabel.text = "You ($p2Name)"; opponentLabel.text = p1Name; }

        bool p1Ready = data['player1Ready'] ?? false;
        bool p2Ready = data['player2Ready'] ?? false;

        if (p1Ready && p2Ready) {
          if (!turnManager.hasShipsSynced) {
            List<dynamic> enemyShipsPositions = amIHost ? (data['ships_p2'] ?? []) : (data['ships_p1'] ?? []);
            if (enemyShipsPositions.isNotEmpty) {
              opponentsGrid.setEnemyShips(enemyShipsPositions);
              turnManager.hasShipsSynced = true;
              isGameRunning = true;
            }
          }

          if (startButton.isMounted) world.remove(startButton);

          _syncShots(data);

          String currentTurnUserId = data['currentTurn'];
          int newPlayerState = (currentTurnUserId == myUserId) ? 1 : 2;

          if (turnManager.currentPlayer != newPlayerState && turnManager.currentPlayer != -1 && isGameRunning) {
            await Future.delayed(const Duration(seconds: delay));
          }

          turnManager.currentPlayer = newPlayerState;
          updateView();

        } else {
          if (turnManager.currentPlayer != 0) {
            turnManager.currentPlayer = -1;
            updateView();
          }
        }
      }
    });
  }

  void checkWinner() {
    if (playersGrid.ships.isEmpty || opponentsGrid.ships.isEmpty) return;

    if (winnerMessage.isNotEmpty && !isGameRunning) return;

    bool playerLost = playersGrid.ships.length == playersGrid.shipsDown.length;
    bool enemyLost = opponentsGrid.ships.length == opponentsGrid.shipsDown.length;

    if (playerLost || enemyLost) {
      isGameRunning = false;
      turnManager.currentPlayer = -1;

      if (playerLost) {
        winnerMessage = "You Lost!";
      } else {
        winnerMessage = "You Won!";
      }

      overlays.add('GameOverMenu');
      updateView();
    }
  }

  void revealAllShips() {
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
}