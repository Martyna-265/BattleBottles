import 'package:flame/components.dart';
import '../BattleShipsGame.dart';

class SharkAnimation extends SpriteComponent with HasGameReference<BattleShipsGame> {
  final double targetY;
  final double worldWidth;
  final double cellSize;

  SharkAnimation({
    required this.targetY,
    required this.worldWidth,
    required this.cellSize,
  }) : super(priority: 200);

  @override
  Future<void> onLoad() async {
    size = Vector2(cellSize, cellSize);

    double centeredY = targetY + (cellSize / 2) - (size.y / 2);
    position = Vector2(-size.x, centeredY);

    sprite = await game.loadSprite('shark_single.png');
  }

  @override
  void update(double dt) {
    super.update(dt);

    double speed = worldWidth / 2.5;

    x += speed * dt;

    if (x > worldWidth) {
      removeFromParent();
    }
  }
}