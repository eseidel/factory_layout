import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final List<CellType> items;
  final ValueChanged<CellType> onItemSelected;
  final CellType selectedItem;

  const ItemSelector({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.selectedItem,
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
        final cell = Cell(item);
        var button = Container(
          color: cell.color,
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

  Cell selectedItem = const Cell.wall();

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
                    controller.setCell(worldPosition, selectedItem);
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
                items: CellType.values,
                onItemSelected: (item) {
                  setState(() {
                    selectedItem = Cell(item);
                  });
                },
                selectedItem: selectedItem.type,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
