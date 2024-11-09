import 'dart:math';

import 'package:flutter/material.dart';

import 'drawing.dart';
import 'geometry.dart';
import 'grid.dart';
import 'items.dart';

const ISize kChunkSize = ISize(10, 10);

enum CellType {
  empty,
  wall,
  source,
  sink,
  up,
  down,
  left,
  right,
}

class Cell {
  final CellType type;
  final double value;

  const Cell(this.type, this.value);

  const Cell.empty()
      : type = CellType.empty,
        value = 0;
  const Cell.wall()
      : type = CellType.wall,
        value = 0;

  bool get isPassable => type == CellType.empty;
  bool get isWall => type == CellType.wall;

  Color get color {
    return {
      CellType.empty: Colors.brown.shade300,
      CellType.wall: Colors.brown.shade600,
      CellType.source: Colors.blue.shade300,
      CellType.sink: Colors.red.shade300,
      CellType.up: Colors.green.shade300,
      CellType.down: Colors.green.shade300,
      CellType.left: Colors.green.shade300,
      CellType.right: Colors.green.shade300,
    }[type]!;
  }

  String toCharRepresentation() {
    return {
      CellType.empty: '.',
      CellType.wall: '#',
      CellType.source: 'S',
      CellType.sink: 'X',
      CellType.up: '^',
      CellType.down: 'v',
      CellType.left: '<',
      CellType.right: '>',
    }[type]!;
  }
}

GridPosition _getRandomGridPositionWithCondition(
    ISize size, Random random, bool Function(GridPosition position) allowed) {
  // FIXME: Track seen positions and avoid repeats / terminate if tried all?
  while (true) {
    final position = _getRandomPosition(size, random);
    if (allowed(position)) {
      return position;
    }
  }
}

GridPosition _getRandomPosition(ISize size, Random random) {
  var area = size.width * size.height;
  var offset = random.nextInt(area);
  var width = (offset / size.width).truncate();
  var height = offset % size.height;
  return GridPosition(width, height);
}

class Chunk {
  final ChunkId chunkId;
  // This is essentially the "foreground" layer, of static items.
  final Grid<Cell> cells;

  final List<Item> items = [];
  final Grid<bool> mapped;
  final Grid<bool> lit;

  Chunk(this.cells, this.chunkId)
      : mapped = Grid<bool>.filled(cells.size, (_) => false),
        lit = Grid<bool>.filled(cells.size, (_) => false) {
    for (var position in allPositions) {
      cells.set(toLocal(position), const Cell.empty());
    }
  }

  void draw(Drawing drawing) {
    // allPositions does not guarantee order.
    for (var position in allPositions) {
      final cell = getCell(position);
      final color = cell.color;
      drawing.addBackground(SolidDrawable(color), position);
    }

    for (var item in items) {
      item.draw(drawing);
    }
  }

  void addWall(Random random) {
    final position = _getRandomGridPositionWithCondition(
        size, random, (position) => _getCellLocal(position).isPassable);
    cells.set(position, const Cell.wall());
  }

  void addManyWalls(int numberOfWalls, random) {
    for (int i = 0; i < numberOfWalls; ++i) {
      addWall(random);
    }
  }

  void spawnOneItem(ItemFactory item, Random random, {double chance = 1.0}) {
    if (random.nextDouble() < chance) {
      items.add(item(location: getItemSpawnLocation(random)));
    }
  }

  void spawnItems(Random random) {
    spawnOneItem(AreaReveal.new, random, chance: 0.50);
    spawnOneItem(HealOne.new, random, chance: 0.70);
    spawnOneItem(HealAll.new, random, chance: 0.20);
    spawnOneItem(Torch.new, random, chance: 0.05);
    spawnOneItem(MaxHealthUp.new, random, chance: 0.05);
  }

  ISize get size => cells.size;

  bool _isPassableLocal(GridPosition position) =>
      _getCellLocal(position).isPassable;
  bool isPassable(Position position) => _isPassableLocal(toLocal(position));

  GridPosition toLocal(Position position) {
    return GridPosition(position.x - chunkId.x * kChunkSize.width,
        position.y - chunkId.y * kChunkSize.height);
  }

  Position toGlobal(GridPosition position) {
    return Position(position.x + chunkId.x * kChunkSize.width,
        position.y + chunkId.y * kChunkSize.height);
  }

  Rect get bounds => toGlobal(GridPosition.zero).toOffset() & size.toSize();

  bool contains(Position position) => ChunkId.fromPosition(position) == chunkId;

  Cell _getCellLocal(GridPosition position) => cells.get(position)!;
  Cell getCell(Position position) => _getCellLocal(toLocal(position));

  void setCell(Position position, Cell cell) {
    cells.set(toLocal(position), cell);
  }

  Iterable<Position> get allPositions =>
      allGridPositions.map((position) => toGlobal(position));
  Iterable<GridPosition> get allGridPositions => cells.allPositions;

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var row in cells.cellsByRow) {
      for (var cell in row) {
        buffer.write(cell.toCharRepresentation());
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }

  bool isRevealed(Position position) => mapped.get(toLocal(position)) ?? false;
  bool isLit(Position position) => lit.get(toLocal(position)) ?? false;

  Item? itemAt(Position position) {
    for (var item in items) {
      if (item.location == position) {
        return item;
      }
    }
    return null;
  }

  Position getItemSpawnLocation(Random random) {
    return toGlobal(_getRandomGridPositionWithCondition(size, random,
        (GridPosition position) {
      if (!_isPassableLocal(position)) {
        return false;
      }
      return itemAt(toGlobal(position)) == null;
    }));
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
    final cells = Grid.filled(kChunkSize, (_) => const Cell.empty());
    return Chunk(cells, chunkId);
  }

  bool isPassable(Position position) => _chunkAt(position).isPassable(position);
  Cell getCell(Position position) => _chunkAt(position).getCell(position);
  void setCell(Position position, Cell cell) =>
      _chunkAt(position).setCell(position, cell);
}
