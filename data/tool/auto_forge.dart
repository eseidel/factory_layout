// Tool to import auto_forge data from the game.
// AutoForge uses lua (transpiled from typescript).

import 'dart:io';

import 'package:data/data.dart';
import 'package:yaml_edit/yaml_edit.dart';

void writeYamlFiles(Data data, String outPath) {
  // Generate the yaml files with the data.
  final outDir = Directory('outPath');
  if (!outDir.existsSync()) {
    outDir.createSync();
  }
  writeAsYaml('out/recipes.yaml',
      data.recipes.map((recipe) => recipe.toJson()).toList());
  writeAsYaml('out/loot.yaml', data.loot.toJson());
  writeAsYaml('out/technologies.yaml', data.technologies.toJson());
}

void main(List<String> args) {
  // Take in a path to the scripts directory.
  if (args.length != 1) {
    print('Usage: auto_forge <scriptsPath>');
    return;
  }
  final scriptsPath = args[0];
  final data = Data.load(scriptsPath);

  print('Parsed ${data.recipes.length} recipes.');
  print('Parsed ${data.loot.groups.length} loot groups '
      'and ${data.loot.batches.length} loot batches.');
  print('Parsed ${data.technologies.technologies.length} technologies.');

  writeYamlFiles(data, 'out');

  // Print all recipes which produce material.iron_ingot.
  findLoot(data, 'material.iron_ingot');
}

void writeAsYaml(String path, dynamic json) {
  final file = File(path);
  final yamlEditor = YamlEditor('')..update([], json);
  file.writeAsStringSync(yamlEditor.toString());
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
