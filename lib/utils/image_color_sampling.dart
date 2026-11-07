import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;

class ImageColorSampleRequest {
  const ImageColorSampleRequest({
    required this.bytes,
    required this.displayX,
    required this.displayY,
    required this.displayWidth,
    required this.displayHeight,
  });

  final Uint8List bytes;
  final double displayX;
  final double displayY;
  final double displayWidth;
  final double displayHeight;
}

int sampleImageColor(ImageColorSampleRequest request) {
  final decoded = image.decodeImage(request.bytes);
  if (decoded == null) {
    throw const FormatException('The selected file is not a supported image.');
  }
  if (request.displayWidth <= 0 || request.displayHeight <= 0) {
    throw ArgumentError('Display dimensions must be positive.');
  }

  final scale = math.min(
    request.displayWidth / decoded.width,
    request.displayHeight / decoded.height,
  );
  final renderedWidth = decoded.width * scale;
  final renderedHeight = decoded.height * scale;
  final left = (request.displayWidth - renderedWidth) / 2;
  final top = (request.displayHeight - renderedHeight) / 2;
  final imageX = request.displayX - left;
  final imageY = request.displayY - top;
  if (imageX < 0 ||
      imageY < 0 ||
      imageX >= renderedWidth ||
      imageY >= renderedHeight) {
    throw RangeError('Tap is outside the visible image.');
  }

  final x = (imageX / scale).floor().clamp(0, decoded.width - 1);
  final y = (imageY / scale).floor().clamp(0, decoded.height - 1);
  final pixel = decoded.getPixel(x, y);
  return (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
}
