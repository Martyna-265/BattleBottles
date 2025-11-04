import 'package:battlebottles/GlobalFunctions.dart';
import 'package:flame/components.dart';

class Condition {

  factory Condition.fromInt(int index) {
    assert(index >= 0 && index <= 3);
    return _singletons[index];
  }

  Condition._(this.value, this.label, double x, double y, double w, double h)
      : sprite = GlobalFunctions.Bottle1x1Sprite(x, y, w, h);

  final int value;
  final String label;
  final Sprite sprite;

  static final List<Condition> _singletons = [
    Condition._(0, 'unhurt', 256, 256, 512, 512),
    Condition._(1, 'hurt', 1280, 256, 512, 512),
    Condition._(2, 'down', 256, 1280, 512, 512),
  ];

}