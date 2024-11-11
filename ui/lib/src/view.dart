import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'geometry.dart';
import 'model.dart';
import 'world.dart';

class GameController extends ChangeNotifier {
  GameState state = GameState();

  LogicalEvent? _logicalEventFor(KeyEvent event) {
    if (state.playerDead) {
      return null;
    }
    bool isRepeat = event is KeyRepeatEvent;
    if (!isRepeat && event.logicalKey == LogicalKeyboardKey.space) {
      return LogicalEvent.interact();
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      return LogicalEvent.move(Direction.left);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      return LogicalEvent.move(Direction.right);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.keyW) {
      return LogicalEvent.move(Direction.up);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.keyS) {
      return LogicalEvent.move(Direction.down);
    }
    return null;
  }

  void handleKeyEvent(KeyEvent event) {
    var logical = _logicalEventFor(event);
    if (logical == null) {
      return;
    }
    var playerAction = state.actionFor(state.player, logical);
    if (playerAction != null) {
      playerAction.execute(state);
    }
  }

  void placeItem({
    required Position position,
    required ItemType itemType,
    Direction direction = Direction.up,
  }) {
    final item = PlacedItem(
        location: position, type: itemType, facingDirection: direction);
    state.world.placeItem(position, item);
  }

  void newGame() {
    state = GameState();
  }
}
