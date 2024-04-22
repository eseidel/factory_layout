import 'package:factory_layout/factory_layout.dart';
import 'package:factory_layout/src/items.dart';

// Factorio keeps name, inputs, outputs, energy required and enabled on a recipe
// I think the energy required is a proxy for time?
class Recipe {
  Recipe(this.name, this.outputs, this.inputs, this.seconds);

  Recipe.one(Item output, this.inputs, this.seconds)
      : name = output.name,
        outputs = {output: 1};
  final String name;

  // Per cycle.
  final Map<Item, int> outputs;
  final Map<Item, int> inputs;
  final double seconds; // Cycle time.

  Map<Item, double> outputsPerMinute() {
    final perMinute = 60 / seconds;
    return outputs.map((key, value) => MapEntry(key, value * perMinute));
  }

  Map<Item, double> inputsPerMinute() {
    final perMinute = 60 / seconds;
    return inputs.map((key, value) => MapEntry(key, value * perMinute));
  }

  @override
  String toString() => name;
}

Recipe _one(Item output, Map<Item, int> inputs, double seconds) =>
    Recipe.one(output, inputs, seconds);

final recipes = [
  // Hack to require wood.
  _one(ironIngot, {ironOre: 1, wood: 1}, 6),
  _one(ironGear, {ironIngot: 1}, 2), // check time
  Recipe('Plank', {plank: 2}, {wood: 1}, 2),
  _one(crank, {ironGear: 1, plank: 1}, 2), // check time
  // This is a bit of a hack.
  _one(ironOre, {}, 9),
  _one(wood, {}, 9),
];
