import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

abstract class Drawable {
  void onStart();

  void onUpdate();

  void onDraw(Canvas canvas, Size size);

  void onDestroy();
}

class SpiteKitPainter extends CustomPainter {
  SpriteKitWidget spriteKitWidget;

  SpiteKitPainter(this.spriteKitWidget);

  @override
  void paint(Canvas canvas, Size size) {
    spriteKitWidget.onDraw(canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class SpriteKitWidget {
  Scene _scene;
  List<Sprite> _sprites = [];
  bool isInit = false;

  var onCollisions = (List<Collision> it) => (it) {  };

  SpriteKitWidget();

  void init(BuildContext context) {
    MediaQueryData params = MediaQuery.of(context);
    _scene = Scene(params.size.width, params.size.height, Colors.grey);
    isInit = true;
  }

  void onUpdate() {
    if (!isInit) return;

    _scene.onUpdate();
    _sprites.forEach((it) {
      it.onUpdate();
    });
  }

  void onDestroy() {
    _sprites.forEach((it) {
      it.onDestroy();
    });
    clear();
  }

  List<Sprite> getSprites() => _sprites;

  void addAll(List<Sprite> sprites) {
    _sprites.addAll(sprites);
    sortByLayer();
  }

  void add(Sprite it) {
    _sprites.add(it);
    sortByLayer();
  }

  void remove(String id) {
    _sprites.removeWhere((it) => it.id == id);
  }

  void clear() {
    _sprites.clear();
  }

  void sortByLayer() {
    _sprites.sort((first, second) {
      if (first.layer < second.layer)
        return -1;
      else if (first.layer > second.layer)
        return 1;
      else
        return 0;
    });
  }

  void _checkCollisions() {
    final List<Collision> result = [];
    for (var i = 0; i < _sprites.length - 1; ++i) {
      final first = _sprites[i];
      if (!first.isVisible) continue;

      for (var j = i + 1; j < _sprites.length; ++j) {
        final second = _sprites[j];
        if (!second.isVisible) continue;

        final distanceBetweenCenters =
            first.getCenter().distance(second.getCenter());
        final sumMaxDistances =
            first.size.maxDistance() + second.size.maxDistance();
        if (distanceBetweenCenters < sumMaxDistances) {
          result.add(Collision(first, second));
        }
      }
    }
    onCollisions(result);
  }

  void onDraw(Canvas canvas, Size size) {
    if (!isInit) return;

    canvas.save();
    _scene.onDraw(canvas, size);
    _sprites.where((it) => it.isVisible).forEach((it) {
      Size sizeByScene =
          Size(_scene._width.toDouble(), _scene._height.toDouble());
      _checkCollisions();
      it.onDraw(canvas, sizeByScene);
    });
    canvas.restore();
  }
}

class Scene extends Drawable {
  double _width;
  double _height;
  Texture texture;
  Color color = Colors.white;

  var _paint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Scene(this._width, this._height, this.color);

  Scene.withTexture(this._width, this._height, this.texture);

  @override
  void onStart() {}

  @override
  void onDestroy() {}

  @override
  void onDraw(Canvas canvas, Size size) {
    if (texture != null) {
      canvas.drawImage(texture.frame(), Offset.zero, Paint());
    } else {
      _paint.color = color;
      canvas.drawPaint(_paint);
    }
  }

  @override
  void onUpdate() {}
}

class Sprite extends Drawable {
  String id;
  Point position;
  Texture texture;
  SpriteSize size;
  int layer;
  bool isVisible = true;

  var paint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Sprite(this.id, this.position, this.size, this.layer);

  @override
  void onStart() {}

  @override
  void onUpdate() {}

  @override
  void onDraw(Canvas canvas, Size size) {}

  @override
  void onDestroy() {}

  Point getCenter() {
    double x = position.x + size.width / 2;
    double y = position.y + size.height / 2;
    return Point(x, y);
  }
}

class MovableSprite extends Sprite {
  MovableSprite(String id, Point position, SpriteSize size)
      : super(id, position, size, 1);

  SpriteVelocity _velocity = SpriteVelocity(5, 5);
  Constraint _constraint;
  bool isVelocityChangable = true;

  @override
  void onUpdate() {
    _move();
  }

  @override
  void onDraw(Canvas canvas, Size size) {
    _checkConstraints(size);
  }

  void setVelocity(double x, double y) {
    _velocity = SpriteVelocity(x, y);
  }

  _checkConstraints(Size size) {
    if (_constraint == null) {
      _constraint = Constraint(size.width.toInt(), size.height.toInt());
    } else if (_constraint.width > size.width) {
      _constraint.width = size.width.toInt();
    } else if (_constraint.height > size.height) {
      _constraint.height = size.height.toInt();
    }
  }

  _move() {
    position.changeBy(_velocity);
    if (_constraint != null) {
      _constraint.process(position);
    }
    _changeVelocity();
  }

  _changeVelocity() {
    if (_constraint != null) {
      bool hasConstraintX = position.x <= 0 || position.x >= _constraint.width;
      bool hasConstraintY = position.y <= 0 || position.y >= _constraint.height;
      if (hasConstraintX || hasConstraintY) {
        if (isVelocityChangable) {
          _velocity.constraint(10, 5);
          _velocity.randomChange();
        } else {
          _velocity.changeDirection();
        }
      }
    }
  }
}

class Texture {
  List<ui.Image> _atlas = [];

  Texture.static(ui.Image it) {
    _atlas = [];
    _atlas.add(it);
  }

  Texture(this._atlas);

  ui.Image frame() => frameBy(0);

  ui.Image frameBy(int index) {
    ui.Image result;
    bool isTextureExists = _atlas != null && _atlas.length > 0;
    bool isFrameAvailable =
        _atlas != null && index < _atlas.length && index >= 0;
    if (isTextureExists && isFrameAvailable) {
      result = _atlas[index];
    }
    return result;
  }
}

class Point {
  double x;
  double y;

  Point(this.x, this.y);

  Point.random(int maxWidth, int maxHeight) {
    x = random(0, maxWidth).toDouble();
    y = random(0, maxHeight).toDouble();
  }

  void changeBy(SpriteVelocity velocity) {
    x += velocity.x;
    y += velocity.y;
  }

  double distance(Point to) {
    final dx = to.x - x;
    final dy = to.y - y;
    return sqrt(dx * dx + dy * dy);
  }
}

class SpriteVelocity {
  double x;
  double y;
  double len;

  SpriteVelocity(this.x, this.y) {
    len = sqrt(x * x + y * y);
  }

  changeDirection() {
    //todo
  }

  randomChange() {
    double kx = -0.25 * random(1, 3);
    double ky = -0.25 * random(1, 3);
    double bx = 0.5 * random(-2, 2);
    double by = 0.5 * random(-2, 2);
    x = kx * x + bx;
    y = ky * y + by;
  }

  constraint(int max, double reset) {
    int signX = 1;
    if (x < 0) signX = -1;
    int signY = 1;
    if (y < 0) signY = -1;
    if (x.abs() >= max) x = reset * signX;
    if (y.abs() >= max) y = reset * signY;
  }
}

class Constraint {
  int width;
  int height;

  Constraint(this.width, this.height);

  Constraint.byContext(BuildContext context) {
    MediaQueryData params = MediaQuery.of(context);
    width = params.size.width.toInt();
    height = params.size.height.toInt();
  }

  Constraint.bySpriteKitWidget(SpriteKitWidget spriteKitWidget) {
    width = spriteKitWidget._scene._width.toInt();
    height = spriteKitWidget._scene._height.toInt();
  }

  void process(Point p) {
    if (p.x <= 0) p.x = 0;
    if (p.x > width) p.x = width.toDouble();
    if (p.y <= 0) p.y = 0;
    if (p.y > height) p.y = height.toDouble();
  }
}

class SpriteSize {
  int width;
  int height;

  SpriteSize(this.width, this.height);

  double maxDistance() => sqrt(width * width / 4 + height * height / 4);
}

class Collision {
  Sprite first;
  Sprite second;

  Collision(this.first, this.second);
}

class DrawManager {
  static const int interval = 50;
  Timer _subscription;

  void begin(block) {
    _subscription = new Timer.periodic(
        const Duration(milliseconds: interval), (v) => block());
  }

  void end() {
    _subscription.cancel();
  }
}

int random(int min, int max) {
  final _random = Random();
  return min + _random.nextInt(max - min);
}

double randomDouble(double min, double max) =>
    random(min.toInt(), max.toInt()).toDouble();
