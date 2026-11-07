import 'dart:typed_data';

import 'package:image/image.dart' as image;

class BackgroundRemovalRequest {
  const BackgroundRemovalRequest({
    required this.bytes,
    required this.threshold,
  });

  final Uint8List bytes;
  final int threshold;
}

Uint8List removeSolidBackground(BackgroundRemovalRequest request) {
  if (request.threshold < 0 || request.threshold > 255) {
    throw ArgumentError.value(request.threshold, 'threshold');
  }

  final source = image.decodeImage(request.bytes);
  if (source == null) {
    throw const FormatException('The selected file is not a supported image.');
  }

  final width = source.width;
  final height = source.height;
  final pixelCount = width * height;
  if (pixelCount > 25000000) {
    throw ArgumentError('Image exceeds the 25 megapixel processing limit.');
  }

  final cornerPixels = [
    source.getPixel(0, 0),
    source.getPixel(width - 1, 0),
    source.getPixel(0, height - 1),
    source.getPixel(width - 1, height - 1),
  ];
  final backgroundRed =
      cornerPixels.map((pixel) => pixel.r.toInt()).reduce((a, b) => a + b) ~/
      cornerPixels.length;
  final backgroundGreen =
      cornerPixels.map((pixel) => pixel.g.toInt()).reduce((a, b) => a + b) ~/
      cornerPixels.length;
  final backgroundBlue =
      cornerPixels.map((pixel) => pixel.b.toInt()).reduce((a, b) => a + b) ~/
      cornerPixels.length;
  final thresholdSquared = request.threshold * request.threshold;
  final removed = Uint8List(pixelCount);
  final queue = Int32List(pixelCount);
  var readIndex = 0;
  var writeIndex = 0;

  bool isBackground(int x, int y) {
    final pixel = source.getPixel(x, y);
    final redDelta = pixel.r.toInt() - backgroundRed;
    final greenDelta = pixel.g.toInt() - backgroundGreen;
    final blueDelta = pixel.b.toInt() - backgroundBlue;
    return redDelta * redDelta +
            greenDelta * greenDelta +
            blueDelta * blueDelta <=
        thresholdSquared;
  }

  void enqueue(int x, int y) {
    final index = y * width + x;
    if (removed[index] != 0 || !isBackground(x, y)) return;
    removed[index] = 1;
    queue[writeIndex++] = index;
  }

  for (var x = 0; x < width; x++) {
    enqueue(x, 0);
    if (height > 1) enqueue(x, height - 1);
  }
  for (var y = 1; y < height - 1; y++) {
    enqueue(0, y);
    if (width > 1) enqueue(width - 1, y);
  }

  while (readIndex < writeIndex) {
    final index = queue[readIndex++];
    final x = index % width;
    final y = index ~/ width;
    if (x > 0) enqueue(x - 1, y);
    if (x + 1 < width) enqueue(x + 1, y);
    if (y > 0) enqueue(x, y - 1);
    if (y + 1 < height) enqueue(x, y + 1);
  }

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = source.getPixel(x, y);
      source.setPixelRgba(
        x,
        y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        removed[y * width + x] == 1 ? 0 : pixel.a.toInt(),
      );
    }
  }

  return Uint8List.fromList(image.encodePng(source));
}
