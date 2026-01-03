import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'FirestoreService.dart';

class StatsService {
  final FirestoreService _firestore = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _keyWins = 'local_wins';
  static const String _keyLosses = 'local_losses';

  static const String _keySinkedEnemy = 'local_sinked_enemy_ships';
  static const String _keySinkedSelf = 'local_sinked_ships';

  static const String _keyGamesSingle = 'local_games_single';
  static const String _keyGamesMulti = 'local_games_multi';

  static const String _keyPuTotal = 'local_pu_total';
  static const String _keyPuOctopus = 'local_pu_octopus';
  static const String _keyPuTriple = 'local_pu_triple';
  static const String _keyPuShark = 'local_pu_shark';

  Future<void> recordGameResult(bool won, bool isMultiplayer) async {
    if (_auth.currentUser != null) {
      await _firestore.updateWinningStats(won, isMultiplayer);
    } else {
      final prefs = await SharedPreferences.getInstance();

      if (won) {
        int wins = prefs.getInt(_keyWins) ?? 0;
        await prefs.setInt(_keyWins, wins + 1);
      } else {
        int losses = prefs.getInt(_keyLosses) ?? 0;
        await prefs.setInt(_keyLosses, losses + 1);
      }

      if (isMultiplayer) {
        int multi = prefs.getInt(_keyGamesMulti) ?? 0;
        await prefs.setInt(_keyGamesMulti, multi + 1);
      } else {
        int single = prefs.getInt(_keyGamesSingle) ?? 0;
        await prefs.setInt(_keyGamesSingle, single + 1);
      }
    }
  }

  Future<void> recordSinkedShip(bool opponents) async {
    if (_auth.currentUser != null) {
      await _firestore.updateSinkedStats(opponents);
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (opponents) {
        int val = prefs.getInt(_keySinkedEnemy) ?? 0;
        await prefs.setInt(_keySinkedEnemy, val + 1);
      } else {
        int val = prefs.getInt(_keySinkedSelf) ?? 0;
        await prefs.setInt(_keySinkedSelf, val + 1);
      }
    }
  }

  Future<void> recordPowerUpUse(String type) async {
    if (_auth.currentUser != null) {
      // Online
      await _firestore.updatePowerUpStats(type);
    } else {
      // Local
      final prefs = await SharedPreferences.getInstance();

      int total = prefs.getInt(_keyPuTotal) ?? 0;
      await prefs.setInt(_keyPuTotal, total + 1);

      if (type == 'octopus') {
        int val = prefs.getInt(_keyPuOctopus) ?? 0;
        await prefs.setInt(_keyPuOctopus, val + 1);
      } else if (type == 'triple_shot') {
        int val = prefs.getInt(_keyPuTriple) ?? 0;
        await prefs.setInt(_keyPuTriple, val + 1);
      } else if (type == 'shark') {
        int val = prefs.getInt(_keyPuShark) ?? 0;
        await prefs.setInt(_keyPuShark, val + 1);
      }
    }
  }

  Future<Map<String, int>> getStats() async {
    if (_auth.currentUser != null) {
      return await _firestore.getUserStats();
    } else {
      final prefs = await SharedPreferences.getInstance();
      return {
        'wins': prefs.getInt(_keyWins) ?? 0,
        'losses': prefs.getInt(_keyLosses) ?? 0,
        'sinked_enemy_ships': prefs.getInt(_keySinkedEnemy) ?? 0,
        'sinked_ships': prefs.getInt(_keySinkedSelf) ?? 0,
        'games_single': prefs.getInt(_keyGamesSingle) ?? 0,
        'games_multi': prefs.getInt(_keyGamesMulti) ?? 0,
        'pu_total': prefs.getInt(_keyPuTotal) ?? 0,
        'pu_octopus': prefs.getInt(_keyPuOctopus) ?? 0,
        'pu_triple': prefs.getInt(_keyPuTriple) ?? 0,
        'pu_shark': prefs.getInt(_keyPuShark) ?? 0,
      };
    }
  }

  Future<void> syncLocalStatsToAccount() async {
    if (_auth.currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();

    int lWins = prefs.getInt(_keyWins) ?? 0;
    int lLosses = prefs.getInt(_keyLosses) ?? 0;
    int lSinkEnemy = prefs.getInt(_keySinkedEnemy) ?? 0;
    int lSinkSelf = prefs.getInt(_keySinkedSelf) ?? 0;
    int lSingle = prefs.getInt(_keyGamesSingle) ?? 0;
    int lMulti = prefs.getInt(_keyGamesMulti) ?? 0;

    int lPuTotal = prefs.getInt(_keyPuTotal) ?? 0;
    int lPuOctopus = prefs.getInt(_keyPuOctopus) ?? 0;
    int lPuTriple = prefs.getInt(_keyPuTriple) ?? 0;
    int lPuShark = prefs.getInt(_keyPuShark) ?? 0;

    if (lWins > 0 || lLosses > 0 || lSinkEnemy > 0 || lSinkSelf > 0 ||
        lSingle > 0 || lMulti > 0 || lPuTotal > 0) {

      await _firestore.addBulkStats(
          lWins, lLosses, lSinkEnemy, lSinkSelf, lSingle, lMulti,
          lPuTotal, lPuOctopus, lPuTriple, lPuShark
      );

      await prefs.setInt(_keyWins, 0);
      await prefs.setInt(_keyLosses, 0);
      await prefs.setInt(_keySinkedEnemy, 0);
      await prefs.setInt(_keySinkedSelf, 0);
      await prefs.setInt(_keyGamesSingle, 0);
      await prefs.setInt(_keyGamesMulti, 0);

      await prefs.setInt(_keyPuTotal, 0);
      await prefs.setInt(_keyPuOctopus, 0);
      await prefs.setInt(_keyPuTriple, 0);
      await prefs.setInt(_keyPuShark, 0);
    }
  }
}