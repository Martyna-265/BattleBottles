import 'package:flame/components.dart';
import 'package:flame/flame.dart';

class GlobalFunctions {
  static Sprite Bottle1x1Sprite(double x, double y, double width, double height) {
    return Sprite(
      Flame.images.fromCache('Bottle1x1.png'),
      srcPosition: Vector2(x, y),
      srcSize: Vector2(width, height),
    );
  }
}