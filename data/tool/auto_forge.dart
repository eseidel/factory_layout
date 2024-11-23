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

  final loot = LootParser().parse(readLuaFile('loot.lua'));
  print('Parsed ${loot.length} loot.');

  // Generate the yaml files with the data.
}
