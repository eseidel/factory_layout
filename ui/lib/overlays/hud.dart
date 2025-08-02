// import 'package:flame/components.dart';
// import 'package:flutter/material.dart';

// import '../ember_quest.dart';
// import 'heart.dart';

// class Hud extends PositionComponent with HasGameReference<FactoryGame> {
//   Hud({
//     super.position,
//     super.size,
//     super.scale,
//     super.angle,
//     super.anchor,
//     super.children,
//     super.priority = 5,
//   });

//   @override
//   Future<void> onLoad() async {
//     for (var i = 1; i <= game.health; i++) {
//       final positionX = 40 * i;
//       await add(
//         HeartHealthComponent(
//           heartNumber: i,
//           position: Vector2(positionX.toDouble(), 20),
//           size: Vector2.all(32),
//         ),
//       );
//     }
//   }

//   @override
//   void update(double dt) {
//     _scoreTextComponent.text = '${game.starsCollected}';
//   }
// }
