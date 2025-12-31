import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getAvailableGames() {
    return _db
        .collection('battles')
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createGame() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("You're not logged in!");

    final docRef = await _db.collection('battles').add({
      'player1Id': user.uid,
      'player1Name': user.displayName ?? 'Player 1',
      'player2Id': null,
      'player2Name': null,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'currentTurn': user.uid, // Domyślnie zaczyna Host
      'player1Ready': false,
      'player2Ready': false,
    });

    return docRef.id;
  }

  Future<void> joinGame(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("You're not logged in!");

    await _db.collection('battles').doc(gameId).update({
      'player2Id': user.uid,
      'player2Name': user.displayName ?? 'Player 2',
      'status': 'playing',
    });
  }

  Future<void> deleteGame(String gameId) async {
    await _db.collection('battles').doc(gameId).delete();
  }
}