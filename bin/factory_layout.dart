import 'package:factory_layout/factory_layout.dart';

void main(List<String> args) {
  // Given an item, solve for inputs needed at what rates.
  // Return inputs/outputs.
  // Print the solution.
  final item = ironOre;
  const minPerMinute = 1;
  logger.info('Solving for $item at $minPerMinute per minute');
  final solution = solve(item, minPerMinute);
  logger
    ..info('Inputs: ${solution.inputsPerMinute}')
    ..info('Outputs: ${solution.outputsPerMinute}')
    ..info('Machines: ${solution.machines}');
}
