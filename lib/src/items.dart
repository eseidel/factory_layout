enum Category {
  natural,
  refined,
  ingredient,
  fuel,
  extraction,
}

// Factorio keeps name and stack size on an item.
// Auto Forge seems to keep stack size on a machine.
class Item {
  Item(this.name, this.category);

  final String name;
  final Category category;

  @override
  String toString() => name;
}

final ironOre = Item('Iron Ore', Category.natural);
final wood = Item('Wood', Category.natural);
final ironIngot = Item('Iron Ingot', Category.refined);
final bioMass = Item('Bio Mass', Category.fuel);
final ironGear = Item('Iron Gear', Category.ingredient);
final crank = Item('Crank', Category.ingredient);
final plank = Item('Plank', Category.ingredient);
final crankDrill = Item('Crank Drill', Category.extraction);
