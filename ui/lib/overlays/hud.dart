import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../ember_quest.dart';

class Hud extends PositionComponent with HasGameReference<EmberQuestGame> {
  Hud({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority = 5,
  });

  late TextComponent _scoreTextComponent;

  @override
  Future<void>? onLoad() async {
    _scoreTextComponent = TextComponent(
      text: '${game.starsCollected}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Color.fromRGBO(10, 10, 10, 1),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(game.size.x - 60, 20),
    );
    add(_scoreTextComponent);

    final starSprite = await game.loadSprite('star.png');
    add(
      SpriteComponent(
        sprite: starSprite,
        position: Vector2(game.size.x - 100, 20),
        size: Vector2.all(32),
        anchor: Anchor.center,
      ),
    );

    return super.onLoad();
  }

  @override
  void update(double dt) {
    _scoreTextComponent.text = '${game.starsCollected}';
    super.update(dt);
  }
}
