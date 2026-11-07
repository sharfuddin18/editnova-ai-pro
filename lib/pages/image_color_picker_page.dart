import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/image_color_sampling.dart';

class ImageColorPickerPage extends StatefulWidget {
  const ImageColorPickerPage({super.key});

  @override
  State<ImageColorPickerPage> createState() => _ImageColorPickerPageState();
}

class _ImageColorPickerPageState extends State<ImageColorPickerPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  int? _selectedRgb;
  bool _isSampling = false;

  Future<void> _selectImage() async {
    try {
      final selected = await _picker.pickImage(source: ImageSource.gallery);
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _selectedRgb = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open image: $error')));
    }
  }

  Future<void> _sampleColor(Offset position, Size displaySize) async {
    final bytes = _imageBytes;
    if (bytes == null || _isSampling) return;
    setState(() => _isSampling = true);
    try {
      final rgb = await compute(
        sampleImageColor,
        ImageColorSampleRequest(
          bytes: bytes,
          displayX: position.dx,
          displayY: position.dy,
          displayWidth: displaySize.width,
          displayHeight: displaySize.height,
        ),
      );
      if (mounted) setState(() => _selectedRgb = rgb);
    } on RangeError {
      // Ignore taps in the letterboxed area around the image.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to sample color: $error')));
    } finally {
      if (mounted) setState(() => _isSampling = false);
    }
  }

  Future<void> _copyHex() async {
    final rgb = _selectedRgb;
    if (rgb == null) return;
    final hex = '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    await Clipboard.setData(ClipboardData(text: hex));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Color copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final rgb = _selectedRgb;
    final color = rgb == null ? null : Color(0xFF000000 | rgb);
    final hex = rgb == null
        ? null
        : '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return Scaffold(
      appBar: AppBar(title: const Text('Image Color Picker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select an image, then tap it to sample an exact pixel color.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSampling ? null : _selectImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Select image'),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const height = 300.0;
              return GestureDetector(
                onTapDown: _imageBytes == null || _isSampling
                    ? null
                    : (details) => _sampleColor(
                        details.localPosition,
                        Size(constraints.maxWidth, height),
                      ),
                child: Container(
                  width: constraints.maxWidth,
                  height: height,
                  alignment: Alignment.center,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: _imageBytes == null
                      ? const Text('No image selected')
                      : Image.memory(
                          _imageBytes!,
                          width: constraints.maxWidth,
                          height: height,
                          fit: BoxFit.contain,
                        ),
                ),
              );
            },
          ),
          if (color != null && hex != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(backgroundColor: color),
                const SizedBox(width: 12),
                Expanded(child: SelectableText(hex)),
                IconButton(
                  tooltip: 'Copy hex color',
                  onPressed: _copyHex,
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ],
          if (kIsWeb && _imageBytes != null)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Image pixels are processed locally in your browser.',
              ),
            ),
        ],
      ),
    );
  }
}
