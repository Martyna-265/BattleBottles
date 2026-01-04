import 'package:battlebottles/BattleShipsGame.dart';
import 'package:battlebottles/screens/GameOverMenu.dart';
import 'package:battlebottles/screens/HelpScreen.dart';
import 'package:battlebottles/screens/MultiplayerLobby.dart';
import 'package:battlebottles/screens/GameOptionsScreen.dart';
import 'package:battlebottles/services/AudioManager.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AudioManager.init();

  final game = BattleShipsGame();

  runApp(BattleBottlesApp(game: game));
}

class BattleBottlesApp extends StatelessWidget {
  final BattleShipsGame game;

  const BattleBottlesApp({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Bottles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        backgroundColor: const Color(0xff7aa3cc),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return GameWidget(
              game: game,
              overlayBuilderMap: {
                'MultiplayerLobby': (BuildContext context, BattleShipsGame game) {
                  return MultiplayerLobby(
                    game: game,
                    onClose: () {
                      game.overlays.remove('MultiplayerLobby');
                    },
                  );
                },
                'GameOptionsScreen': (BuildContext context, BattleShipsGame game) {
                  return GameOptionsScreen(
                    game: game,
                    isMultiplayer: game.tempIsMultiplayer,
                    gameId: game.tempGameId,
                  );
                },
                'GameOverMenu': (BuildContext context, BattleShipsGame game) {
                  return GameOverMenu(
                    game: game,
                    overlayId: 'GameOverMenu',
                  );
                },
                'HelpScreen': (BuildContext context, BattleShipsGame game) {
                  return HelpScreen(game: game);
                },
              },
            );
          },
        ),
      ),
    );
  }
}