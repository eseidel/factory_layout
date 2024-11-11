import 'geometry.dart';
import 'model.dart';

abstract class Mob {
  Position location;
  Direction facingDirection = Direction.up;

  Mob({required this.location});
}

abstract class Character extends Mob {
  Character({
    required super.location,
  });
}

class Player extends Character {
  Player.spawn(Position location) : super(location: location);
}

abstract class GameAction {
  final Character character;

  const GameAction({required this.character});

  void execute(GameState state);
}

class MoveAction extends GameAction {
  final Direction direction;
  final Position destination;

  const MoveAction({
    required this.destination,
    required this.direction,
    required super.character,
  });

  @override
  void execute(GameState state) {
    character.facingDirection = direction;
    if (state.world.isPassable(destination)) {
      character.location = destination;
    }
  }
}
