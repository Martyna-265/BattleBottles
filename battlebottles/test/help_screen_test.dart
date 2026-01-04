import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:battlebottles/screens/HelpScreen.dart';
import 'package:battlebottles/BattleShipsGame.dart';

class FakeBattleShipsGame extends BattleShipsGame {
  @override
  Future<void> onLoad() async {
  }
}

void main() {
  testWidgets('HelpScreen displays all main headers correctly', (WidgetTester tester) async {
    final fakeGame = FakeBattleShipsGame();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HelpScreen(game: fakeGame),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('HELP & RULES'), findsOneWidget);

    expect(find.text('Battle Bottles'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Power-ups'), findsOneWidget);
    expect(find.text('Multiplayer'), findsOneWidget);

    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}