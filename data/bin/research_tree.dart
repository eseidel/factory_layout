// Tool to import auto_forge data from the game.
// AutoForge uses lua (transpiled from typescript).

import 'package:data/data.dart';

void main() {
  final data = defaultData();
  printResearchTree(data);
}

void printResearchTree(Data data) {
  // List with columns:
  print("Technology	Prerequisites	Costs	Unlocks");
  for (final technology in data.technologies.technologies) {
    final name = technology.name;
    final prerequisites =
        technology.dependencies.map((dep) => dep.name).join(', ');
    final costs = technology.inputs.entries
        .map((entry) => '${entry.value} ${entry.key.name}')
        .join(', ');
    final unlocks = technology.recipes.join(', ');
    print('$name\t$prerequisites\t$costs\t$unlocks');
  }
}
