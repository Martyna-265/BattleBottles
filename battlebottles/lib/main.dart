import 'package:battlebottles/BattleShipsGame.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

void main() {
  final game = BattleShipsGame();
  runApp(GameWidget(game: game));
}