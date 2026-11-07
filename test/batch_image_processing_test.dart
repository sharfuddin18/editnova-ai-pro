import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:editnova/utils/batch_image_processing.dart';

void main() {
  test('batch resize preserves aspect ratio and does not upscale', () {
    final source = image.Image(width: 4, height: 2);
    final sourceBytes = Uint8List.fromList(image.encodePng(source));

    final resizedBytes = resizeAndEncodeImage(
      BatchImageRequest(bytes: sourceBytes, maxDimension: 2, format: 'PNG'),
    );
    final resized = image.decodeImage(resizedBytes)!;

    expect(resized.width, 2);
    expect(resized.height, 1);

    final unchangedBytes = resizeAndEncodeImage(
      BatchImageRequest(bytes: sourceBytes, maxDimension: 8, format: 'PNG'),
    );
    final unchanged = image.decodeImage(unchangedBytes)!;
    expect(unchanged.width, 4);
    expect(unchanged.height, 2);
  });

  test('batch processing can encode JPEG output', () {
    final source = image.Image(width: 2, height: 2);
    final result = resizeAndEncodeImage(
      BatchImageRequest(
        bytes: Uint8List.fromList(image.encodePng(source)),
        maxDimension: 2,
        format: 'JPEG',
      ),
    );

    expect(image.decodeJpg(result), isNotNull);
  });
}
