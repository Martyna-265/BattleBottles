import 'package:battlebottles/screens/BattleShipsGame.dart';
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return GameWidget(
              game: game,
              // --- DODAJEMY MAPĘ NAKŁADEK (OVERLAYS) ---
              overlayBuilderMap: {
                'MultiplayerLobby': (BuildContext context, BattleShipsGame game) {
                  return MultiplayerLobby(
                    game: game,
                    onClose: () {
                      // Funkcja zamykająca lobby
                      game.overlays.remove('MultiplayerLobby');
                    },
                  );
                },
              },
              // -----------------------------------------
            );
          },
        ),
      ),
    ),
  );
}