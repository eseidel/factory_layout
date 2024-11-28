import 'dart:io';

import 'src/models/loot.dart';
import 'src/parsers/loot_parser.dart';
import 'src/parsers/recipe_parser.dart';
import 'src/parsers/technologies_parser.dart';

export 'src/models/loot.dart';

class Data {
  final LootSystem loot;
  final List<Recipe> recipes;
  final TechnologyManager technologies;

  Data({
    required this.loot,
    required this.recipes,
    required this.technologies,
  });

  static Data load(String scriptsPath) {
    final directory = Directory(scriptsPath);
    if (!directory.existsSync()) {
      throw ArgumentError('Directory does not exist: $scriptsPath');
    }

    String readLuaFile(String path) {
      final file = File('$scriptsPath/$path');
      if (!file.existsSync()) {
        throw ArgumentError('File does not exist: $path');
      }
      return file.readAsStringSync();
    }

    final recipes = RecipeParser().parse(readLuaFile('recipes.lua'));
    final loot = LootParser().parse(readLuaFile('loot.lua'));
    final technologies =
        TechnologiesParser().parse(readLuaFile('technologies.lua'));

    return Data(
      loot: loot,
      recipes: recipes,
      technologies: technologies,
    );
  }
}
