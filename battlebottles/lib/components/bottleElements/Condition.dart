import 'package:flame/components.dart';
import 'package:flame/flame.dart';

class Condition {
  factory Condition.fromInt(int index) {
    assert(index >= 0 && index <= 5);
    return _singletons[index];
  }

  Condition._(this.value, this.label, double x, double y, double w, double h)
      : sprite = GridElementSprite(x, y, w, h);

  final int value;
  final String label;
  final Sprite sprite;

  static final List<Condition> _singletons = [
    Condition._(0, 'unhurt', 0, 0, 256, 256),
    Condition._(1, 'hurt', 256, 0, 256, 256),
    Condition._(2, 'down', 0, 256, 256, 256),
    Condition._(3, 'water', 256, 256, 256, 256),
    Condition._(4, 'water_down', 0, 512, 256, 256),
    Condition._(5, 'clouds', 256, 256, 256, 256),
  ];

  static Sprite GridElementSprite(
    double x,
    double y,
    double width,
    double height,
  ) {
    return Sprite(
      Flame.images.fromCache('grid_element_sheet.png'),
      srcPosition: Vector2(x, y),
      srcSize: Vector2(width, height),
    );
  }
}
