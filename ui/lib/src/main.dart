import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'geometry.dart';
import 'view.dart';
import 'world.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Factory',
      theme: ThemeData.dark(),
      home: const GamePage(),
    );
  }
}

class ItemSelector extends StatelessWidget {
  final List<ItemType> items;
  final ValueChanged<ItemType> onItemSelected;
  final ItemType selectedItem;
  final Direction selectedDirection;

  const ItemSelector({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.selectedItem,
    required this.selectedDirection,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final cell = PlacedItem(
          location: Position.zero,
          type: item,
          facingDirection: selectedDirection,
        );
        var button = Container(
          color: item.color,
          child: Center(
            child: Text(
              cell.toCharRepresentation(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
        if (item == selectedItem) {
          button = Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: button,
          );
        }
        return GestureDetector(
          onTap: () => onItemSelected(item),
          child: button,
        );
      },
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with TickerProviderStateMixin<GamePage> {
  final focusNode = FocusNode();
  late GameController controller;
  final gameKey = GlobalKey();

  ItemType selectedItem = ItemType.wall;
  Direction selectedDirection = Direction.up;

  @override
  void initState() {
    super.initState();
    controller = GameController(this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blueGrey,
      child: Center(
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: KeyboardListener(
                autofocus: true,
                focusNode: focusNode,
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.keyR) {
                    setState(() {
                      selectedDirection = selectedDirection.rotateRight();
                    });
                    return;
                  }

                  if (event is KeyDownEvent || event is KeyRepeatEvent) {
                    controller.handleKeyEvent(event);
                  }
                },
                child: Listener(
                  onPointerDown: (event) {
                    focusNode.requestFocus();
                    final renderBox =
                        gameKey.currentContext!.findRenderObject() as RenderBox;
                    final size = renderBox.size;
                    final worldPosition =
                        controller.hitTest(event.localPosition, size);
                    controller.placeItem(
                      position: worldPosition,
                      itemType: selectedItem,
                      direction: selectedDirection,
                    );
                  },
                  child: GameView(
                    key: gameKey,
                    controller: controller,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ItemSelector(
                items: ItemType.values,
                onItemSelected: (item) {
                  setState(() {
                    selectedItem = item;
                  });
                },
                selectedItem: selectedItem,
                selectedDirection: selectedDirection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
