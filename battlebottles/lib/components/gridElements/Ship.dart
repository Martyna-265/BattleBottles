import 'dart:math';
import 'package:flutter/material.dart';

import '../bottleElements/ShipType.dart';

class Ship {
  ShipType type;
  int x;
  int y;
  List<Point<int>>? _syncedRelativePositions;

  Ship({
    required this.type,
    required this.x,
    required this.y,
    List<Point<int>>? syncedPoints,
  }) : _syncedRelativePositions = syncedPoints;

  List<Point<int>> getOccupiedPoints() {
    if (_syncedRelativePositions != null &&
        _syncedRelativePositions!.isNotEmpty) {
      return _syncedRelativePositions!
          .map((p) => Point(x + p.x, y + p.y))
          .toList();
    }
    return type.relativePositions.map((p) => Point(x + p.x, y + p.y)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'typeId': type.id,
      'x': x,
      'y': y,
      'relPoints':
          type.relativePositions.map((p) => {'x': p.x, 'y': p.y}).toList(),
    };
  }

  factory Ship.fromJson(Map<String, dynamic> json) {
    List<Point<int>>? loadedPoints;
    if (json['relPoints'] != null) {
      try {
        loadedPoints = (json['relPoints'] as List).map((p) {
          int px = (p['x'] as num).toInt();
          int py = (p['y'] as num).toInt();
          return Point<int>(px, py);
        }).toList();
      } catch (e) {
        debugPrint("Point loading error: $e");
      }
    }
    return Ship(
      type: ShipType.fromId((json['typeId'] as num).toInt()),
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      syncedPoints: loadedPoints,
    );
  }

  void typeChange() {
    _syncedRelativePositions = null;
  }
}
