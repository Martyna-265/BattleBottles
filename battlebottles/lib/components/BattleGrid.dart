import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import '../BattleShipsGame.dart';
import 'bottleElements/Condition.dart';
import 'bottleElements/ShipType.dart';
import 'gridElements/Bottle.dart';
import 'gridElements/GridElement.dart';
import 'gridElements/Ship.dart';
import 'gridElements/Water.dart';

class BattleGrid extends PositionComponent
    with HasGameReference<BattleShipsGame> {
  BattleGrid(this.opponent, this.fleetConfig) : super(size: Vector2.zero());

  final Map<String, int> fleetConfig;
  final bool opponent;
  late List<List<GridElement?>> grid;

  List<Ship> ships = [];
  List<Ship> shipsHurt = [];
  List<Ship> shipsDown = [];

  static final Paint blueBackgroundPaint = Paint()
    ..color = const Color(0x00000000);
  static final Paint blackBorderPaint = Paint()
    ..color = const Color(0xee000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    regenerateGrid();
  }

  void regenerateGrid() {
    removeAll(children);
    ships.clear();
    shipsHurt.clear();
    shipsDown.clear();

    int currentGridSize = game.squaresInGrid;

    grid = List.generate(
      currentGridSize,
      (_) => List.filled(currentGridSize, null, growable: false),
      growable: false,
    );

    List<ShipType> fleetToPlace = [];

    fleetConfig.forEach((sizeKey, count) {
      int size = int.parse(sizeKey);
      List<ShipType> availableTypes =
          ShipType.all.where((t) => t.size == size).toList();

      if (availableTypes.isNotEmpty) {
        Random r = Random();
        for (int i = 0; i < count; i++) {
          fleetToPlace.add(availableTypes[r.nextInt(availableTypes.length)]);
        }
      }
    });

    fleetToPlace.sort((a, b) => b.size.compareTo(a.size));

    final random = Random();

    for (var type in fleetToPlace) {
      bool placed = false;
      int attempts = 0;

      ShipType typeToPlace = type;

      while (!placed && attempts < 200) {
        int startX = random.nextInt(game.squaresInGrid);
        int startY = random.nextInt(game.squaresInGrid);

        Ship candidate = Ship(type: typeToPlace, x: startX, y: startY);
        List<Point<int>> points = candidate.getOccupiedPoints();

        bool fits = true;
        for (var p in points) {
          if (p.x < 0 ||
              p.x >= game.squaresInGrid ||
              p.y < 0 ||
              p.y >= game.squaresInGrid) {
            fits = false;
            break;
          }
          if (grid[p.y][p.x] != null) {
            fits = false;
            break;
          }
          List<Point<int>> neighbors = [
            Point(p.x, p.y - 1),
            Point(p.x, p.y + 1),
            Point(p.x - 1, p.y),
            Point(p.x + 1, p.y),
          ];
          for (var n in neighbors) {
            if (n.x >= 0 &&
                n.x < game.squaresInGrid &&
                n.y >= 0 &&
                n.y < game.squaresInGrid) {
              if (grid[n.y][n.x] is Bottle) {
                fits = false;
                break;
              }
            }
          }
          if (!fits) break;
        }

        if (fits) {
          ships.add(candidate);
          for (var p in points) {
            final bottle = Bottle(p.x, p.y, 0, opponent, candidate);
            bottle.position = Vector2(
              p.x * BattleShipsGame.squareLength,
              p.y * BattleShipsGame.squareLength,
            );
            grid[p.y][p.x] = bottle;
            add(bottle);
          }
          placed = true;
        }
        attempts++;
      }
    }
    _fillEmptyWithWater();
  }

  void _fillEmptyWithWater() {
    for (int y = 0; y < game.squaresInGrid; y++) {
      for (int x = 0; x < game.squaresInGrid; x++) {
        if (grid[y][x] == null) {
          final water = Water(x, y, opponent);
          water.position = Vector2(
            x * BattleShipsGame.squareLength,
            y * BattleShipsGame.squareLength,
          );
          grid[y][x] = water;
          add(water);
        }
      }
    }
  }

  void setEnemyShips(List<dynamic> shipsData) {
    removeAll(children);
    ships.clear();
    shipsHurt.clear();
    shipsDown.clear();

    grid = List.generate(
      game.squaresInGrid,
      (_) => List.filled(game.squaresInGrid, null, growable: false),
      growable: false,
    );

    for (var shipJson in shipsData) {
      if (shipJson is Map) {
        final safeMap = Map<String, dynamic>.from(shipJson);
        try {
          Ship enemyShip = Ship.fromJson(safeMap);
          ships.add(enemyShip);

          List<Point<int>> points = enemyShip.getOccupiedPoints();

          for (var p in points) {
            if (p.x >= 0 &&
                p.x < game.squaresInGrid &&
                p.y >= 0 &&
                p.y < game.squaresInGrid) {
              final bottle = Bottle(p.x, p.y, 0, opponent, enemyShip);
              bottle.condition = Condition.fromInt(0);
              bottle.sprite = Condition.fromInt(3).sprite;
              bottle.bombable = true;
              bottle.position = Vector2(
                p.x * BattleShipsGame.squareLength,
                p.y * BattleShipsGame.squareLength,
              );
              grid[p.y][p.x] = bottle;
              add(bottle);
            }
          }
        } catch (e) {
          debugPrint("Error parsing ship: $e");
        }
      }
    }
    _fillEmptyWithWater();
  }

  void rotateShip(Ship ship) {
    ShipType nextType = ship.type.nextRotation;
    for (int radius = 0; radius <= game.squaresInGrid; radius++) {
      for (int dx = -radius; dx <= radius; dx++) {
        for (int dy = -radius; dy <= radius; dy++) {
          if (max(dx.abs(), dy.abs()) != radius) continue;
          int testX = ship.x + dx;
          int testY = ship.y + dy;
          if (_tryPlaceRotatedShip(ship, nextType, testX, testY)) return;
        }
      }
    }
    for (int y = 0; y < game.squaresInGrid; y++) {
      for (int x = 0; x < game.squaresInGrid; x++) {
        if (_tryPlaceRotatedShip(ship, nextType, x, y)) return;
      }
    }
  }

  bool _tryPlaceRotatedShip(
    Ship ship,
    ShipType newType,
    int newHeadX,
    int newHeadY,
  ) {
    List<Point<int>> newPoints = newType.relativePositions
        .map((p) => Point(newHeadX + p.x, newHeadY + p.y))
        .toList();
    for (var p in newPoints) {
      if (p.x < 0 ||
          p.x >= game.squaresInGrid ||
          p.y < 0 ||
          p.y >= game.squaresInGrid) return false;
      if (!_isValidCell(p.x, p.y, ship)) return false;
      List<Point<int>> neighbors = [
        Point(p.x, p.y - 1),
        Point(p.x, p.y + 1),
        Point(p.x - 1, p.y),
        Point(p.x + 1, p.y),
      ];
      for (var n in neighbors) {
        if (n.x >= 0 &&
            n.x < game.squaresInGrid &&
            n.y >= 0 &&
            n.y < game.squaresInGrid) {
          if (!_isValidCell(n.x, n.y, ship)) return false;
        }
      }
    }
    List<Point<int>> oldPoints = ship.getOccupiedPoints();
    for (var p in oldPoints) {
      var element = grid[p.y][p.x];
      if (element is Bottle && element.parentShip == ship) {
        remove(element);
        Water water = Water(p.x, p.y, opponent)..position = element.position;
        add(water);
        grid[p.y][p.x] = water;
      }
    }

    ship.typeChange();
    ship.type = newType;
    ship.x = newHeadX;
    ship.y = newHeadY;

    for (var p in newPoints) {
      var target = grid[p.y][p.x];
      if (target != null) remove(target);
      final bottle = Bottle(p.x, p.y, 0, opponent, ship);
      bottle.position = Vector2(
        p.x * BattleShipsGame.squareLength,
        p.y * BattleShipsGame.squareLength,
      );
      grid[p.y][p.x] = bottle;
      add(bottle);
    }
    return true;
  }

  bool _isValidCell(int x, int y, Ship shipToIgnore) {
    var element = grid[y][x];
    if (element == null) return true;
    if (element is Water) return true;
    if (element is Bottle) {
      if (element.parentShip == shipToIgnore) return true;
      return false;
    }
    return true;
  }

  List<Map<String, dynamic>> getShipsData() {
    return ships.map((s) => s.toJson()).toList();
  }

  void visualizeHit(int index) {
    int y = index ~/ game.squaresInGrid;
    int x = index % game.squaresInGrid;
    if (y < game.squaresInGrid && x < game.squaresInGrid) {
      final element = grid[y][x];
      if (element != null && element.bombable) element.bomb();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), blueBackgroundPaint);
    final double cellWidth = size.x / game.squaresInGrid;
    final double cellHeight = size.y / game.squaresInGrid;
    for (int i = 0; i <= game.squaresInGrid; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), blackBorderPaint);
    }
    for (int j = 0; j <= game.squaresInGrid; j++) {
      final y = j * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), blackBorderPaint);
    }
    canvas.drawRect(size.toRect(), blackBorderPaint);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final textStyle = TextStyle(
      color: const Color(0xFFFFFFFF),
      fontSize: cellHeight * 0.4,
      fontWeight: FontWeight.w900,
    );

    for (int i = 0; i < game.squaresInGrid; i++) {
      final letter = String.fromCharCode(65 + i);
      textPainter.text = TextSpan(text: letter, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          i * cellWidth + cellWidth / 2 - textPainter.width / 2,
          -cellHeight * 0.6,
        ),
      );
    }

    for (int j = 0; j < game.squaresInGrid; j++) {
      final number = '${j + 1}';
      textPainter.text = TextSpan(text: number, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          -cellWidth * 0.6,
          j * cellHeight + cellHeight / 2 - textPainter.height / 2,
        ),
      );
    }
  }
}
