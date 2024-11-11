import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'belt.dart';
import 'drawing.dart';
import 'geometry.dart';
import 'grid.dart';
import 'sprite.dart';

const ISize kChunkSize = ISize(10, 10);

enum ItemType {
  wall,
  source,
  sink,
  belt;

  Color get color {
    return {
      ItemType.wall: Colors.brown.shade600,
      ItemType.source: Colors.blue.shade300,
      ItemType.sink: Colors.red.shade300,
      ItemType.belt: Colors.green.shade300,
    }[this]!;
  }

  Drawable get drawable {
    return this == ItemType.belt
        ? const SpriteDrawable(Sprites.tube)
        : SolidDrawable(color);
  }
}

class PlacedItem {
  final Position location;
  final ItemType type;
  final Direction facingDirection;

  const PlacedItem({
    required this.location,
    required this.type,
    this.facingDirection = Direction.up,
  });

  bool get isPassable => type != ItemType.wall;
  bool get isWall => type == ItemType.wall;
  bool get isBelt => type == ItemType.belt;

  Drawable get drawable {
    return TransformDrawable.rst(
      rotation: facingDirection.rotation,
      drawable: type.drawable,
    );
  }

  void draw(Drawing drawing) {
    drawing.addForeground(drawable, location);
  }

  String toCharRepresentation() {
    return {
      ItemType.wall: '#',
      ItemType.source: 'S',
      ItemType.sink: 'X',
      ItemType.belt: {
        Direction.up: '^',
        Direction.down: 'v',
        Direction.left: '<',
        Direction.right: '>',
      }[facingDirection]!,
    }[type]!;
  }
}

class Chunk {
  final ChunkId chunkId;
  // This is essentially the "foreground" layer, of static items.
  final List<PlacedItem> items = [];

  final List<BeltSegment> beltSegments = [];

  Chunk(this.chunkId);

  ISize get size => kChunkSize;

  void draw(Drawing drawing) {
    for (var item in items) {
      item.draw(drawing);
    }
    for (var segment in beltSegments) {
      segment.draw(drawing);
    }
  }

  bool isPassable(Position position) {
    return getItem(position)?.isPassable ?? true;
  }

  GridPosition toLocal(Position position) {
    return GridPosition(position.x - chunkId.x * kChunkSize.width,
        position.y - chunkId.y * kChunkSize.height);
  }

  Position toGlobal(GridPosition position) {
    return Position(position.x + chunkId.x * kChunkSize.width,
        position.y + chunkId.y * kChunkSize.height);
  }

  Rect get bounds =>
      toGlobal(GridPosition.zero).toOffset() & kChunkSize.toSize();

  bool contains(Position position) => ChunkId.fromPosition(position) == chunkId;

  PlacedItem? getItem(Position position) {
    return items.firstWhereOrNull((item) => item.location == position);
  }

  void placeItem(Position position, PlacedItem item) {
    // Later we might throw an exception if the item is already placed.
    final existing = getItem(position);
    if (existing != null) {
      items.remove(existing);
    }
    items.add(item);
    onPlaceItem(item);
  }

  Iterable<PlacedItem> _inputBelts(Position position) {
    return Direction.values
        .map((direction) => getItem(position + direction.delta))
        .nonNulls
        .where((item) => item.isBelt)
        .where(
            (item) => item.location + item.facingDirection.delta == position);
  }

  BeltSegment? _segmentForBelt(PlacedItem belt) {
    return beltSegments
        .firstWhereOrNull((segment) => segment.belts.contains(belt));
  }

  void onPlaceItem(PlacedItem item) {
    // When placing an item that is a belt, we need to potentially add that
    // item to the belt system.
    // For now we handle the simple cases of just adding to an existing belt.
    // We look for a single belt flowing into this position and add it to that segment.

    if (item.isBelt) {
      // If there was already a belt there, we probably need to recompute
      // but don't currently.

      // Otherwise check for neighbors.
      final inputBelts = _inputBelts(item.location);
      final outputBelt = getItem(item.location + item.facingDirection.delta);
      if (inputBelts.isNotEmpty) {
        // If the belt is pointing towards this position, add us to the end
        // Should probably split the segment if there are multiple inputs.
        final inputBelt = inputBelts.first;
        final segment = _segmentForBelt(inputBelt)!;
        segment.addBeltToEnd(item);
      } else if (outputBelt != null) {
        // Look up the segment and add this belt to it.
        // If we're pointing at the belt add us to the start.
        final segment = _segmentForBelt(outputBelt)!;
        segment.addBeltToStart(item);
      } else {
        // Create a new segment with this belt.
        beltSegments.add(BeltSegment([item]));
      }
    }
  }

  Iterable<Position> get allPositions =>
      allGridPositions.map((position) => toGlobal(position));
  Iterable<GridPosition> get allGridPositions {
    final positions = <GridPosition>[];
    for (var x = 0; x < size.width; x++) {
      for (var y = 0; y < size.height; y++) {
        positions.add(GridPosition(x, y));
      }
    }
    return positions;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    int i = 0;
    for (final position in allPositions) {
      final cell = getItem(position);
      buffer.write(cell?.toCharRepresentation() ?? '.');
      if (++i % size.width == 0) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  PlacedItem? itemAt(Position position) {
    for (var item in items) {
      if (item.location == position) {
        return item;
      }
    }
    return null;
  }
}

class ChunkId {
  final int x;
  final int y;

  const ChunkId(this.x, this.y);
  const ChunkId.origin()
      : x = 0,
        y = 0;

  ChunkId.fromPosition(Position position)
      : x = (position.x / kChunkSize.width).floor(),
        y = (position.y / kChunkSize.height).floor();

  @override
  String toString() => '[$x,$y]';

  @override
  bool operator ==(other) {
    if (other is! ChunkId) {
      return false;
    }
    return x == other.x && y == other.y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

class World {
  final int seed;
  final Map<ChunkId, Chunk> _map = {};

  World({int? seed}) : seed = seed ?? 0;

  Chunk get(ChunkId id) => _map.putIfAbsent(id, () => _generateChunk(id));

  Chunk _chunkAt(Position position) => get(ChunkId.fromPosition(position));

  Chunk _generateChunk(ChunkId chunkId) {
    return Chunk(chunkId);
  }

  bool isPassable(Position position) => _chunkAt(position).isPassable(position);

  PlacedItem? getPlacedItem(Position position) =>
      _chunkAt(position).getItem(position);
  void placeItem(Position position, PlacedItem item) =>
      _chunkAt(position).placeItem(position, item);

  void update(double elapsed) {
    for (var chunk in _map.values) {
      for (var segment in chunk.beltSegments) {
        segment.update(elapsed);
        if (segment.hasSpaceAtStart) {
          segment.addItemToStart(ItemType.wall);
        }
      }
    }
  }
}
