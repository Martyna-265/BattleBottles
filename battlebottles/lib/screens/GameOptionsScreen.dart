import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../BattleShipsGame.dart';
import '../services/FirestoreService.dart';

class GameOptionsScreen extends StatefulWidget {
  final BattleShipsGame game;
  final bool isMultiplayer;
  final String? gameId;

  const GameOptionsScreen({
    super.key,
    required this.game,
    required this.isMultiplayer,
    this.gameId,
  });

  @override
  State<GameOptionsScreen> createState() => _GameOptionsScreenState();
}

class _GameOptionsScreenState extends State<GameOptionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  static const double _maxShipSpace = 0.4;

  int _gridSize = 10;
  Map<String, int> _fleetCounts = {
    "4": 2,
    "3": 3,
    "2": 3,
    "1": 4,
  };

  Map<String, int> _powerUpCounts = {
    "octopus": 2,
    "triple": 1,
    "shark": 1,
  };

  bool _isUpdating = false;

  bool _canFitInGrid(int size) {
    int totalOccupied = 0;
    _fleetCounts.forEach((key, c) {
      totalOccupied += int.parse(key) * c;
    });

    int maxCapacity = (size * size * _maxShipSpace).floor();
    return totalOccupied <= maxCapacity;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
        )
    );
  }

  Future<void> _updateSettings() async {
    if (!widget.isMultiplayer || widget.gameId == null) return;

    setState(() => _isUpdating = true);
    try {
      await _firestoreService.updateGameSettings(widget.gameId!, _gridSize, _fleetCounts, _powerUpCounts);
    } catch (e) {
      debugPrint("Error updating settings: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _modifyPowerUpCount(String key, int delta) {
    if (_isUpdating && widget.isMultiplayer) return;

    int current = _powerUpCounts[key] ?? 0;
    int newCount = current + delta;

    if (newCount < 0) return;
    if (newCount > 10) return;

    setState(() {
      _powerUpCounts[key] = newCount;
    });

    _updateSettings();
  }

  void _modifyShipCount(String sizeKey, int delta) {
    if (_isUpdating && widget.isMultiplayer) return;

    int current = _fleetCounts[sizeKey] ?? 0;
    int shipSize = int.parse(sizeKey);
    int newCount = current + delta;

    if (newCount < 0) return;

    int currentOccupied = 0;
    _fleetCounts.forEach((key, c) {
      currentOccupied += int.parse(key) * c;
    });
    int newOccupied = currentOccupied - (current * shipSize) + (newCount * shipSize);

    int maxCapacity = (_gridSize * _gridSize * _maxShipSpace).floor();

    if (newOccupied > maxCapacity && delta > 0) {
      _showError("Not enough space! Increase grid size first.");
      return;
    }

    if (newOccupied == 0 && delta < 0) {
      _showError("Fleet cannot be empty!");
      return;
    }

    setState(() {
      _fleetCounts[sizeKey] = newCount;
    });

    _updateSettings();
  }

  void _onGridSizeChanged(double value) {
    if (_isUpdating && widget.isMultiplayer) return;

    int newSize = value.toInt();

    if (newSize < _gridSize) {
      if (!_canFitInGrid(newSize)) {
        _showError("Too many ships for ${newSize}x$newSize grid! Remove ships first.");
        return;
      }
    }

    setState(() => _gridSize = newSize);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xAA000000),
      body: Center(
        child: Container(
          width: 700,
          height: 600,
          decoration: BoxDecoration(
            color: const Color(0xff003366),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: widget.isMultiplayer ? _buildMultiplayerStream() : _buildSingleplayerView(),
        ),
      ),
    );
  }

  Widget _buildMultiplayerStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('battles').doc(widget.gameId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.game.overlays.isActive('GameOptionsScreen')) {
              widget.game.overlays.remove('GameOptionsScreen');
            }
          });
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String status = data['status'];
        final String p1Id = data['player1Id'];
        final bool amIHost = currentUserId == p1Id;

        final String p1Name = data['player1Name'] ?? 'Player 1';
        final String? p2Name = data['player2Name'];

        if (!amIHost) {
          if (data['gridSize'] != null) _gridSize = data['gridSize'];
          if (data['fleetCounts'] != null) {
            _fleetCounts = Map<String, int>.from(data['fleetCounts']);
          }
          if (data['powerUps'] != null) {
            _powerUpCounts = Map<String, int>.from(data['powerUps']);
          }
        }

        if (status == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.game.overlays.isActive('GameOptionsScreen')) {
              widget.game.overlays.remove('GameOptionsScreen');
              widget.game.startMultiplayerGame(
                  widget.gameId!,
                  gridSize: _gridSize,
                  fleetCounts: _fleetCounts,
                  powerUps: _powerUpCounts,
                  p1Name: p1Name,
                  p2Name: p2Name,
                  p1Id: p1Id
              );            }
          });
        }

        return _buildContent(
          amIHost: amIHost,
          p1Name: data['player1Name'] ?? 'Host',
          p2Name: data['player2Name'],
          onStart: amIHost ? () async {
            if (_isUpdating) return;
            await _updateSettings();
            await _firestoreService.startGameFromLobby(widget.gameId!);
          } : null,
          onLeave: () async {
            await _firestoreService.exitLobby(widget.gameId!);
            widget.game.overlays.remove('GameOptionsScreen');
          },
        );
      },
    );
  }

  Widget _buildSingleplayerView() {
    return _buildContent(
      amIHost: true,
      p1Name: "You",
      p2Name: "Computer",
      onStart: () {
        widget.game.overlays.remove('GameOptionsScreen');
        widget.game.startGame(gridSize: _gridSize, fleetCounts: _fleetCounts);
      },
      onLeave: () => widget.game.overlays.remove('GameOptionsScreen'),
    );
  }

  Widget _buildContent({
    required bool amIHost,
    required String p1Name,
    String? p2Name,
    VoidCallback? onStart,
    required VoidCallback onLeave,
  }) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text('GAME OPTIONS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white54, indent: 50, endIndent: 50),

        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _playerInfo(p1Name, true),
                      const SizedBox(height: 10),
                      const Text('VS', style: TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _playerInfo(p2Name ?? 'Waiting...', p2Name != null),
                    ],
                  ),
                ),
                const SizedBox(height: 20, child: VerticalDivider(color: Colors.white24, width: 1)),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Grid Size: $_gridSize x $_gridSize", style: const TextStyle(color: Colors.white, fontSize: 18)),
                            if (_isUpdating)
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                              )
                          ],
                        ),
                        Slider(
                          value: _gridSize.toDouble(),
                          min: 5,
                          max: 15,
                          divisions: 10,
                          activeColor: _isUpdating ? Colors.grey : Colors.green,
                          inactiveColor: Colors.white24,
                          onChanged: (amIHost && !_isUpdating) ? _onGridSizeChanged : null,
                          onChangeEnd: (amIHost && !_isUpdating) ? (val) => _updateSettings() : null,
                        ),
                        const SizedBox(height: 20),
                        const Text("Fleet Composition:", style: TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 10),
                        _counterRow("Quad (4)", "4", _fleetCounts["4"]!, amIHost, (delta) => _modifyShipCount("4", delta)),
                        _counterRow("Triple (3)", "3", _fleetCounts["3"]!, amIHost, (delta) => _modifyShipCount("3", delta)),
                        _counterRow("Double (2)", "2", _fleetCounts["2"]!, amIHost, (delta) => _modifyShipCount("2", delta)),
                        _counterRow("Single (1)", "1", _fleetCounts["1"]!, amIHost, (delta) => _modifyShipCount("1", delta)),
                        if (widget.isMultiplayer) ...[
                          const Divider(color: Colors.white24),
                          const Text("Power-Ups:", style: TextStyle(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 5),
                          _counterRow("Octopus", "octopus", _powerUpCounts["octopus"]!, amIHost, (delta) => _modifyPowerUpCount("octopus", delta)),
                          _counterRow("Triple Shot", "triple", _powerUpCounts["triple"]!, amIHost, (delta) => _modifyPowerUpCount("triple", delta)),
                          _counterRow("Shark", "shark", _powerUpCounts["shark"]!, amIHost, (delta) => _modifyPowerUpCount("shark", delta)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onLeave,
                child: const Text('LEAVE', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              ),
              const SizedBox(width: 30),
              if (onStart != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (p2Name != null) ? Colors.green : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: (p2Name != null && !_isUpdating) ? onStart : null,
                  child: const Text('START GAME', style: TextStyle(fontSize: 20, color: Colors.white)),
                )
              else
                const Text("Waiting for host...", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _counterRow(String label, String key, int count, bool enabled, Function(int) onModify) {
    bool isEnabled = enabled && !_isUpdating;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
                onPressed: isEnabled ? () => onModify(-1) : null,
              ),
              SizedBox(
                width: 30,
                child: Text('$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 20),
                onPressed: isEnabled ? () => onModify(1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerInfo(String name, bool isActive) {
    return Column(
      children: [
        Icon(Icons.person, size: 40, color: isActive ? Colors.lightBlueAccent : Colors.grey),
        const SizedBox(height: 5),
        Text(name, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
      ],
    );
  }
}