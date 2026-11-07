import 'dart:typed_data';

import 'package:image/image.dart' as image;

class ImageAdjustmentRequest {
  const ImageAdjustmentRequest({
    required this.bytes,
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });

  final Uint8List bytes;
  final double brightness;
  final double contrast;
  final double saturation;
}

Uint8List adjustImageBytes(ImageAdjustmentRequest request) {
  final decoded = image.decodeImage(request.bytes);
  if (decoded == null) {
    throw const FormatException('The selected file is not a supported image.');
  }

  final adjusted = image.adjustColor(
    decoded,
    brightness: request.brightness,
    contrast: request.contrast,
    saturation: request.saturation,
  );
  return Uint8List.fromList(image.encodePng(adjusted));
}
