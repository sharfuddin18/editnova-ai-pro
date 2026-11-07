import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:editnova/utils/image_color_sampling.dart';

void main() {
  test('samples the correct pixel using contain-fit display coordinates', () {
    final source = image.Image(width: 2, height: 1);
    source.setPixelRgb(0, 0, 255, 0, 0);
    source.setPixelRgb(1, 0, 0, 255, 0);
    final bytes = Uint8List.fromList(image.encodePng(source));

    final sampled = sampleImageColor(
      ImageColorSampleRequest(
        bytes: bytes,
        displayX: 75,
        displayY: 50,
        displayWidth: 200,
        displayHeight: 100,
      ),
    );

    expect(sampled, 0x00FF00);
  });
}
