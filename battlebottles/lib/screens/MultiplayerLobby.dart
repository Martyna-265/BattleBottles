import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/FirestoreService.dart';
import '../screens/BattleShipsGame.dart';

class MultiplayerLobby extends StatelessWidget {
  final BattleShipsGame game;
  final VoidCallback onClose;

  MultiplayerLobby({Key? key, required this.game, required this.onClose}) : super(key: key);

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xAA000000),
      body: Center(
        child: Container(
          width: 400,
          height: 600,
          decoration: BoxDecoration(
            color: const Color(0xff003366),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            children: [
              // Nagłówek
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MULTIPLAYER LOBBY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Awesome Font',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getAvailableGames(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Database error', style: TextStyle(color: Colors.red)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final games = snapshot.data!.docs;

                    if (games.isEmpty) {
                      return const Center(
                        child: Text(
                          'No available games.\nCreate a new one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final doc = games[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final hostName = data['player1Name'] ?? 'Unknown';

                        return Card(
                          color: Colors.blue[900],
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: const Icon(Icons.person, color: Colors.white),
                            title: Text(
                              hostName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: const Text(
                              'Waiting...',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () async {
                                try {
                                  await _firestoreService.joinGame(doc.id);
                                  game.startMultiplayerGame(doc.id);
                                } catch (e) {
                                  print("Error: $e");
                                }
                              },
                              child: const Text('PLAY'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Przycisk Create
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () async {
                      try {
                        String gameId = await _firestoreService.createGame();
                        // Host od razu startuje grę (do zmiany)
                        game.startMultiplayerGame(gameId);
                      } catch (e) {
                        print("Error: $e");
                      }
                    },
                    child: const Text(
                      'CREATE A NEW GAME',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}