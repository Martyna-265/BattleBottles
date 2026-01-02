import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import '../BattleGrid.dart';
import '../../screens/BattleShipsGame.dart';

class ShipsCounter extends PositionComponent {
  final BattleGrid linkedGrid;

  ShipsCounter(this.linkedGrid);

  final Paint _shipPaint = Paint()..color = const Color(0xff003366);

  final Paint _borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05;

  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1,
      color: Color(0xff003366),
      fontWeight: FontWeight.bold,
      fontFamily: 'Awesome Font',
    ),
  );

  final TextPaint _labelPaint = TextPaint(
    style: const TextStyle(
      fontSize: 1,
      color: Color(0xff003366),
      fontFamily: 'Awesome Font',
    ),
  );

  @override
  Future<void> onLoad() async {
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (linkedGrid.ships.isEmpty) return;

    _labelPaint.render(canvas, 'Ships left:', Vector2(0, 0));

    int size4 = 0;
    int size3 = 0;
    int size2 = 0;
    int size1 = 0;

    for (var ship in linkedGrid.ships) {
      if (!linkedGrid.shipsDown.contains(ship)) {
        int s = ship.type.size;
        if (s == 4) size4++;
        else if (s == 3) size3++;
        else if (s == 2) size2++;
        else if (s == 1) size1++;
      }
    }

    double iconSize = BattleShipsGame.squareLength / 2;
    double gap = 0.2;
    double groupGap = BattleShipsGame.squareLength / 2;

    double currentX = 0;

    double startY = 2;

    void drawGroup(int shipSize, int count) {
      // Mini statek
      for (int i = 0; i < shipSize; i++) {
        Rect rect = Rect.fromLTWH(currentX + (i * iconSize), startY, iconSize, iconSize);
        canvas.drawRect(rect, _shipPaint);
        canvas.drawRect(rect, _borderPaint);
      }

      currentX += (shipSize * iconSize) + gap;

      // Counter
      TextPaint paintToUse;

      if (count > 0) {
        paintToUse = TextPaint(
          style: _textPaint.style.copyWith(
            fontWeight: FontWeight.w900, // Gruby
            color: const Color(0xFF003366),
          ),
        );
      } else {
        paintToUse = TextPaint(
          style: _textPaint.style.copyWith(
            fontWeight: FontWeight.normal,
            color: const Color(0xEE003366),
          ),
        );
      }

      String label = " x$count";
      paintToUse.render(canvas, label, Vector2(currentX, startY));

      currentX += 1.5 + groupGap;
    }

    drawGroup(4, size4);
    drawGroup(3, size3);
    drawGroup(2, size2);
    drawGroup(1, size1);
  }
}