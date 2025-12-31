import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Strumień dostępnych gier (tylko te ze statusem 'waiting')
  Stream<QuerySnapshot> getAvailableGames() {
    return _db
        .collection('battles')
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Funkcja: Stwórz nową grę
  Future<String> createGame() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("You're not logged in!");

    // Tworzymy dokument gry
    final docRef = await _db.collection('battles').add({
      'player1Id': user.uid,
      'player1Name': user.displayName ?? 'Player 1',
      'player2Id': null, // Na razie brak przeciwnika
      'player2Name': null,
      'status': 'waiting', // Oczekujemy na gracza
      'createdAt': FieldValue.serverTimestamp(),
      'currentTurn': user.uid, // Zaczyna ten, kto stworzył (można zmienić na losowe)
    });

    return docRef.id; // Zwracamy ID gry, żeby wiedzieć, czego nasłuchiwać
  }

  // Funkcja: Dołącz do istniejącej gry
  Future<void> joinGame(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("You're not logged in!");

    await _db.collection('battles').doc(gameId).update({
      'player2Id': user.uid,
      'player2Name': user.displayName ?? 'Player 2',
      'status': 'playing', // Zmieniamy status na 'gra w toku'
    });
  }

  // Funkcja do czyszczenia gier (opcjonalnie, do testów)
  Future<void> deleteGame(String gameId) async {
    await _db.collection('battles').doc(gameId).delete();
  }
}