import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'actors/player.dart';
import 'objects/platform_block.dart';

const int kGridSize = 64;

class FactoryGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents, TapDetector {
  FactoryGame();

  late Player _player;
  late double lastBlockXPosition = 0.0;
  late UniqueKey lastBlockKey;

  double objectSpeed = 0.0;

  @override
  Future<void> onLoad() async {
    //debugMode = true; // Uncomment to see the bounding boxes
    await images.loadAll([
      'block.png',
      'ember.png',
      'ground.png',
    ]);
    camera.viewfinder.anchor = Anchor.topLeft;

    initializeGame(loadHud: true);
  }

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 173, 223, 247);
  }

  @override
  void onTapDown(TapDownInfo info) {
    print(
        "Tapped at ${info.eventPosition.widget.x}, ${info.eventPosition.widget.y}");
    // Figure out which grid position the tap was in
    final gridPosition = Vector2(
      (info.eventPosition.widget.x / kGridSize).floorToDouble(),
      (info.eventPosition.widget.y / kGridSize).floorToDouble(),
    );
    // Add a platform block at that grid position
    final platformBlock = PlatformBlock(
      gridPosition: gridPosition,
      xOffset: 0,
    );
    world.add(platformBlock);
  }

  // Block size is 64x64
  // This code does not try to handle resizing at all (yet).

  void initializeGame({required bool loadHud}) {
    _player = Player(
      position: Vector2(128, canvasSize.y - 128),
    );
    world.add(_player);
  }

  void reset() {
    initializeGame(loadHud: false);
  }
}
