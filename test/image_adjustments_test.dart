import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:editnova/utils/image_adjustments.dart';

void main() {
  test('brightness adjustment changes the encoded image pixels', () {
    final source = image.Image(width: 1, height: 1);
    source.setPixelRgb(0, 0, 40, 80, 120);
    final sourceBytes = Uint8List.fromList(image.encodePng(source));

    final adjustedBytes = adjustImageBytes(
      ImageAdjustmentRequest(
        bytes: sourceBytes,
        brightness: 1.5,
        contrast: 1,
        saturation: 1,
      ),
    );

    final originalPixel = image.decodeImage(sourceBytes)!.getPixel(0, 0);
    final adjustedPixel = image.decodeImage(adjustedBytes)!.getPixel(0, 0);
    expect(adjustedPixel.r, greaterThan(originalPixel.r));
  });
}
