import 'dart:math';

import 'package:flutter/material.dart';

import 'drawing.dart';
import 'geometry.dart';
import 'model.dart';
import 'sprite.dart';

abstract class Mob {
  Position location;
  Direction facingDirection = Direction.up;

  Mob({required this.location});

  Drawable get drawable;

  void draw(Drawing drawing) {
    drawing.add(this, drawable, location);
  }
}

abstract class Character extends Mob {
  int maxHealth;
  int currentHealth;

  Character({
    required super.location,
    required this.maxHealth,
    required this.currentHealth,
  });

  void applyHealthChange(GameState state, int delta) {
    currentHealth = max(min(currentHealth + delta, maxHealth), 0);
    if (currentHealth == 0) {
      didExhaustHealth(state);
    }
  }

  void didExhaustHealth(GameState state) {}
}

class Player extends Character {
  double lightRadius = 2.5;
  bool carryingBlock = false;

  Player.spawn(Position location)
      : super(location: location, maxHealth: 10, currentHealth: 10);

  int get missingHealth => maxHealth - currentHealth;

  @override
  Drawable get drawable {
    Drawable avatar = const SpriteDrawable(Sprites.ant);

    if (carryingBlock) {
      final block = TransformDrawable.rst(
        scale: 0.25,
        dx: 0.0,
        dy: -0.6,
        drawable: SolidDrawable(Colors.brown.shade600),
      );
      avatar = CompositeDrawable([avatar, block]);
    }

    return TransformDrawable.rst(
      rotation: facingDirection.rotation,
      drawable: avatar,
    );
  }
}

abstract class Brain {
  void update(GameState state);
}

abstract class GameAction {
  final Character character;

  const GameAction({required this.character});

  void execute(GameState state);
}

class MoveAction extends GameAction {
  final Direction direction;
  final Position destination;

  const MoveAction({
    required this.destination,
    required this.direction,
    required super.character,
  });

  @override
  void execute(GameState state) {
    character.facingDirection = direction;
    if (state.world.isPassable(destination)) {
      character.location = destination;
    }
  }
}
