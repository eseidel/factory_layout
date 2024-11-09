import 'dart:ui';

import 'package:flutter/material.dart' hide TextStyle;

abstract class Sprite {
  const Sprite();

  void paint(Canvas canvas, Rect rect);
}

@immutable
class IconSprite extends Sprite {
  final IconData data;
  final Color? color;

  const IconSprite(this.data, {this.color});

  IconSprite copyWith({
    Color? color,
  }) {
    return IconSprite(
      data,
      color: color ?? this.color,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect) {
    final builder = ParagraphBuilder(
      ParagraphStyle(
        fontFamily: data.fontFamily,
        fontSize: rect.shortestSide * 0.8,
      ),
    );
    if (color != null) {
      builder.pushStyle(TextStyle(color: color));
    }
    builder.addText(String.fromCharCode(data.codePoint));
    final paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    final iconSize = Size(paragraph.maxIntrinsicWidth, paragraph.height);
    final iconRect = Alignment.center.inscribe(iconSize, rect);
    canvas.drawParagraph(paragraph, iconRect.topLeft);
  }
}

class Sprites {
  Sprites._();

  static const IconSprite heart = IconSprite(IconData(0x1F49C));
  static const IconSprite flutterDash = IconSprite(Icons.flutter_dash);
  static const IconSprite ant = IconSprite(IconData(0x1F41C));
}
