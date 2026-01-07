import 'package:flame/components.dart';
import '../BattleShipsGame.dart';

class SplashAnimation extends SpriteAnimationComponent
    with HasGameReference<BattleShipsGame> {
  final Vector2 targetPosition;
  final double cellSize;

  SplashAnimation({required this.targetPosition, required this.cellSize})
    : super(priority: 300);

  @override
  Future<void> onLoad() async {
    final spriteSheet = await game.images.load('water_splash.png');

    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 9,
        stepTime: 0.1,
        textureSize: Vector2(32, 32),
        loop: false,
      ),
    );

    removeOnFinish = true;
    size = Vector2(cellSize, cellSize);
    position = targetPosition;
    anchor = Anchor.topLeft;
  }
}
