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
                  stream: _firestoreService.getFriends(), // 1. Pobieramy znajomych
                  builder: (context, friendsSnapshot) {
                    // Jeśli ładuje znajomych, czekamy (opcjonalnie można pominąć loader)
                    if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Tworzymy listę ID naszych znajomych
                    final List<String> friendIds = friendsSnapshot.data?.docs
                        .map((doc) => doc.id) // Zakładamy, że ID dokumentu to UID znajomego
                        .toList() ?? [];

                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getAvailableGames(), // 2. Pobieramy gry
                      builder: (context, gamesSnapshot) {
                        if (gamesSnapshot.hasError) {
                          return const Center(child: Text('Error loading games', style: TextStyle(color: Colors.red)));
                        }
                        if (gamesSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final allGames = gamesSnapshot.data!.docs;

                        // 3. FILTROWANIE: Pokaż tylko gry, gdzie host jest moim znajomym
                        final friendGames = allGames.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final hostId = data['player1Id'];
                          // Gra musi być stworzona przez kogoś z friendIds
                          return friendIds.contains(hostId);
                        }).toList();

                        if (friendGames.isEmpty) {
                          return Center(
                            child: Text(
                              friendIds.isEmpty
                                  ? 'Add friends to see their games!'
                                  : 'No active games from your friends.\nCreate one!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: friendGames.length,
                          itemBuilder: (context, index) {
                            final doc = friendGames[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final hostName = data['player1Name'] ?? 'Unknown';

                            return Card(
                              color: Colors.blue[900],
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: ListTile(
                                title: Text(
                                  hostName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text(
                                  'Friend\'s Lobby',
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () async {
                                    try {
                                      await _firestoreService.joinGame(doc.id);
                                      game.startMultiplayerGame(doc.id);
                                    } catch (e) {
                                      debugPrint("Error: $e");
                                    }
                                  },
                                  child: const Text('JOIN'),
                                ),
                              ),
                            );
                          },
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
                        debugPrint("Error: $e");
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