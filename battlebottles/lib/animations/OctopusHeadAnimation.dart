import 'package:flame/components.dart';
import '../BattleShipsGame.dart';

class OctopusHeadAnimation extends SpriteAnimationComponent
    with HasGameReference<BattleShipsGame> {
  final Vector2 targetPosition;
  final double cellSize;

  OctopusHeadAnimation({required this.targetPosition, required this.cellSize})
      : super(priority: 200);

  @override
  Future<void> onLoad() async {
    final spriteSheet = await game.images.load('octopus_head_sheet.png');

    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 21,
        stepTime: 0.1,
        textureSize: Vector2(16, 16),
        loop: false,
      ),
    );

    removeOnFinish = true;

    size = Vector2(cellSize, cellSize);
    position = targetPosition;
  }
}
