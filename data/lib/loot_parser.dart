import 'parser.dart';

class LootItem {}

class LootParser extends Parser {
  List<LootItem> parse(String content) {
    final lootItems = <LootItem>[];

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
          print("LootSystem:addGroup");
        }
        if (fullName == "LootSystem:addBatch") {
          print("LootSystem:addBatch");
        }
      }
    }

    return lootItems;
  }
}
