import 'package:battlebottles/screens/AccountDropdown.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatsDialog displays correct data and labels', (
    WidgetTester tester,
  ) async {
    final mockStats = {
      'wins': 5,
      'losses': 2,
      'sinked_enemy_ships': 20,
      'sinked_ships': 10,
      'games_single': 4,
      'games_multi': 3,
      'pu_total': 3,
      'pu_octopus': 1,
      'pu_triple': 1,
      'pu_shark': 1,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StatsDialog(stats: mockStats)),
      ),
    );

    expect(find.text("Captain's Log"), findsOneWidget);

    expect(find.text("Victories"), findsOneWidget);
    expect(find.text("5"), findsWidgets);

    expect(find.text("Defeats"), findsOneWidget);
    expect(find.text("2"), findsWidgets);

    expect(find.text("Sunk Enemies"), findsOneWidget);
    expect(find.text("Lost Ships"), findsOneWidget);

    expect(find.textContaining("71.4%"), findsOneWidget);

    expect(find.text("Octopus"), findsOneWidget);
    expect(find.text("Triple Shot"), findsOneWidget);
    expect(find.text("Shark"), findsOneWidget);

    expect(find.text("CLOSE"), findsOneWidget);
  });
}
