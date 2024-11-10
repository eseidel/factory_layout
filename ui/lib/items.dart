import 'drawing.dart';
import 'geometry.dart';
import 'sprite.dart';

enum ItemType {
  heart,
}

class Item {
  final Position location;
  final ItemType type;

  const Item({required this.location, required this.type});

  void draw(Drawing drawing) {
    drawing.add(this, const SpriteDrawable(Sprites.heart), location);
  }
}
