import 'dart:math';
import 'package:battlebottles/components/GridElement.dart';
import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import '../screens/BattleShipsGame.dart';
import 'Bottle.dart';
import 'Water.dart';
import 'bottleElements/Condition.dart';

class BattleGrid extends PositionComponent with HasGameReference<BattleShipsGame> {

  BattleGrid(bool opponent, int bottleCount)
      : squaresInGrid = BattleShipsGame.squaresInGrid,
        opponent = opponent,
        bottleCount = bottleCount,
        super(size: Vector2(BattleShipsGame.battleGridWidth, BattleShipsGame.battleGridHeight));

  final int squaresInGrid;
  final bool opponent;
  late List<List<GridElement?>> grid;
  final int bottleCount;

  static final Paint blueBackgroundPaint = Paint()..color = const Color(0xff7aa3cc);
  static final Paint blackBorderPaint = Paint()
    ..color = const Color(0xff000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  @override
  Future<void> onLoad() async {
    regenerateGrid();
  }

  void regenerateGrid() {
    removeAll(children);

    grid = List.generate(
      squaresInGrid,
          (_) => List.filled(squaresInGrid, null, growable: false),
      growable: false,
    );

    final random = Random();
    final Set<Point<int>> bottlePositions = {};

    while (bottlePositions.length < bottleCount) {
      final x = random.nextInt(squaresInGrid);
      final y = random.nextInt(squaresInGrid);
      bottlePositions.add(Point(x, y));
    }

    for (int y = 0; y < squaresInGrid; y++) {
      for (int x = 0; x < squaresInGrid; x++) {
        final bool isBottle = bottlePositions.contains(Point(x, y));

        final GridElement square = isBottle
            ? Bottle(x, y, 0, opponent)
            : Water(x, y, opponent);

        square.position = Vector2(
          x * BattleShipsGame.squareLength,
          y * BattleShipsGame.squareLength,
        );

        grid[y][x] = square;
        add(square);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), blueBackgroundPaint);

    final double cellWidth = size.x / squaresInGrid;
    final double cellHeight = size.y / squaresInGrid;

    for (int i = 0; i <= squaresInGrid; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), blackBorderPaint);
    }
    for (int j = 0; j <= squaresInGrid; j++) {
      final y = j * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), blackBorderPaint);
    }
    canvas.drawRect(size.toRect(), blackBorderPaint);

    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    final textStyle = TextStyle(color: const Color(0xFF000000), fontSize: cellHeight * 0.4);

    for (int i = 0; i < squaresInGrid; i++) {
      final letter = String.fromCharCode(65 + i);
      textPainter.text = TextSpan(text: letter, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(i * cellWidth + cellWidth / 2 - textPainter.width / 2, -cellHeight * 0.8));
    }
    for (int j = 0; j < squaresInGrid; j++) {
      final number = '${j + 1}';
      textPainter.text = TextSpan(text: number, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(-cellWidth * 0.8, j * cellHeight + cellHeight / 2 - textPainter.height / 2));
    }
  }

  List<int> getShipPositions() {
    List<int> positions = [];
    for (int y = 0; y < squaresInGrid; y++) {
      for (int x = 0; x < squaresInGrid; x++) {
        final element = grid[y][x];
        if (element != null && element.condition.value == 0) {
          int index = y * squaresInGrid + x;
          positions.add(index);
        }
      }
    }
    return positions;
  }

  void setEnemyShips(List<dynamic> indices) {
    for (int y = 0; y < squaresInGrid; y++) {
      for (int x = 0; x < squaresInGrid; x++) {
        final element = grid[y][x];
        if (element != null && element.condition.value != 1 && element.condition.value != 2 && element.condition.value != 4) {
          element.condition = Condition.fromInt(3); // Water
          element.sprite = element.condition.sprite;
          element.bombable = true;
        }
      }
    }

    for (var index in indices) {
      if (index is int) {
        int y = index ~/ squaresInGrid;
        int x = index % squaresInGrid;

        if (y < squaresInGrid && x < squaresInGrid) {
          final element = grid[y][x];
          if (element != null) {
            element.condition = Condition.fromInt(0);

            element.sprite = opponent ? Condition.fromInt(3).sprite : element.condition.sprite;
            element.bombable = true;
          }
        }
      }
    }
  }

  void visualizeHit(int index) {
    int y = index ~/ squaresInGrid;
    int x = index % squaresInGrid;

    if (y < squaresInGrid && x < squaresInGrid) {
      final element = grid[y][x];
      if (element != null && element.bombable) {
        element.bomb();
      }
    }
  }
}