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
    });
  }

  Future<void> startGameFromLobby(String gameId) async {
    await _db.collection('battles').doc(gameId).update({
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

  Future<void> exitLobby(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('battles').doc(gameId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final String p1Id = data['player1Id'];

    if (p1Id == user.uid) {
      // JESTEŚ HOSTEM -> Usuń całą grę
      await deleteGame(gameId);
    } else {
      // JESTEŚ GOŚCIEM -> Opuść grę (wyczyść pola playera 2)
      await docRef.update({
        'player2Id': null,
        'player2Name': null,
        'player2Ready': false,
        'status': 'waiting',
      });
    }
  }

  Future<void> updateGameSettings(String gameId, int gridSize, Map<String, int> fleetCounts) async {
    await _db.collection('battles').doc(gameId).update({
      'gridSize': gridSize,
      'fleetCounts': fleetCounts,
    });
  }

  Future<void> addBulkStats(
      int wins, int losses,
      int sinkedEnemy, int sinkedSelf,
      int gamesSingle, int gamesMulti,
      int puTotal, int puOctopus, int puTriple, int puShark
      ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (wins == 0 && losses == 0 && gamesSingle == 0 && gamesMulti == 0 && puTotal == 0) return;

    final userRef = _db.collection('users').doc(user.uid);

    final updates = {
      'wins': FieldValue.increment(wins),
      'losses': FieldValue.increment(losses),
      'sinked_enemy_ships': FieldValue.increment(sinkedEnemy),
      'sinked_ships': FieldValue.increment(sinkedSelf),
      'games_single': FieldValue.increment(gamesSingle),
      'games_multi': FieldValue.increment(gamesMulti),
      'powerups_total': FieldValue.increment(puTotal),
      'powerups_octopus': FieldValue.increment(puOctopus),
      'powerups_triple_shot': FieldValue.increment(puTriple),
      'powerups_shark': FieldValue.increment(puShark),
    };

    await userRef.update(updates).catchError((error) async {
      await userRef.set({
        'wins': wins,
        'losses': losses,
        'sinked_enemy_ships': sinkedEnemy,
        'sinked_ships': sinkedSelf,
        'games_single': gamesSingle,
        'games_multi': gamesMulti,
        'powerups_total': puTotal,
        'powerups_octopus': puOctopus,
        'powerups_triple_shot': puTriple,
        'powerups_shark': puShark,
        'email': user.email,
        'username': user.displayName ?? 'Player',
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateWinningStats(bool won, bool isMultiplayer) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);

    Map<String, dynamic> updates = {};

    if (won) {
      updates['wins'] = FieldValue.increment(1);
    } else {
      updates['losses'] = FieldValue.increment(1);
    }

    if (isMultiplayer) {
      updates['games_multi'] = FieldValue.increment(1);
    } else {
      updates['games_single'] = FieldValue.increment(1);
    }

    await userRef.update(updates);
  }
  
  Future<void> updateSinkedStats(bool opponents) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final userRef = _db.collection('users').doc(user.uid);
    
    if (opponents) {
      await userRef.update({'sinked_enemy_ships' : FieldValue.increment(1)});
    } else {
      await userRef.update({'sinked_ships': FieldValue.increment(1)});
    }
    
  }

  Future<void> updatePowerUpStats(String type) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);

    Map<String, dynamic> updates = {
      'powerups_total': FieldValue.increment(1),
    };

    if (type == 'octopus') updates['powerups_octopus'] = FieldValue.increment(1);
    if (type == 'triple_shot') updates['powerups_triple_shot'] = FieldValue.increment(1);
    if (type == 'shark') updates['powerups_shark'] = FieldValue.increment(1);

    await userRef.update(updates);
  }

  Future<Map<String, int>> getUserStats() async {
    final user = _auth.currentUser;

    final Map<String, int> emptyStats = {
      'wins': 0, 'losses': 0,
      'sinked_enemy_ships': 0, 'sinked_ships': 0,
      'games_single': 0, 'games_multi': 0,
      'pu_total': 0, 'pu_octopus': 0, 'pu_triple': 0, 'pu_shark': 0
    };

    if (user == null) return emptyStats;

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (data == null) return emptyStats;

    return {
      'wins': (data['wins'] ?? 0) as int,
      'losses': (data['losses'] ?? 0) as int,
      'sinked_enemy_ships': (data['sinked_enemy_ships'] ?? 0) as int,
      'sinked_ships': (data['sinked_ships'] ?? 0) as int,
      'games_single': (data['games_single'] ?? 0) as int,
      'games_multi': (data['games_multi'] ?? 0) as int,
      'pu_total': (data['powerups_total'] ?? 0) as int,
      'pu_octopus': (data['powerups_octopus'] ?? 0) as int,
      'pu_triple': (data['powerups_triple_shot'] ?? 0) as int,
      'pu_shark': (data['powerups_shark'] ?? 0) as int,
    };
  }
}