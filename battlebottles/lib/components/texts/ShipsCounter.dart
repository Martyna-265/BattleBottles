import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import '../BattleGrid.dart';
import '../../BattleShipsGame.dart';

class ShipsCounter extends PositionComponent {
  final BattleGrid linkedGrid;

  ShipsCounter(this.linkedGrid);

  final Paint _shipPaint = Paint()..color = const Color(0xff003366);
  final Paint _borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  final TextPaint _countPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.1,
      color: Color(0xff003366),
      fontWeight: FontWeight.bold,
      fontFamily: 'Awesome Font',
    ),
  );

  final TextPaint _labelPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1.2,
      color: Color(0xff003366),
      fontFamily: 'Awesome Font',
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (linkedGrid.ships.isEmpty) return;

    _labelPaint.render(canvas, 'Ships left:', Vector2(0, 0));

    // Zliczanie statków
    int size4 = 0; int size3 = 0; int size2 = 0; int size1 = 0;
    for (var ship in linkedGrid.ships) {
      if (!linkedGrid.shipsDown.contains(ship)) {
        int s = ship.type.size;
        if (s == 4) {
          size4++;
        } else if (s == 3) {
          size3++;
        }
        else if (s == 2) {
          size2++;
        } else if (s == 1) {
          size1++;
        }
      }
    }

    double effectiveGridWidth = linkedGrid.size.x * linkedGrid.scale.x;

    int gridSize = linkedGrid.game.squaresInGrid;
    double startY = 1.5 + (10 - gridSize) * 0.15;
    startY = startY.clamp(1.5, 3.5);

    double baseIconSize = BattleShipsGame.squareLength / 2.2;
    double gapBetweenIconAndText = 0.3;
    double gapBetweenGroups = 1.2;

    double getGroupWidth(int shipSize) => (shipSize * baseIconSize) + gapBetweenIconAndText + 1.2;

    double totalContentWidth = getGroupWidth(4) + getGroupWidth(3) + getGroupWidth(2) + getGroupWidth(1) + (3 * gapBetweenGroups);

    double contentScale = 1.0;
    if (totalContentWidth > effectiveGridWidth) {
      contentScale = effectiveGridWidth / (totalContentWidth + 1.0);
    }

    canvas.save();
    canvas.scale(contentScale);

    double startX = (effectiveGridWidth / contentScale - totalContentWidth) / 2;

    if (startX < 0) startX = 0;

    double currentX = startX;

    void drawGroup(int shipSize, int count) {
      for (int i = 0; i < shipSize; i++) {
        Rect rect = Rect.fromLTWH(currentX + (i * baseIconSize), startY, baseIconSize, baseIconSize);
        canvas.drawRect(rect, _shipPaint);
        canvas.drawRect(rect, _borderPaint);
      }
      currentX += (shipSize * baseIconSize) + gapBetweenIconAndText;

      TextPaint paintToUse = count > 0
          ? _countPaint
          : TextPaint(style: _countPaint.style.copyWith(color: const Color(0x55003366)));

      paintToUse.render(canvas, "x$count", Vector2(currentX, startY));
      currentX += 1.4 + gapBetweenGroups;
    }

    drawGroup(4, size4);
    drawGroup(3, size3);
    drawGroup(2, size2);
    drawGroup(1, size1);

    canvas.restore();
  }
}