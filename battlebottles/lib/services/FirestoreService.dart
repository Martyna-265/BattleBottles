import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveUserData(User user, String? username) async {
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'username': username ?? user.displayName ?? 'Unknown',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

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

  Stream<QuerySnapshot> getFriends() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .snapshots();
  }

  Future<void> addFriend(String friendEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Not logged in");

    final emailToSearch = friendEmail.trim();

    if (emailToSearch == currentUser.email) {
      throw Exception("You cannot add yourself.");
    }

    final querySnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: emailToSearch)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("User not found in database.");
    }

    final friendDoc = querySnapshot.docs.first;
    final friendData = friendDoc.data();
    final String friendId = friendDoc.id;
    final String friendName = friendData['username'] ?? friendData['email'] ?? 'Unknown';

    WriteBatch batch = _db.batch();

    // Dodaje znajomego do mojej kolekcji
    DocumentReference myFriendRef = _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .doc(friendId);

    batch.set(myFriendRef, {
      'email': friendEmail,
      'username': friendName,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // Dodaje mnie do kolekcji znajomego
    DocumentReference meInFriendRef = _db
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(currentUser.uid);

    final myName = currentUser.displayName ?? currentUser.email ?? 'Unknown Player';

    batch.set(meInFriendRef, {
      'email': currentUser.email,
      'username': myName,
      'addedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Usuwa znajomego obustronnie
  Future<void> removeFriend(String friendId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    WriteBatch batch = _db.batch();

    // Usuwa u mnie
    batch.delete(
        _db.collection('users').doc(currentUser.uid).collection('friends').doc(friendId)
    );

    // Usuwa mnie u niego
    batch.delete(
        _db.collection('users').doc(friendId).collection('friends').doc(currentUser.uid)
    );

    await batch.commit();
  }

  Future<void> cleanupOldGames() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 3));
    final Timestamp timestampCutoff = Timestamp.fromDate(cutoff);

    try {
      final snapshot = await _db
          .collection('battles')
          .where('status', isEqualTo: 'waiting')
          .where('createdAt', isLessThan: timestampCutoff)
          .get();

      if (snapshot.docs.isEmpty) return;

      WriteBatch batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint("CLEANUP: Deleted ${snapshot.docs.length} old games.");

    } catch (e) {
      debugPrint("CLEANUP ERROR: $e");
    }
  }

}