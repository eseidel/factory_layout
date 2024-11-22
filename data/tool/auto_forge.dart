// Tool to import auto_forge data from the game.
// AutoForge uses lua (transpiled from typescript).

import 'dart:io';

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

  // We care about recipes.lua.
  final recipesFile = File('$scriptsPath/recipes.lua');
  if (!recipesFile.existsSync()) {
    print('File does not exist: ${recipesFile.path}');
    return;
  }

  print('Reading recipes file: ${recipesFile.path}');
  final recipesLua = recipesFile.readAsStringSync();

  final parser = RecipeParser();
  final recipes = parser.parse(recipesLua);
  print('Parsed ${recipes.length} recipes.');
  // Generate the yaml files with the data.
}
