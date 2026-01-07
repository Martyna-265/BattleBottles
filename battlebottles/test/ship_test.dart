import 'dart:math';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:battlebottles/components/gridElements/Ship.dart';
import 'package:battlebottles/components/bottleElements/ShipType.dart';

void main() {
  group('Ship Logic Tests', () {
    test(
      'getOccupiedPoints() returns correct coordinates for Vertical Triple Ship',
      () {
        final ship = Ship(type: ShipType.tripleLineV, x: 5, y: 5);

        final points = ship.getOccupiedPoints();

        expect(points.length, 3);

        expect(points, contains(const Point(5, 5)));
        expect(points, contains(const Point(5, 6)));
        expect(points, contains(const Point(5, 7)));
      },
    );

    test('ShipType.single nextRotation is still ShipType.single', () {
      const type = ShipType.single;

      final nextType = type.nextRotation;

      expect(nextType, ShipType.single);
    });

    test('ShipType.doubleH rotates to ShipType.doubleV', () {
      const type = ShipType.doubleH;
      final nextType = type.nextRotation;

      expect(nextType, ShipType.doubleV);
    });

    test('Ship serialization (toJson -> fromJson) works correctly', () {
      final originalShip = Ship(type: ShipType.tripleCorner, x: 2, y: 3);

      final json = originalShip.toJson();

      final restoredShip = Ship.fromJson(json);

      expect(restoredShip.x, originalShip.x);
      expect(restoredShip.y, originalShip.y);
      expect(restoredShip.type.id, originalShip.type.id);
    });
  });
}
