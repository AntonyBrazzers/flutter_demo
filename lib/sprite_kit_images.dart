
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as ui;

class ImageManager {
  Future<void> loadFromAsset(String path, block(ui.Image image)) async {
    ByteData imageBytes = await rootBundle.load(path);
    List<int> values = imageBytes.buffer.asUint8List();
    ui.Image image = ui.decodeImage(values);
    block(image);
  }
}