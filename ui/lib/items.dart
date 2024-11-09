import 'drawing.dart';
import 'geometry.dart';
import 'model.dart';
import 'sprite.dart';

abstract class Mob {
  Position location;
  Direction facingDirection = Direction.up;

  Mob({required this.location});

  Drawable get drawable;

  void draw(Drawing drawing) {
    drawing.add(this, drawable, location);
  }
}

typedef ItemFactory = Item Function({required Position location});

abstract class Item extends Mob {
  Item({required super.location});

  void onPickup(GameState state);
}

class HealOne extends Item {
  HealOne({required super.location});

  @override
  void onPickup(GameState state) {
    state.player.applyHealthChange(state, 1);
  }

  @override
  Drawable get drawable => const SpriteDrawable(Sprites.heart);
}
