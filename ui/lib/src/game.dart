import 'package:flame/components.dart';
import 'package:flame/game.dart';

class FactoryGame extends FlameGame {
  FactoryGame();

  @override
  Future<void> onLoad() async {
    // Load your game here
    await images.loadAll([
      'block.png',
      'ember.png',
      'ground.png',
      'heart_half.png',
      'heart.png',
      'star.png',
      'water_enemy.png',
    ]);

    // Everything in this tutorial assumes that the position
    // of the `CameraComponent`s viewfinder (where the camera is looking)
    // is in the top left corner, that's why we set the anchor here.
    camera.viewfinder.anchor = Anchor.topLeft;
  }
}
