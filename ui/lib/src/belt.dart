import 'package:collection/collection.dart';

import 'world.dart';

class ItemOffset {
  final ItemType item;
  // Offset is the distance to the item after this in the belt segment
  // or the end of the segment if there is no item after this.
  double offset;

  ItemOffset(this.item, this.offset);
}

int kMinimumSpaceBetweenItems = 1;
double kBeltSpeed = 0.1;

class BeltSegment {
  // List of Cells that make up this segment.
  final List<PlacedItem> belts;
  // Item offsets are measured from the end of the belt segment.
  // The first item in the list is the item closest to the end of the segment.
  final List<ItemOffset> items = [];

  BeltSegment(this.belts);

  /// Returns th offset from the end of the segment to the first item
  /// relative to the start of the segment.
  double? get offsetOfFirstItem {
    if (items.isEmpty) {
      return null;
    }
    final distanceFromEnd = items.map((item) => item.offset).sum;
    assert(distanceFromEnd <= belts.length);
    return belts.length - distanceFromEnd;
  }

  // Because belts are exactly 1x1, the length of the segment is the same as the
  // length of the belts.
  double get length => belts.length.toDouble();

  void addItemToStart(ItemType item) {
    final spaceToFirstItem = offsetOfFirstItem ?? length;
    if (spaceToFirstItem < kMinimumSpaceBetweenItems) {
      throw ArgumentError('Not enough space to add item to start of segment');
    }
    items.add(ItemOffset(item, spaceToFirstItem));
  }

  bool get hasSpaceAtStart {
    return (offsetOfFirstItem ?? length) >= kMinimumSpaceBetweenItems;
  }

  void addBeltToStart(PlacedItem belt) {
    print('Adding belt to start of segment');
    assert(belt.isBelt);
    belts.insert(0, belt);
    // No offsets should need to be updated.
  }

  void addBeltToEnd(PlacedItem belt) {
    print('Adding belt to end of segment');
    assert(belt.isBelt);
    belts.add(belt);
    // If there is a first item, update its offset.
    if (items.isNotEmpty) {
      items.first.offset += 1;
    }
  }

  void update(double elapsed) {
    var deltaLeft = elapsed * kBeltSpeed;
    while (deltaLeft > 0) {
      if (items.isEmpty) {
        break;
      }
      final item = items.first;
      final delta = deltaLeft.clamp(0, item.offset);
      item.offset -= delta;
      deltaLeft -= delta;
      if (item.offset <= 0) {
        items.removeAt(0);
      }
    }
  }
}
