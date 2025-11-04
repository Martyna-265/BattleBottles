import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import '../BattleShipsGame.dart';

class BattleGrid extends PositionComponent {

  BattleGrid()
        : squaresInGrid = BattleShipsGame.squaresInGrid,
        super(size: Vector2(BattleShipsGame.battleGridWidth, BattleShipsGame.battleGridHeight));

  final int squaresInGrid;

  @override
  bool get debugMode => false;

  static final Paint blueBackgroundPaint = Paint()
    ..color = const Color(0xff7aa3cc);
  static final Paint blackBorderPaint = Paint()
    ..color = const Color(0xff000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.08;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // tło
    canvas.drawRect(size.toRect(), blueBackgroundPaint);

    final double cellWidth = size.x / squaresInGrid;
    final double cellHeight = size.y / squaresInGrid;

    // linie pionowe
    for (int i = 0; i <= squaresInGrid; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), blackBorderPaint);
    }

    // linie poziome
    for (int j = 0; j <= squaresInGrid; j++) {
      final y = j * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), blackBorderPaint);
    }

    // opcjonalnie: czarna ramka wokół całego grida
    canvas.drawRect(size.toRect(), blackBorderPaint);

    // --- numeracja ---
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final textStyle = TextStyle(
      color: const Color(0xFF000000),
      fontSize: cellHeight * 0.4,
    );

    // litery u góry (A, B, C, ...)
    for (int i = 0; i < squaresInGrid; i++) {
      final letter = String.fromCharCode(65 + i); // 65 = 'A'
      textPainter.text = TextSpan(text: letter, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(i * cellWidth + cellWidth / 2 - textPainter.width / 2, -cellHeight * 0.8),
      );
    }

    // liczby po lewej (1, 2, 3, ...)
    for (int j = 0; j < squaresInGrid; j++) {
      final number = '${j + 1}';
      textPainter.text = TextSpan(text: number, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-cellWidth * 0.8, j * cellHeight + cellHeight / 2 - textPainter.height / 2),
      );
    }
  }


}