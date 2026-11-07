import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;

class BatchImageRequest {
  const BatchImageRequest({
    required this.bytes,
    required this.maxDimension,
    required this.format,
  });

  final Uint8List bytes;
  final int maxDimension;
  final String format;
}

Uint8List resizeAndEncodeImage(BatchImageRequest request) {
  if (request.maxDimension < 1) {
    throw ArgumentError.value(request.maxDimension, 'maxDimension');
  }
  if (request.format != 'PNG' && request.format != 'JPEG') {
    throw ArgumentError.value(request.format, 'format');
  }

  final source = image.decodeImage(request.bytes);
  if (source == null) {
    throw const FormatException('The selected file is not a supported image.');
  }

  final longestSide = math.max(source.width, source.height);
  final scale = math.min(1.0, request.maxDimension / longestSide);
  final resized = scale == 1
      ? source
      : image.copyResize(
          source,
          width: math.max(1, (source.width * scale).round()),
          height: math.max(1, (source.height * scale).round()),
          interpolation: image.Interpolation.average,
        );

  return Uint8List.fromList(
    request.format == 'PNG'
        ? image.encodePng(resized)
        : image.encodeJpg(resized, quality: 90),
  );
}
