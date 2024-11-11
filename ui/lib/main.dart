import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/src/game.dart';

void main() {
  runApp(
    const GameWidget<FactoryGame>.controlled(
      gameFactory: FactoryGame.new,
    ),
  );
}
