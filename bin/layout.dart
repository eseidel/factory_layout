import 'dart:math';

import 'package:collection/collection.dart';

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

  Iterable<Position> get allPositions sync* {
    for (var y = 0; y < spaces.length; y++) {
      for (var x = 0; x < spaces[y].length; x++) {
        yield Position(x, y);
      }
    }
  }

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
  String toString() => toStrings().join('\n');

  Iterable<Position> get sources => positionsMatching(Space.source);
  Iterable<Position> get sinks => positionsMatching(Space.sink);

  SpaceGrid copy() {
    return SpaceGrid(List<List<Space>>.from(spaces.map(List<Space>.from)));
  }
}

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

extension<T> on List<T> {
  T pickOne(Random random) => this[random.nextInt(length)];
}

int score(SpaceGrid grid) => grid.countMatching(Space.path);

// This was derived from another project of mine and can be optimized.
class Optimizer {
  Optimizer(this.original, {Random? random, this.populationCount = 100})
      : random = random ?? Random();

  final Random random;
  final SpaceGrid original;

  final int populationCount;
  // Only this percent of the population will get to breed.
  final breedingRate = 0.1;

  // This percent of the breeding population will survive to the next round.
  // They will still be mutated.
  final survivalRate = 0.2;

  /// Chance that a given gene will mutate.
  final mutationRate = 0.005;

  int get breederCount => (populationCount * breedingRate).ceil();
  int get survivorCount => (breederCount * survivalRate).ceil();

  List<SpaceGrid> _seedPopulation(int count) {
    final population = <SpaceGrid>[];
    for (var i = 0; i < count; i++) {
      population.add(randomSolution(original, random));
    }
    return population;
  }

  List<SpaceGrid> _crossover(List<SpaceGrid> parents, int childCount) {
    final children = <SpaceGrid>[];
    for (var i = 0; i < childCount; i++) {
      // Should probably pick unique parents?
      final parent1 = parents.pickOne(random);
      final parent2 = parents.pickOne(random);

      final child = parent1.copy();
      for (final position in parent2.allPositions) {
        if (random.nextBool()) {
          child[position] = parent2[position];
        }
      }
      children.add(child);
    }
    return children;
  }

  SpaceGrid _mutate(SpaceGrid current, double mutationRate) {
    final child = current.copy();
    for (final position in child.allPositions) {
      if (random.nextDouble() < mutationRate) {
        if (child[position] == Space.path) {
          child[position] = Space.empty;
        } else if (child[position] == Space.empty) {
          child[position] = Space.path;
        }
      }
    }
    return child;
  }

  List<SpaceGrid> _removeInvalidAndRepopulate(List<SpaceGrid> population) {
    final valid = population.where(isConnected).toList();
    final missing = populationCount - valid.length;
    return [
      ...valid,
      ..._seedPopulation(missing),
    ];
  }

  List<SpaceGrid> run(int rounds) {
    var pop = <SpaceGrid>[];

    for (var i = 0; i < rounds; i++) {
      // Mutations can cause individuals to become invalid.
      // Also the initial population is empty.
      pop = _removeInvalidAndRepopulate(pop);
      final sorted = pop.toList()..sortBy<num>(score);
      final survivors = sorted.sublist(0, survivorCount);
      final breeders = sorted.sublist(0, breederCount);
      final children = _crossover(breeders, populationCount - survivorCount);
      // Make the next generation and apply mutations.
      pop = [...survivors, ...children]
          .map((c) => _mutate(c, mutationRate))
          .toList();
    }
    return pop;
  }
}

SpaceGrid randomSolution(SpaceGrid grid, Random random) =>
    Planner(grid, random).plan();

void main(List<String> args) {
  // Do I care about segment direction?  I don't think so in the beginning.

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

  final solution = Optimizer(grid).run(100).first;
  print(solution);
}
