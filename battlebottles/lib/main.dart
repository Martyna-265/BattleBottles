import 'package:battlebottles/screens/BattleShipsGame.dart';
import 'package:battlebottles/screens/GameOverMenu.dart';
import 'package:battlebottles/screens/MultiplayerLobby.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final game = BattleShipsGame();

  runApp(
    MaterialApp(
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

                'GameOverMenu': (BuildContext context, BattleShipsGame game) {
                  return GameOverMenu(
                    game: game,
                    overlayId: 'GameOverMenu',
                  );
                },
              },
            );
          },
        ),
      ),
    ),
  );
}