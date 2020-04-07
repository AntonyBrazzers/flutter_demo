import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutteraquarium/sprite_kit.dart';

class Gameplay {
  static const countSmall = 3;
  static const countMiddle = 3;
  static const countBig = 3;
  static const countMammals = 1;
  static const int interval = 1000;
  static const _timeCheck = 15;
  var _counter = 0;
  Timer _subscription;

  int screenWidth = 360;
  int screenHeight = 640;

  void setScreenSize(int width, int height) {
    screenWidth = width;
    screenHeight = height;
  }

  void init(BuildContext context) {
    MediaQueryData params = MediaQuery.of(context);
    setScreenSize(params.size.width.toInt(), params.size.height.toInt());
  }

  void begin(block) {
    _subscription =
        new Timer.periodic(const Duration(milliseconds: interval), (v) {
      ++_counter;
      if (_counter == _timeCheck) {
        block();
        _counter = 0;
      }
    });
  }

  void end() {
    _subscription.cancel();
  }

  List<FishMovableSprite> initFishes() {
    final result = [
      getFish(FishType.predators, FishSize.small),
      getFish(FishType.predators, FishSize.small),
      getFish(FishType.predators, FishSize.small),
      getFish(FishType.predators, FishSize.middle),
      getFish(FishType.predators, FishSize.middle),
      getFish(FishType.predators, FishSize.middle),
      getFish(FishType.predators, FishSize.big),
      getFish(FishType.predators, FishSize.big),
      getFish(FishType.predators, FishSize.big),
      getFish(FishType.mammals, FishSize.small),
      getFish(FishType.mammals, FishSize.middle),
      getFish(FishType.mammals, FishSize.big),
    ];
    return result;
  }

  FishMovableSprite getFish(FishType type, FishSize size) => FishMovableSprite(
      Point.random(screenWidth, screenHeight), Fish(type, size));

  void controlSprites(SpriteKitWidget spriteKitWidget) {
    _controlCountFish(spriteKitWidget, FishType.predators, FishSize.small);
    _controlCountFish(spriteKitWidget, FishType.predators, FishSize.middle);
    _controlCountFish(spriteKitWidget, FishType.predators, FishSize.big);
    _controlCountFish(spriteKitWidget, FishType.mammals, FishSize.small);
    _controlCountFish(spriteKitWidget, FishType.mammals, FishSize.middle);
    _controlCountFish(spriteKitWidget, FishType.mammals, FishSize.big);
  }

  void _controlCountFish(
      SpriteKitWidget spriteKitWidget, FishType type, FishSize size) {
    final list = spriteKitWidget.getSprites();
    final count = _countFishes(list, type, size);
    var maxCount = countSmall;
    if (type == FishType.predators) {
      if (size == FishSize.middle) maxCount = countMiddle;
      if (size == FishSize.big) maxCount = countBig;
    } else {
      maxCount = countMammals;
    }
    final diff = maxCount - count;
    for (var i = 0; i < diff; ++i) {
      spriteKitWidget.add(getFish(type, size));
    }
  }

  int _countFishes(List<Sprite> source, FishType type, FishSize size) {
    int result = 0;
    source.forEach((it) {
      if (it is FishMovableSprite &&
          it.isVisible &&
          it.fish.type == type &&
          it.fish.size == size) {
        ++result;
      }
    });
    return result;
  }

  void eating(List<Collision> list) {
    list.forEach((it) {
      if (it.first is FishMovableSprite && it.second is FishMovableSprite) {
        final spriteFish1 = it.first as FishMovableSprite;
        final spriteFish2 = it.second as FishMovableSprite;
        _predatorVsMammals(spriteFish1, spriteFish2);
        _predatorVsMammals(spriteFish2, spriteFish1);
        _predatorVsPredator(spriteFish1, spriteFish2);
        _predatorVsPredator(spriteFish2, spriteFish1);
      }
    });
  }

  _predatorVsMammals(
      FishMovableSprite spriteFish1, FishMovableSprite spriteFish2) {
    if (spriteFish1.isVisible && spriteFish2.isVisible) {
      final fish1 = spriteFish1.fish;
      final fish2 = spriteFish2.fish;
      if (fish1.isPredator() && fish2.isMammals()) {
        if (fish1.isBig()) {
          spriteFish2.isVisible = false;
        } else if (fish1.isMiddle()) {
          spriteFish2.isVisible = false;
        } else if (fish1.isSmall()) {
          if (!fish2.isBig()) {
            spriteFish2.isVisible = false;
          }
        }
      }
    }
  }

  _predatorVsPredator(
      FishMovableSprite spriteFish1, FishMovableSprite spriteFish2) {
    if (spriteFish1.isVisible && spriteFish2.isVisible) {
      final fish1 = spriteFish1.fish;
      final fish2 = spriteFish2.fish;
      if (fish1.isPredator() && fish2.isPredator()) {
        if (fish1.isBig()) {
          spriteFish2.isVisible = false;
        } else if (fish1.isMiddle()) {
          if (!fish2.isBig()) {
            spriteFish2.isVisible = false;
          }
        } else if (fish1.isSmall()) {
          if (fish2.isSmall()) {
            spriteFish2.isVisible = false;
          }
        }
      }
    }
  }
}

class Fish {
  FishType type;
  FishSize size;

  Fish(this.type, this.size);

  bool isPredator() => type == FishType.predators;

  bool isMammals() => type == FishType.mammals;

  bool isSmall() => size == FishSize.small;

  bool isMiddle() => size == FishSize.middle;

  bool isBig() => size == FishSize.big;

  int getRadius() {
    var radius = 10;
    if (isMiddle()) radius = 20;
    if (isBig()) radius = 30;
    return radius;
  }

  Color getColor() {
    var color = Colors.grey;
    if (isPredator()) {
      if (isSmall()) color = Colors.yellow;
      if (isMiddle()) color = Colors.orange;
      if (isBig()) color = Colors.red;
    } else if (isMammals()) {
      if (isSmall()) color = Colors.blue;
      if (isMiddle()) color = Colors.green;
      if (isBig()) color = Colors.lightGreen;
    }
    return color;
  }

  SpriteVelocity getVelocity() {
    var result = SpriteVelocity(6 * randomSign(), 6 * randomSign());
    if (isMiddle()) result = SpriteVelocity(4 * randomSign(), 4 * randomSign());
    if (isBig()) result = SpriteVelocity(2 * randomSign(), 2 * randomSign());
    return result;
  }

  double randomSign() {
    int result = 1;
    if (random(0, 1) == 0) result = -1;
    return result.toDouble();
  }
}

enum FishType { mammals, predators }

enum FishSize { small, middle, big }

class FishMovableSprite extends MovableSprite {
  FishMovableSprite(Point position, Fish fish)
      : super("id-test", position, SpriteSize(0, 0)) {
    this.fish = fish;
    _color = fish.getColor();
    _radius = fish.getRadius();
    size = SpriteSize(_radius * 2, _radius * 2);
    final v = fish.getVelocity();
    setVelocity(v.x, v.y);
  }

  Fish fish;
  Color _color;
  int _radius;

  @override
  void onDraw(Canvas canvas, Size size) {
    super.onDraw(canvas, size);
    paint.color = _color;
    final r = 5 * _radius/3;
    final left = position.x + r / 4;
    final top = position.y + r / 4;
    canvas.drawOval(Rect.fromLTWH(left, top, r.toDouble(), 3 * r / 4), paint);

    var paintLine = Paint()
      ..style = PaintingStyle.fill
      ..color = _color
      ..strokeWidth = 5
      ..isAntiAlias = true;

    final offsetTop = Offset(position.x - 5, position.y + r / 3);
    final offsetMiddle = Offset(left, position.y + 2 * r / 3);
    final offsetBottom = Offset(position.x - 5, position.y + 10 * r / 9);
    canvas.drawLine(offsetTop, offsetMiddle, paintLine);
    canvas.drawLine(offsetBottom, offsetMiddle, paintLine);
  }
}
