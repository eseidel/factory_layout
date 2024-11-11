import 'dart:math';

import 'characters.dart';
import 'geometry.dart';
import 'world.dart';

class LogicalEvent {
  Direction? direction;
  bool interact;

  LogicalEvent.move(this.direction) : interact = false;
  LogicalEvent.interact() : interact = true;
}

class GameState {
  late Player player;
  final World world;
  final Random random;

  GameState({
    int? seed,
  })  : world = World(seed: seed),
        random = Random(seed) {
    player = Player.spawn(Position.zero);
  }

  Chunk get focusedChunk => getChunk(player.location);

  Chunk getChunk(Position position) =>
      world.get(ChunkId.fromPosition(position));

  GameAction? actionFor(Player player, LogicalEvent logical) {
    var direction = logical.direction;
    if (direction == null) {
      return null;
    }
    return MoveAction(
      destination: player.location + direction.delta,
      direction: direction,
      character: player,
    );
  }
}
