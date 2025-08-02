// Tool to import auto_forge data from the game.
// AutoForge uses lua (transpiled from typescript).

import 'package:data/data.dart';

void main() {
  final data = defaultData();
  // Print all recipes which produce material.iron_ingot.
  findLoot(data, 'material.iron_ingot');
}

void findLoot(Data data, String desired,
    {Set<LootOrigin> allowedOrigins = const {
      LootOrigin.husbandry,
      LootOrigin.farming
    }}) {
  for (final recipe in data.recipes) {
    if (recipe.outputs.keys.any((output) => output.name == desired)) {
      print(recipe.name);
    }
  }

  // Print any loot groups which produce material.iron_ingot.
  // for (final entry in lootSystem.groups.entries) {
  //   final name = entry.key;
  //   final group = entry.value;
  //   if (group.entries.any((entry) => entry.item.name == desired)) {
  //     print(name);
  //   }
  // }

  // Print any loot batches which produce material.iron_ingot.
  for (final entry in data.loot.batches.entries) {
    final batch = entry.value;
    if (allowedOrigins.contains(batch.origin) &&
        batch.listings.any((listing) => listing.groups.any((group) =>
            group.entries.any((entry) => entry.item.name == desired)))) {
      print(batch.name);
    }
  }
}
