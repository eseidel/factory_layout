import 'package:collection/collection.dart';

import 'parser.dart';

class LootSystem {
  final Map<String, LootGroup> groups;
  final Map<String, LootBatch> batches;

  LootSystem({
    required this.groups,
    required this.batches,
  });

  LootGroup group(String name) {
    final group = groups[name];
    if (group == null) {
      throw ArgumentError('Unknown loot group: $name');
    }
    return group;
  }
}

class QuantityWeights {
  List<DropAmount> dropAmounts = [];

  QuantityWeights(this.dropAmounts);

  QuantityWeights.single(int count, {int emptyChance = 0}) {
    dropAmounts = [DropAmount(100 - emptyChance, count)];
  }
}

class DropAmount {
  final int chance;
  final int count;

  DropAmount(this.chance, this.count);
}

class LootGroupOrItem {}

class LootItem extends LootGroupOrItem {
  final String name;
  final QuantityWeights quantityWeights;
  final bool isBonus;

  LootItem({
    required this.name,
    required this.quantityWeights,
    required this.isBonus,
  });
}

class LootGroupEntry {
  final LootItem item;
  final int chance;

  LootGroupEntry(this.item, this.chance);
}

// Loot groups are a set of items which may all drop at once.
// Each entry has an independent chance to drop.
class LootGroup extends LootGroupOrItem {
  final List<LootGroupEntry> entries;

  LootGroup(this.entries);
}

enum LootOrigin {
  treasure,
  environment,
  monster,
  spawner,
  husbandry,
  farming,
  plant;

  static LootOrigin fromString(String s) {
    final parts = s.split('.');
    if (parts.length != 2) {
      throw ArgumentError('Invalid LootOrigin: $s');
    }
    if (parts[0] != 'LootOrigin') {
      throw ArgumentError('Invalid LootOrigin: $s');
    }
    final name = parts[1].toLoweredCamel();
    final match = values.firstWhereOrNull((e) => e.name == name);
    if (match == null) {
      throw ArgumentError('Unknown LootOrigin: $s');
    }
    return match;
  }
}

class LootListing {
  // Lua holds a list of LootItems or LootGroups.
  List<LootGroupOrItem> items = [];

  LootListing.item({
    required String name,
    required int count,
    required bool isBonus,
    required int emptyChance,
  }) : items = [
          LootItem(
              name: name,
              quantityWeights:
                  QuantityWeights.single(count, emptyChance: emptyChance),
              isBonus: isBonus)
        ];

  LootListing.entry({
    required LootItem item,
    required int emptyChance,
  });

  LootListing.group({
    required LootSystem system,
    required String group,
    required QuantityWeights quantityWeights,
    required int emptyChance,
  }) : items = [system.group(group)];

  LootListing.fluid({
    required String name,
    required int count,
    required int emptyChance,
  }) : items = [
          LootItem(
              name: name,
              quantityWeights:
                  QuantityWeights.single(count, emptyChance: emptyChance),
              isBonus: false)
        ];
}

class LootBatch {
  final String name;
  final LootOrigin origin;
  final List<LootListing> listings;

  LootBatch(this.name, this.origin, this.listings);
}

class LootParser extends Parser {
  final LootSystem system = LootSystem(groups: {}, batches: {});

  (String, LootGroup) _parseLootSystemAddGroup(Exp exp) {
    // Example:
    // LootSystem:addGroup(
    //     "wood_chest_group",
    //     LootGroup:create({{
    //         __TS__New(LootItem, "material.repair_tools", {{10, 100}}, false),
    //         50
    //     }})
    // )
    if (exp is! FuncCallExp) {
      fail(exp, '$exp is not FuncCallExp');
    }
    final args = exp.args;
    if (args.length != 2) {
      fail(exp, 'Invalid loot group');
    }
    final name = (args[0] as StringExp).str;
    final group = _parseLootGroup(args[1]);
    return (name, group);
  }

  LootGroup _parseLootGroup(Exp exp) {
    if (exp is! FuncCallExp) {
      fail(exp, 'Invalid loot group');
    }
    final args = exp.args;
    if (args.length != 1) {
      fail(exp, 'Invalid loot group');
    }
    return _parseLootGroupEntries(args[0]);
  }

  LootGroup _parseLootGroupEntries(Exp exp) {
    if (exp is! TableConstructorExp) {
      fail(exp, 'Invalid loot group');
    }
    final entries = <LootGroupEntry>[];
    for (final valExp in exp.valExps) {
      final entry = _parseLootGroupEntry(valExp);
      entries.add(entry);
    }
    return LootGroup(entries);
  }

  LootItem _parseLootItem(Exp exp) {
    // Example:
    // __TS__New(LootItem, "material.repair_tools", {{10, 100}}, false)
    if (exp is! FuncCallExp) {
      fail(exp, 'Invalid loot item');
    }
    final args = exp.args;
    if (args.length != 4) {
      fail(exp, 'Invalid loot item');
    }
    final name = (args[1] as StringExp).str;
    final quantityWeights = _parseQuantityWeights(args[2]);
    final isBonus = (args[3] is TrueExp);
    return LootItem(
      name: name,
      quantityWeights: quantityWeights,
      isBonus: isBonus,
    );
  }

  QuantityWeights _parseQuantityWeights(Exp exp) {
    if (exp is! TableConstructorExp) {
      fail(exp, 'Invalid drop amounts');
    }
    final dropAmounts = <DropAmount>[];
    for (final valExp in exp.valExps) {
      if (valExp is! TableConstructorExp) {
        fail(valExp, 'Invalid drop amount');
      }
      final chance = (valExp.valExps[0] as IntegerExp).val;
      final count = (valExp.valExps[1] as IntegerExp).val;
      dropAmounts.add(DropAmount(chance, count));
    }
    return QuantityWeights(dropAmounts);
  }

  LootGroupEntry _parseLootGroupEntry(Exp exp) {
    if (exp is! TableConstructorExp) {
      fail(exp, 'Invalid loot item');
    }
    final item = _parseLootItem(exp.valExps[0]);
    final chance = (exp.valExps[1] as IntegerExp).val;
    return LootGroupEntry(item, chance);
  }

  LootOrigin _parseLootOrigin(Exp exp) {
    if (exp is! TableAccessExp) {
      fail(exp, 'Invalid loot origin');
    }
    return LootOrigin.fromString(tableAccessToString(exp));
  }

  LootListing _parseLootListing(Exp exp) {
    // Example:
    // LootListing:item("material.obsidian", 3, false, 0)
    // or
    // LootListing:entry(
    //     __TS__New(LootItem, "material.mana", {{5, 40}, {6, 60}}, false),
    //     0
    // )
    // or
    // LootListing:group(LootSystem, "clay_pot", 1, 20)
    if (exp is! FuncCallExp) {
      fail(exp, 'Invalid loot listing');
    }
    final prefix = (exp.prefixExp as NameExp).name;
    final name = exp.nameExp?.str;
    final fullName = '$prefix:$name';
    if (fullName == 'LootListing:item') {
      final args = exp.args;
      if (args.length != 4) {
        fail(exp, 'Invalid loot listing');
      }
      final itemName = (args[0] as StringExp).str;
      final count = (args[1] as IntegerExp).val;
      final isBonus = (args[2] is TrueExp);
      final emptyChance = (args[3] as IntegerExp).val;
      return LootListing.item(
        name: itemName,
        count: count,
        isBonus: isBonus,
        emptyChance: emptyChance,
      );
    } else if (fullName == 'LootListing:entry') {
      final args = exp.args;
      if (args.length != 2) {
        fail(exp, 'Invalid loot listing');
      }
      final item = _parseLootItem(args[0]);
      final emptyChance = (args[1] as IntegerExp).val;
      return LootListing.entry(item: item, emptyChance: emptyChance);
    } else if (fullName == 'LootListing:group') {
      final args = exp.args;
      if (args.length != 4) {
        fail(exp, 'Invalid loot listing');
      }
      final group = (args[1] as StringExp).str;
      final QuantityWeights quantityWeights;
      if (args[2] is IntegerExp) {
        quantityWeights = QuantityWeights.single((args[2] as IntegerExp).val);
      } else {
        quantityWeights = _parseQuantityWeights(args[2]);
      }
      final emptyChance = (args[3] as IntegerExp).val;
      return LootListing.group(
        system: system,
        group: group,
        quantityWeights: quantityWeights,
        emptyChance: emptyChance,
      );
    } else if (fullName == 'LootListing:fluid') {
      // {LootListing:fluid(FluidType.Lava, 45, 0)}
      final args = exp.args;
      if (args.length != 3) {
        fail(exp, 'Invalid loot listing');
      }
      final fluidType = args[0] as TableAccessExp;
      final quantity = (args[1] as IntegerExp).val;
      final emptyChance = (args[2] as IntegerExp).val;
      return LootListing.fluid(
        name: tableAccessToString(fluidType),
        count: quantity,
        emptyChance: emptyChance,
      );
    } else {
      fail(exp, 'Invalid loot listing');
    }
  }

  List<LootListing> _parseLootListings(Exp exp) {
    if (exp is! TableConstructorExp) {
      fail(exp, 'Invalid loot listings');
    }
    final listings = <LootListing>[];
    for (final valExp in exp.valExps) {
      final listing = _parseLootListing(valExp);
      listings.add(listing);
    }
    return listings;
  }

  LootBatch _parseLootBatch(Exp exp) {
    // Example:
    // LootSystem:addBatch(
    //     "volcanic_tooth_small",
    //     LootOrigin.Environment,
    //     {LootListing:item("material.obsidian", 3, false, 0)}
    // )
    if (exp is! FuncCallExp) {
      fail(exp, 'Invalid loot batch');
    }

    final args = exp.args;
    if (args.length != 3) {
      fail(exp, 'Invalid loot batch');
    }

    final name = (args[0] as StringExp).str;
    final origin = _parseLootOrigin(args[1]);
    final listings = _parseLootListings(args[2]);

    return LootBatch(name, origin, listings);
  }

  LootSystem parse(String content) {
    final block = parseLua(content);
    final addLoot = block.stats.firstWhere((stat) {
      if (stat is LocalFuncDefStat && stat.name == 'addLoot') {
        return true;
      }
      return false;
    }) as LocalFuncDefStat;
    for (final stat in addLoot.exp.block.stats) {
      if (stat is FuncCallStat) {
        final prefix = (stat.exp.prefixExp as NameExp).name;
        final name = stat.exp.nameExp?.str;
        final fullName = '$prefix:$name';
        if (fullName == "LootSystem:addGroup") {
          final (name, group) = _parseLootSystemAddGroup(stat.exp);
          system.groups[name] = group;
        }
        if (fullName == "LootSystem:addBatch") {
          final batch = _parseLootBatch(stat.exp);
          system.batches[batch.name] = batch;
        }
      }
    }

    return system;
  }
}
