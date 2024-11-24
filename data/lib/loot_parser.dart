import 'parser.dart';

class DropAmount {
  final int chance;
  final int count;

  DropAmount(this.chance, this.count);
}

class LootItem {
  final String name;
  final List<DropAmount> dropAmounts;
  final bool isBonus;

  LootItem(this.name, this.dropAmounts, this.isBonus);
}

class LootGroupEntry {
  final LootItem item;
  final int chance;

  LootGroupEntry(this.item, this.chance);
}

// Loot groups are a set of items which may all drop at once.
// Each entry has an independent chance to drop.
class LootGroup {
  final List<LootGroupEntry> entries;

  LootGroup(this.entries);
}

class LootParser extends Parser {
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
    final dropAmounts = _parseDropAmounts(args[2]);
    final isBonus = (args[3] is TrueExp);
    return LootItem(name, dropAmounts, isBonus);
  }

  List<DropAmount> _parseDropAmounts(Exp exp) {
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
    return dropAmounts;
  }

  LootGroupEntry _parseLootGroupEntry(Exp exp) {
    if (exp is! TableConstructorExp) {
      fail(exp, 'Invalid loot item');
    }
    final item = _parseLootItem(exp.valExps[0]);
    final chance = (exp.valExps[1] as IntegerExp).val;
    return LootGroupEntry(item, chance);
  }

  List<LootItem> parse(String content) {
    final lootItems = <LootItem>[];

    final groupsByName = <String, LootGroup>{};

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
          groupsByName[name] = group;
          print("LootSystem:addGroup $name");
        }
        if (fullName == "LootSystem:addBatch") {
          print("LootSystem:addBatch");
        }
      }
    }

    return lootItems;
  }
}
