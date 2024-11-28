// Tool to import auto_forge data from the game.
// AutoForge uses lua (transpiled from typescript).

import 'dart:io';

import 'package:data/loot_parser.dart';
import 'package:data/recipe_parser.dart';

void main(List<String> args) {
  // Take in a path to the scripts directory.
  if (args.length != 1) {
    print('Usage: auto_forge <scriptsPath>');
    return;
  }
  final scriptsPath = args[0];
  final directory = Directory(scriptsPath);
  if (!directory.existsSync()) {
    print('Directory does not exist: $scriptsPath');
    return;
  }

  String readLuaFile(String path) {
    final file = File('$scriptsPath/$path');
    if (!file.existsSync()) {
      throw ArgumentError('File does not exist: $path');
    }
    return file.readAsStringSync();
  }

  final recipes = RecipeParser().parse(readLuaFile('recipes.lua'));
  print('Parsed ${recipes.length} recipes.');

  final lootSystem = LootParser().parse(readLuaFile('loot.lua'));
  print('Parsed ${lootSystem.groups.length} loot groups '
      'and ${lootSystem.batches.length} loot batches.');

  // Generate the yaml files with the data.

  // Print all recipes which produce material.iron_ingot.
  findLoot(recipes, lootSystem, 'material.iron_ingot');
}

void findLoot(List<Recipe> recipes, LootSystem lootSystem, String desired,
    {Set<LootOrigin> allowedOrigins = const {
      LootOrigin.husbandry,
      LootOrigin.farming
    }}) {
  for (final recipe in recipes) {
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
  for (final entry in lootSystem.batches.entries) {
    final batch = entry.value;
    if (allowedOrigins.contains(batch.origin) &&
        batch.listings.any((listing) => listing.groups.any((group) =>
            group.entries.any((entry) => entry.item.name == desired)))) {
      print(batch.name);
    }
  }
}
