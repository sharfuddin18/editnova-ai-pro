import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:editnova/utils/background_color_removal.dart';

void main() {
  test('removes edge-connected solid color and preserves the subject', () {
    final source = image.Image(width: 3, height: 3);
    image.fill(source, color: image.ColorRgb8(240, 20, 20));
    source.setPixelRgb(1, 1, 20, 40, 220);
    final input = Uint8List.fromList(image.encodePng(source));

    final output = removeSolidBackground(
      BackgroundRemovalRequest(bytes: input, threshold: 24),
    );
    final result = image.decodeImage(output)!;

    expect(result.getPixel(0, 0).a, 0);
    expect(result.getPixel(1, 1).a, 255);
  });
}
