import 'dart:math';

enum Space {
  empty(' '),
  source('S'),
  sink('T'),
  path('X');

  const Space(this.char);

  final String char;

  static Space fromChar(String string) {
    for (final space in Space.values) {
      if (space.char == string) {
        return space;
      }
    }
    throw ArgumentError('Invalid character: $string');
  }
}

class Position {
  Position(this.x, this.y);

  final int x;
  final int y;
}

class Grid<T> {
  Grid(this.spaces);

  factory Grid.filled(int width, int height, T fill) {
    final spaces = <List<T>>[];
    for (var y = 0; y < height; y++) {
      final row = <T>[];
      for (var x = 0; x < width; x++) {
        row.add(fill);
      }
      spaces.add(row);
    }
    return Grid(spaces);
  }

  final List<List<T>> spaces;

  int get width => spaces[0].length;
  int get height => spaces.length;

  bool inBounds(Position position) {
    return position.x >= 0 &&
        position.x < width &&
        position.y >= 0 &&
        position.y < height;
  }

  Iterable<Position> neighbors(Position position) sync* {
    for (final neighbor in [
      Position(position.x - 1, position.y),
      Position(position.x + 1, position.y),
      Position(position.x, position.y - 1),
      Position(position.x, position.y + 1),
    ]) {
      if (inBounds(neighbor)) {
        yield neighbor;
      }
    }
  }

  T operator [](Position position) => spaces[position.y][position.x];
  void operator []=(Position position, T value) {
    spaces[position.y][position.x] = value;
  }

  Iterable<Position> positionsMatching(T space) sync* {
    for (var y = 0; y < spaces.length; y++) {
      for (var x = 0; x < spaces[y].length; x++) {
        if (spaces[y][x] == space) {
          yield Position(x, y);
        }
      }
    }
  }

  int countMatching(T space) {
    var count = 0;
    for (final row in spaces) {
      for (final value in row) {
        if (value == space) {
          count++;
        }
      }
    }
    return count;
  }
}

class SpaceGrid extends Grid<Space> {
  SpaceGrid(super.spaces);

  factory SpaceGrid.fromStrings(List<String> strings) {
    // Parse the strings into a grid of spaces.
    final spaces = <List<Space>>[];
    for (final string in strings) {
      final row = <Space>[];
      for (final char in string.split('')) {
        row.add(Space.fromChar(char));
      }
      spaces.add(row);
    }
    return SpaceGrid(spaces);
  }

  List<String> toStrings() {
    final strings = <String>[];
    for (final row in spaces) {
      final string = row.map((space) => space.char).join();
      strings.add(string);
    }
    return strings;
  }

  @override
  String toString() {
    return toStrings().join('\n');
  }

  Iterable<Position> get sources => positionsMatching(Space.source);
  Iterable<Position> get sinks => positionsMatching(Space.sink);

  SpaceGrid copy() {
    return SpaceGrid(List<List<Space>>.from(spaces.map(List<Space>.from)));
  }
}

// Need some way to score a grid.
// Does it connect the needed sources and sinks?
// How many segments does it use?

bool isConnected(SpaceGrid grid) {
  // Walk the sinks and see if they can reach the sources.
  final colors = Grid.filled(grid.width, grid.height, 0);
  var color = 1;
  for (final sink in grid.sinks) {
    final stack = [sink];
    while (stack.isNotEmpty) {
      final position = stack.removeLast();
      if (colors[position] != 0) {
        continue;
      }
      colors[position] = color;
      if (grid[position] == Space.source) {
        break;
      }

      for (final neighbor in grid.neighbors(position)) {
        if (grid[neighbor] == Space.path || grid[neighbor] == Space.source) {
          stack.add(neighbor);
        }
      }
    }
    color++;
  }
  return grid.sources.every((source) => colors[source] != 0);
}

class Planner {
  Planner(this.original, this.random);

  final SpaceGrid original;
  final Random random;

  void fillOne(SpaceGrid grid, Random random) {
    // If we don't have empty space left, throw.
    final emptySpaces = grid.positionsMatching(Space.empty);
    if (emptySpaces.isEmpty) {
      throw ArgumentError('No empty spaces left');
    }
    // Otherwise convert an empty space into a path.
    final position = emptySpaces.elementAt(random.nextInt(emptySpaces.length));
    grid[position] = Space.path;
  }

  SpaceGrid plan() {
    // Start with the original grid.
    final solution = original.copy();
    while (!isConnected(solution)) {
      fillOne(solution, random);
    }
    return solution;
  }
}

void main(List<String> args) {
  // Given a map of inputs and outputs, solve routing.

  // Start with just one source and sink and see if the algorithm can solve
  // for the path between them.

  // Do I care about segment direction?  I don't think so in the beginning.

  // The easiest case is just one source and one sink.
  // A better case might be one source, one sink, and one intermediate?
  // Including an intermediate which is far away?

  // Then maybe an intermediate with two inputs?

  // What if a node has multiple possible inputs, only one of which needs
  // to be satisfied?

  final grid = SpaceGrid.fromStrings([
    '  S  ',
    '     ',
    '  T  ',
  ]);

  final planner = Planner(grid, Random());
  final solution = planner.plan();

  print(solution);
  print(isConnected(solution));
}
