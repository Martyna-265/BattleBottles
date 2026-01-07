import 'package:battlebottles/BattleShipsGame.dart';
import 'package:battlebottles/screens/GameOptionsScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

class FakeBattleShipsGame extends BattleShipsGame {
  @override
  Future<void> onLoad() async {}

  @override
  void startGame({int? gridSize, Map<String, int>? fleetCounts}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupFirebaseCoreMocks();

  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('GameOptionsScreen Widget Tests', () {
    testWidgets(
      'Singleplayer screen renders correctly and updates ship count',
      (WidgetTester tester) async {
        final fakeGame = FakeBattleShipsGame();

        await tester.pumpWidget(
          MaterialApp(
            home: GameOptionsScreen(game: fakeGame, isMultiplayer: false),
          ),
        );

        await tester.pump();

        expect(find.text('GAME OPTIONS'), findsOneWidget);

        expect(find.text('4'), findsWidgets);

        final singleRowFinder = find
            .ancestor(of: find.text('Single (1)'), matching: find.byType(Row))
            .first;

        final plusButton = find.descendant(
          of: singleRowFinder,
          matching: find.byIcon(Icons.add_circle),
        );

        await tester.tap(plusButton);
        await tester.pump();

        expect(find.text('5'), findsOneWidget);
      },
    );
  });
}

void setupFirebaseAuthMocks() {
  const MethodChannel authChannel = MethodChannel(
    'plugins.flutter.io/firebase_auth',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(authChannel, (MethodCall methodCall) async {
    return null;
  });
}
