import 'package:collection/collection.dart';

import '../extensions/string.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'groups': {
        for (final entry in groups.entries) entry.key: entry.value.toJson(),
      },
      'batches': {
        for (final entry in batches.entries) entry.key: entry.value.toJson(),
      },
    };
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

class LootItem {
  final String name;
  final QuantityWeights quantityWeights;
  final bool isBonus;

  LootItem({
    required this.name,
    required this.quantityWeights,
    this.isBonus = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantityWeights': quantityWeights.dropAmounts
          .map((e) => {'chance': e.chance, 'count': e.count})
          .toList(),
      'isBonus': isBonus,
    };
  }
}

class LootGroupEntry {
  final LootItem item;
  final int chance;

  LootGroupEntry(this.item, this.chance);

  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'chance': chance,
    };
  }
}

// Loot groups are a set of items which may all drop at once.
// Each entry has an independent chance to drop.
class LootGroup {
  final List<LootGroupEntry> entries;

  LootGroup(this.entries);

  LootGroup.single(LootItem item, {int chance = 100})
      : entries = [LootGroupEntry(item, chance)];

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
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
  List<LootGroup> groups = [];

  LootListing.item({
    required String name,
    required int count,
    required bool isBonus,
    required int emptyChance,
  }) : groups = [
          LootGroup.single(LootItem(
              name: name,
              quantityWeights:
                  QuantityWeights.single(count, emptyChance: emptyChance),
              isBonus: isBonus))
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
  }) : groups = [system.group(group)];

  LootListing.fluid({
    required String name,
    required int count,
    required int emptyChance,
  }) : groups = [
          LootGroup.single(LootItem(
              name: name,
              quantityWeights:
                  QuantityWeights.single(count, emptyChance: emptyChance),
              isBonus: false))
        ];
}

class LootBatch {
  final String name;
  final LootOrigin origin;
  final List<LootListing> listings;

  LootBatch(this.name, this.origin, this.listings);

  Map<String, dynamic> toJson() {
    return {
      'origin': origin.toString().split('.').last,
      'listings': listings
          .map((e) => e.groups.map((e) => e.toJson()).toList())
          .toList(),
    };
  }
}
