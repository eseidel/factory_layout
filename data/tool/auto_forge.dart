// Tool to import auto_forge data from the game.
// AutoForge uses lua (transpiled from typescript).

import 'dart:io';

import 'package:collection/collection.dart';

class Item {
  final String name;

  Item(this.name);
}

extension CaseTools on String {
  String toLoweredCamel() {
    return this[0].toLowerCase() + substring(1);
  }
}

enum CraftSite {
  assembler,
  forge,
  player,
  warfare,
  lavaForge;

  static CraftSite fromString(String s) {
    final parts = s.split('.');
    if (parts.length != 2) {
      throw ArgumentError('Invalid CraftSite: $s');
    }
    if (parts[0] != 'CraftSite') {
      throw ArgumentError('Invalid CraftSite: $s');
    }
    final name = parts[1].toLoweredCamel();
    final match = values.firstWhereOrNull((e) => e.name == name);
    if (match == null) {
      throw ArgumentError('Unknown CraftSite: $s');
    }
    return match;
  }
}

enum CraftTab {
  assembler,
  warfare,
  structures,
  byproduct,
  materials;

  static CraftTab fromString(String s) {
    final parts = s.split('.');
    if (parts.length != 2) {
      throw ArgumentError('Invalid CraftTab: $s');
    }
    if (parts[0] != 'CraftTab') {
      throw ArgumentError('Invalid CraftTab: $s');
    }
    final name = parts[1].toLowerCase();
    final match = values.firstWhereOrNull((e) => e.name == name);
    if (match == null) {
      throw ArgumentError('Unknown CraftTab: $s');
    }
    return match;
  }
}

class Recipe {
  final String name;
  final Map<Item, int> inputs;
  final Map<Item, int> outputs;
  final Duration duration;
  final Set<CraftSite> sites;
  final CraftTab tab;
  final int id;
  final bool unlocked;

  Recipe(this.name, this.inputs, this.outputs, this.duration, this.sites,
      this.tab, this.id, this.unlocked);
}

class RecipeParser {
  Map<Item, int> itemCountsFromLua(String lua) {
    final items = <Item, int>{};
    // This will be a list of Item.create("material.mana", 5)
    final regexp = RegExp(r'Item.create\("(.*?)", (\d+)\)');
    final matches = regexp.allMatches(lua);
    for (final match in matches) {
      final name = match.group(1)!;
      final count = int.parse(match.group(2)!);
      items[Item(name)] = count;
    }
    return items;
  }

  Duration durationFromLua(String lua) {
    final seconds = double.parse(lua.substring(8, lua.length - 1));
    return Duration(microseconds: (seconds * 1000).floor());
  }

  Set<CraftSite> sitesFromLua(String lua) {
    final regexp = RegExp(r'(CraftSite\..*?),');
    final matches = regexp.allMatches(lua);
    return matches.map((m) => m.group(1)!).map(CraftSite.fromString).toSet();
  }

  Recipe recipeFromMatch(RegExpMatch match) {
    // Get the line number from the match for errors.
    final lineNumber = match.input.substring(0, match.start).split('\n').length;
    print('Parsing recipe at line $lineNumber');

    final name = match.namedGroup('name')!;
    final inputs = match.namedGroup('inputs');
    final outputs = match.namedGroup('outputs');
    final time = match.namedGroup('time');
    final sites = match.namedGroup('sites');
    final tab = match.namedGroup('tab');
    final id = match.namedGroup('id');
    final unlocked = match.namedGroup('unlocked');
    return Recipe(
      name,
      itemCountsFromLua(inputs!),
      itemCountsFromLua(outputs!),
      durationFromLua(time!),
      sitesFromLua(sites!),
      CraftTab.fromString(tab!),
      int.parse(id!),
      unlocked == 'true',
    );
  }
}

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

  // Look for sections like:
// CraftManager:add(__TS__New(
//     CraftRecipe,
//     "IronIngot",
//     {Item.create("material.iron_ore", 1)},
//     {Item.create("material.iron_ingot", 1)},
//     seconds(6),
//     CraftSite.Forge,
//     CraftTab.Materials,
//     0,
//     true
// ))
  final regexp = RegExp(
      r'CraftManager:add\(__TS__New\('
      r'\s*CraftRecipe,$'
      r'\s*"(?<name>.*)",$'
      r'\s*\{(?<inputs>.*?)\},$'
      r'\s*\{(?<outputs>.*?)\},$'
      r'\s*(?<time>.*),$'
      r'\s*(?<sites>.*),$'
      r'\s*(?<tab>.*),$'
      r'\s*(?<id>\d+),$'
      r'\s*(?<unlocked>true|false)$'
      r'\s*\)\)',
      multiLine: true);
  final recipesLua = recipesFile.readAsStringSync();
  final matches = regexp.allMatches(recipesLua);
  print('Found ${matches.length} recipes.');
  final parser = RecipeParser();
  final recipes = matches.map(parser.recipeFromMatch).toList();
  print('Parsed ${recipes.length} recipes.');
  // Generate the yaml files with the data.
}
