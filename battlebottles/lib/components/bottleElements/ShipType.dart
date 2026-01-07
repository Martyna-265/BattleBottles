import 'dart:math';

class ShipType {
  final int id;
  final String name;
  final List<Point<int>> relativePositions; // Point relative to (0,0)

  const ShipType._(this.id, this.name, this.relativePositions);

  int get size => relativePositions.length;

  ShipType get nextRotation {
    List<ShipType> sameSizeTypes = all.where((t) => t.size == size).toList();

    int currentIndex = sameSizeTypes.indexOf(this);

    return sameSizeTypes[(currentIndex + 1) % sameSizeTypes.length];
  }

  // SINGLE (1 squre)
  static const ShipType single = ShipType._(0, 'Single', [Point(0, 0)]);

  // DOUBLE (2 squares)
  static const ShipType doubleH = ShipType._(1, 'Double H', [
    Point(0, 0),
    Point(1, 0),
  ]);

  static const ShipType doubleV = ShipType._(2, 'Double V', [
    Point(0, 0),
    Point(0, 1),
  ]);

  // TRIPLE (3 squares)
  static const ShipType tripleLineH = ShipType._(3, 'Triple Line H', [
    Point(0, 0),
    Point(1, 0),
    Point(2, 0),
  ]);

  static const ShipType tripleLineV = ShipType._(4, 'Triple Line V', [
    Point(0, 0),
    Point(0, 1),
    Point(0, 2),
  ]);

  // [X]
  // [X][X]
  static const ShipType tripleCorner = ShipType._(5, 'Triple Corner', [
    Point(0, 0),
    Point(0, 1),
    Point(1, 1),
  ]);

  // [X][X]
  // [X]
  static const ShipType tripleCornerRev = ShipType._(6, 'Triple Corner Rev', [
    Point(0, 0),
    Point(1, 0),
    Point(0, 1),
  ]);

  //    [X]
  // [X][X]
  static const ShipType tripleCornerLeft = ShipType._(7, 'Triple Corner Left', [
    Point(1, 0),
    Point(0, 1),
    Point(1, 1),
  ]);

  // [X][X]
  //    [X]
  static const ShipType tripleCornerRevLeft = ShipType._(
    8,
    'Triple Corner Rev Left',
    [Point(0, 0), Point(1, 0), Point(1, 1)],
  );

  // QUADS (4 squares)
  // Lines and square
  static const ShipType quadLineH = ShipType._(9, 'Quad Line H', [
    Point(0, 0),
    Point(1, 0),
    Point(2, 0),
    Point(3, 0),
  ]);

  static const ShipType quadLineV = ShipType._(10, 'Quad Line V', [
    Point(0, 0),
    Point(0, 1),
    Point(0, 2),
    Point(0, 3),
  ]);

  static const ShipType quadSquare = ShipType._(11, 'Quad Square', [
    Point(0, 0),
    Point(1, 0),
    Point(0, 1),
    Point(1, 1),
  ]);

  // Letter T

  // [X][X][X]
  //    [X]
  static const ShipType quadT_Down = ShipType._(12, 'Quad T Down', [
    Point(0, 0),
    Point(1, 0),
    Point(2, 0),
    Point(1, 1),
  ]);

  //    [X]
  // [X][X][X]
  static const ShipType quadT_Up = ShipType._(13, 'Quad T Up', [
    Point(1, 0),
    Point(0, 1),
    Point(1, 1),
    Point(2, 1),
  ]);

  // [X]
  // [X][X]
  // [X]
  static const ShipType quadT_Right = ShipType._(14, 'Quad T Right', [
    Point(0, 0),
    Point(0, 1),
    Point(1, 1),
    Point(0, 2),
  ]);

  //    [X]
  // [X][X]
  //    [X]
  static const ShipType quadT_Left = ShipType._(15, 'Quad T Left', [
    Point(1, 0),
    Point(0, 1),
    Point(1, 1),
    Point(1, 2),
  ]);

  // Letter L

  // [X]
  // [X]
  // [X][X]
  static const ShipType quadL_Normal = ShipType._(16, 'Quad L Normal', [
    Point(0, 0),
    Point(0, 1),
    Point(0, 2),
    Point(1, 2),
  ]);

  //       [X]
  // [X][X][X]
  static const ShipType quadL_Right = ShipType._(17, 'Quad L Right', [
    Point(2, 0),
    Point(0, 1),
    Point(1, 1),
    Point(2, 1),
  ]);

  // [X][X]
  //    [X]
  //    [X]
  static const ShipType quadL_Inverted = ShipType._(18, 'Quad L Inverted', [
    Point(0, 0),
    Point(1, 0),
    Point(1, 1),
    Point(1, 2),
  ]);

  // [X][X][X]
  // [X]
  static const ShipType quadL_Left = ShipType._(19, 'Quad L Left', [
    Point(0, 0),
    Point(1, 0),
    Point(2, 0),
    Point(0, 1),
  ]);

  // Letter J

  //    [X]
  //    [X]
  // [X][X]
  static const ShipType quadJ_Normal = ShipType._(20, 'Quad J Normal', [
    Point(1, 0),
    Point(1, 1),
    Point(0, 2),
    Point(1, 2),
  ]);

  // [X]
  // [X][X][X]
  static const ShipType quadJ_Right = ShipType._(21, 'Quad J Right', [
    Point(0, 0),
    Point(0, 1),
    Point(1, 1),
    Point(2, 1),
  ]);

  // [X][X]
  // [X]
  // [X]
  static const ShipType quadJ_Inverted = ShipType._(22, 'Quad J Inverted', [
    Point(0, 0),
    Point(1, 0),
    Point(0, 1),
    Point(0, 2),
  ]);

  // [X][X][X]
  //       [X]
  static const ShipType quadJ_Left = ShipType._(23, 'Quad J Left', [
    Point(0, 0),
    Point(1, 0),
    Point(2, 0),
    Point(2, 1),
  ]);

  // Letters S and Z

  // [X][X]
  //    [X][X]
  static const ShipType quadZ_Hor = ShipType._(24, 'Quad Z Horizontal', [
    Point(0, 0),
    Point(1, 0),
    Point(1, 1),
    Point(2, 1),
  ]);

  //    [X]
  // [X][X]
  // [X]
  static const ShipType quadZ_Ver = ShipType._(25, 'Quad Z Vertical', [
    Point(1, 0),
    Point(0, 1),
    Point(1, 1),
    Point(0, 2),
  ]);

  //    [X][X]
  // [X][X]
  static const ShipType quadS_Hor = ShipType._(26, 'Quad S Horizontal', [
    Point(1, 0),
    Point(2, 0),
    Point(0, 1),
    Point(1, 1),
  ]);

  // [X]
  // [X][X]
  //    [X]
  static const ShipType quadS_Ver = ShipType._(27, 'Quad S Vertical', [
    Point(0, 0),
    Point(0, 1),
    Point(1, 1),
    Point(1, 2),
  ]);

  // List of all types
  static const List<ShipType> all = [
    single,
    doubleH,
    doubleV,

    tripleLineH,
    tripleLineV,
    tripleCorner,
    tripleCornerRev,
    tripleCornerLeft,
    tripleCornerRevLeft,

    quadLineH,
    quadLineV,
    quadSquare,

    quadT_Down,
    quadT_Up,
    quadT_Right,
    quadT_Left,

    quadL_Normal,
    quadL_Right,
    quadL_Inverted,
    quadL_Left,
    quadJ_Normal,
    quadJ_Right,
    quadJ_Inverted,
    quadJ_Left,

    quadZ_Hor,
    quadZ_Ver,
    quadS_Hor,
    quadS_Ver,
  ];

  static ShipType fromId(int id) {
    return all.firstWhere((element) => element.id == id, orElse: () => single);
  }
}
