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

  Iterable<Chunk> get activeChunks sync* {
    final chunkId = ChunkId.fromPosition(player.location);
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        yield world.get(ChunkId(chunkId.x + dx, chunkId.y + dy));
      }
    }
  }

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

  Character? characterAt(Position position) {
    if (player.location == position) {
      return player;
    }
    return null;
  }
}
