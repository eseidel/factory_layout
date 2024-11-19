import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:ui/src/world.dart';

import '../game.dart';

class ItemData {
  final String name;
  final String image;
  bool hasCollision;

  ItemData(
      {required this.name, required this.image, required this.hasCollision});
}

class ItemBlock extends SpriteComponent with HasGameReference<FactoryGame> {
  final ItemType type;
  final Vector2 gridPosition;

  ItemBlock({required this.type, required this.gridPosition})
      : super(
            size: Vector2.all(kGridSize.toDouble()), anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    final groundImage = game.images.fromCache('ground.png');
    sprite = Sprite(groundImage);
    position = Vector2(gridPosition.x * size.x, gridPosition.y * size.y);
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }
}
