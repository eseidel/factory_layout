// Tool to import auto_forge data from the game.
// AutoForge uses lua (transpiled from typescript).

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:lua_dardo/src/compiler/ast/exp.dart';
import 'package:lua_dardo/src/compiler/ast/stat.dart';
import 'package:lua_dardo/src/compiler/parser/parser.dart';

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
  infuser,
  elementalizer,
  manufacturer,
  refiner,
  compressor,
  distiller,
  byproduct,
  replicator,
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

  Recipe({
    required this.name,
    required this.inputs,
    required this.outputs,
    required this.duration,
    required this.sites,
    required this.tab,
    required this.id,
    required this.unlocked,
  });
}

class RecipeParser {
  Set<CraftSite> _parseCraftSites(Exp exp) {
    if (exp is TableAccessExp) {
      final prefix = (exp.prefixExp as NameExp?)?.name;
      if (prefix != 'CraftSite') {
        throw 'Invalid CraftSite $exp on line ${exp.lastLine}';
      }
      final key = (exp.keyExp as StringExp).str;
      return {CraftSite.fromString("$prefix.$key")};
    }
    if (exp is FuncCallExp) {
      return exp.args.map(_parseCraftSites).expand((e) => e).toSet();
    }
    throw 'Invalid CraftSite $exp on line ${exp.lastLine}';
  }

  Duration _parseDuration(Exp exp) {
    if (exp is! FuncCallExp) {
      throw 'Invalid duration $exp on line ${exp.lastLine}';
    }
    final name = (exp.prefixExp as NameExp).name;
    if (name == 'seconds') {
      final arg = exp.args.first;
      final int milliseconds;
      if (arg is IntegerExp) {
        milliseconds = arg.val * 1000;
      } else if (arg is FloatExp) {
        milliseconds = (arg.val * 1000).toInt();
      } else {
        throw 'Invalid duration $exp on line ${exp.lastLine}';
      }
      return Duration(milliseconds: milliseconds);
    } else {
      throw 'Unsupported duration type $name $exp on line ${exp.lastLine}';
    }
  }

  (Item, int) _parseItemCount(Exp exp) {
    // Can be either:
    //  Item.create("material.mineral", 5),
    // __TS__New(FluidItem, FluidType.Water, 10)
    if (exp is! FuncCallExp) {
      throw 'Invalid item count $exp on line ${exp.lastLine}';
    }
    final String name;
    final Exp prefixExp = exp.prefixExp;
    if (prefixExp is NameExp) {
      name = (prefixExp).name;
    } else if (prefixExp is TableAccessExp) {
      final key = prefixExp.keyExp;
      if (key is StringExp) {
        name = key.str;
      } else {
        throw 'Invalid item count $exp on line ${exp.lastLine}';
      }
    } else {
      throw 'Invalid item count $exp on line ${exp.lastLine}';
    }
    if (name == 'create') {
      final args = exp.args;
      final int count;
      if (args.length == 1) {
        count = 1;
      } else if (args.length == 2) {
        count = (args[1] as IntegerExp).val;
      } else {
        throw 'Invalid item count $exp on line ${exp.lastLine}';
      }
      final itemName = (args[0] as StringExp).str;
      return (Item(itemName), count);
    } else if (name == '__TS__New') {
      final args = exp.args;
      if (args.length != 3) {
        throw 'Invalid item count $exp on line ${exp.lastLine}';
      }
      final itemExp = (args[1] as TableAccessExp);
      final prefix = (itemExp.prefixExp as NameExp?)?.name;
      final key = (itemExp.keyExp as StringExp).str;
      final itemName = '$prefix.$key';
      final count = (args[2] as IntegerExp).val;
      return (Item(itemName), count);
    } else {
      print(name);
      throw 'Unsupported item count $name $exp on line ${exp.lastLine}';
    }
  }

  Map<Item, int> _parseItemCounts(Exp exp) {
    if (exp is! TableConstructorExp) {
      throw 'Invalid item counts $exp on line ${exp.lastLine}';
    }
    final items = <Item, int>{};
    for (final valExp in exp.valExps) {
      final (item, count) = _parseItemCount(valExp);
      items[item] = count;
    }
    return items;
  }

  CraftTab _parseCraftTab(Exp exp) {
    if (exp is! TableAccessExp) {
      throw 'Invalid CraftTab $exp on line ${exp.lastLine}';
    }
    final prefix = (exp.prefixExp as NameExp?)?.name;
    if (prefix != 'CraftTab') {
      throw 'Invalid CraftTab $exp on line ${exp.lastLine}';
    }
    final key = (exp.keyExp as StringExp).str;
    return CraftTab.fromString("$prefix.$key");
  }

  Recipe _parseCraftManagerAdd(FuncCallStat stat) {
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
    final args = stat.exp.args;
    if (args.length != 1) {
      throw 'Invalid CraftManager:add call.';
    }
    if (args.first is! FuncCallExp) {
      throw 'Invalid CraftManager:add call.';
    }
    final inner = args.first as FuncCallExp;
    if (inner.args.length != 9) {
      throw 'Invalid CraftRecipe call.';
    }
    // Ignore the first argument.
    final name = (inner.args[1] as StringExp).str;
    final inputs = _parseItemCounts(inner.args[2]);
    final outputs = _parseItemCounts(inner.args[3]);
    final time = _parseDuration(inner.args[4]);
    final sites = _parseCraftSites(inner.args[5]);
    final tab = _parseCraftTab(inner.args[6]);
    final id = (inner.args[7] as IntegerExp).val.toInt();
    final unlocked = (inner.args[8] is TrueExp);
    return Recipe(
      name: name,
      inputs: inputs,
      outputs: outputs,
      duration: time,
      sites: sites,
      tab: tab,
      id: id,
      unlocked: unlocked,
    );
  }

  List<Recipe> parse(String content) {
    final recipes = <Recipe>[];
    final block = Parser.parse(content, 'main');
    final addRecipes = block.stats.firstWhere((stat) {
      if (stat is LocalFuncDefStat && stat.name == 'addRecipes') {
        return true;
      }
      return false;
    }) as LocalFuncDefStat;
    for (final stat in addRecipes.exp.block.stats) {
      if (stat is FuncCallStat) {
        final name = stat.exp.nameExp?.str;
        // We want the CraftManager:add calls.
        if (name == "add") {
          final Recipe recipe = _parseCraftManagerAdd(stat);
          recipes.add(recipe);
        }
      }
    }
    return recipes;
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
  final recipesLua = recipesFile.readAsStringSync();

  final parser = RecipeParser();
  final recipes = parser.parse(recipesLua);
  print('Parsed ${recipes.length} recipes.');
  // Generate the yaml files with the data.
}
