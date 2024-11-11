import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game.dart';
import 'overlays/main_menu.dart';

void main() {
  runApp(
    GameWidget<FactoryGame>.controlled(
      gameFactory: FactoryGame.new,
      overlayBuilderMap: {
        'MainMenu': (_, game) => MainMenu(game: game),
      },
      initialActiveOverlays: const ['MainMenu'],
    ),
  );
}
