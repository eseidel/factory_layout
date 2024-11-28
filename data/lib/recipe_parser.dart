import 'package:collection/collection.dart';

import 'parser.dart';

class Item {
  final String name;

  Item(this.name);
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

class RecipeParser extends Parser {
  Set<CraftSite> _parseCraftSites(Exp exp) {
    if (exp is TableAccessExp) {
      final name = tableAccessToString(exp);
      return {CraftSite.fromString(name)};
    }
    if (exp is FuncCallExp) {
      return exp.args.map(_parseCraftSites).expand((e) => e).toSet();
    }
    fail(exp, 'Invalid CraftSite');
  }

  Duration _parseDuration(Exp exp) {
    if (exp is! FuncCallExp) {
      fail(exp, 'Invalid duration');
    }
    final name = (exp.prefixExp as NameExp).name;
    if (name != 'seconds') {
      fail(exp, 'Invalid duration');
    }
    final arg = exp.args.first;
    final int milliseconds;
    if (arg is IntegerExp) {
      milliseconds = arg.val * 1000;
    } else if (arg is FloatExp) {
      milliseconds = (arg.val * 1000).toInt();
    } else {
      fail(exp, 'Invalid duration');
    }
    return Duration(milliseconds: milliseconds);
  }

  (Item, int) _parseItemCount(Exp exp) {
    // Can be either:
    //  Item.create("material.mineral", 5),
    // __TS__New(FluidItem, FluidType.Water, 10)
    if (exp is! FuncCallExp) {
      fail(exp, 'Invalid item count');
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
        fail(exp, 'Invalid item count');
      }
    } else {
      fail(exp, 'Invalid item count');
    }
    if (name == 'create') {
      final args = exp.args;
      final int count;
      if (args.length == 1) {
        count = 1;
      } else if (args.length == 2) {
        count = (args[1] as IntegerExp).val;
      } else {
        fail(exp, 'Invalid item count');
      }
      final itemName = (args[0] as StringExp).str;
      return (Item(itemName), count);
    } else if (name == '__TS__New') {
      final args = exp.args;
      if (args.length != 3) {
        fail(exp, 'Invalid item count');
      }
      final itemExp = (args[1] as TableAccessExp);
      final itemName = tableAccessToString(itemExp);
      final count = (args[2] as IntegerExp).val;
      return (Item(itemName), count);
    } else {
      fail(exp, 'Invalid item count');
    }
  }

  Map<Item, int> _parseItemCounts(Exp exp) {
    if (exp is! TableConstructorExp) {
      fail(exp, 'Invalid item counts');
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
      fail(exp, 'Invalid CraftTab');
    }
    return CraftTab.fromString(tableAccessToString(exp));
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
      fail(stat.exp, 'Invalid CraftManager:add call');
    }
    if (args.first is! FuncCallExp) {
      fail(stat.exp, 'Invalid CraftManager:add call');
    }
    final inner = args.first as FuncCallExp;
    if (inner.args.length != 9) {
      fail(inner, 'Invalid CraftRecipe');
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
    final block = parseLua(content);
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
          recipes.add(_parseCraftManagerAdd(stat));
        }
      }
    }
    return recipes;
  }
}
