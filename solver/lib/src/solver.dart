import 'package:collection/collection.dart';
import 'package:factory_layout/factory_layout.dart';

class Solution {
  Solution({
    required this.inputsPerMinute,
    required this.outputsPerMinute,
    required this.machines,
  });

  final Map<Item, double> inputsPerMinute;
  final Map<Item, double> outputsPerMinute;
  final Map<Recipe, int> machines;
}

Solution solve(Item item, int minPerMinute) {
  // Starting with a given item and a desired minimum rate.
  // Find the recipe that produces it.
  // Figure out the multiplier needed to meet the minimum rate.
  // Recurse on the inputs of the recipe.
  // Return the inputs and outputs of the recipe.
  final machines = <Recipe, int>{};

  final recipe = recipes.firstWhereOrNull((r) => r.outputs.containsKey(item));
  if (recipe == null) {
    throw ArgumentError('No recipe found for $item');
  }

  final outputsPerMinute = <Item, double>{...recipe.outputsPerMinute()};
  final inputsPerMinute = <Item, double>{};
  final perMinute = 60 / recipe.seconds;
  final multiplier = (minPerMinute / perMinute).ceil();
  machines[recipe] = multiplier;
  for (final input in recipe.inputs.keys) {
    final inputRate = recipe.inputs[input]! * multiplier;
    final inputSolution = solve(input, inputRate);
    inputSolution.inputsPerMinute.forEach((key, value) {
      inputsPerMinute[key] = inputsPerMinute[key] ?? 0 + value;
    });
    inputSolution.outputsPerMinute.forEach((key, value) {
      outputsPerMinute[key] = outputsPerMinute[key] ?? 0 + value;
    });
    inputSolution.machines.forEach((key, value) {
      machines[key] = machines[key] ?? 0 + value;
    });
  }
  return Solution(
    inputsPerMinute: inputsPerMinute,
    outputsPerMinute: outputsPerMinute,
    machines: machines,
  );
}
