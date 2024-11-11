import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'actors/player.dart';
import 'managers/segment_manager.dart';
import 'objects/ground_block.dart';
import 'objects/platform_block.dart';

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
    // Figure out which block is hit
    // Turn that block into a ground block.
  }

  void loadGameSegments(int segmentIndex, double xPositionOffset) {
    for (final block in segments[segmentIndex]) {
      final component = switch (block.blockType) {
        const (GroundBlock) => GroundBlock(
            gridPosition: block.gridPosition,
            xOffset: xPositionOffset,
          ),
        const (PlatformBlock) => PlatformBlock(
            gridPosition: block.gridPosition,
            xOffset: xPositionOffset,
          ),
        _ => throw UnimplementedError(),
      };
      world.add(component);
    }
  }

  // Block size is 64x64
  // This code does not try to handle resizing at all (yet).

  void initializeGame({required bool loadHud}) {
    // Assume that size.x < 3200
    final segmentsToLoad = (size.x / 640).ceil();
    segmentsToLoad.clamp(0, segments.length);

    for (var i = 0; i <= segmentsToLoad; i++) {
      loadGameSegments(i, (640 * i).toDouble());
    }

    _player = Player(
      position: Vector2(128, canvasSize.y - 128),
    );
    world.add(_player);
  }

  void reset() {
    initializeGame(loadHud: false);
  }
}
