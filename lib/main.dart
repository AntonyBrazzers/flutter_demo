import 'package:flutter/material.dart';
import 'package:flutteraquarium/sprite_kit.dart';

import 'gameplay.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Aquarium'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _drawManager = DrawManager();
  final _spriteKitWidget = SpriteKitWidget();
  final _gameplay = Gameplay();

  @override
  void initState() {
    super.initState();
    _spriteKitWidget.addAll(_gameplay.initFishes());
    _spriteKitWidget.onCollisions = (list) {
      _gameplay.eating(list);
      return null;
    };
    _drawManager.begin(() {
      setState(() {
        _spriteKitWidget.onUpdate();
      });
    });
    _gameplay.begin(() {
      _gameplay.controlSprites(_spriteKitWidget);
    });
  }

  @override
  Widget build(BuildContext context) {
    _gameplay.init(context);
    _spriteKitWidget.init(context);
    return Scaffold(
      body: CustomPaint(painter: SpiteKitPainter(_spriteKitWidget)),
    );
  }

  @override
  void dispose() {
    _gameplay.end();
    _spriteKitWidget.onDestroy();
    _drawManager.end();
    super.dispose();
  }
}
