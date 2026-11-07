import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:typed_data';

import '../utils/background_color_removal.dart';

class BackgroundRemoverPage extends StatefulWidget {
  const BackgroundRemoverPage({super.key});

  @override
  State<BackgroundRemoverPage> createState() => _BackgroundRemoverPageState();
}

class _BackgroundRemoverPageState extends State<BackgroundRemoverPage> {
  Uint8List? _originalBytes;
  Uint8List? _processedBytes;
  String _fileName = 'image';
  double _threshold = 48;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final selected = await _picker.pickImage(source: ImageSource.gallery);
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      setState(() {
        _originalBytes = bytes;
        _processedBytes = null;
        _fileName = selected.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open image: $error')));
    }
  }

  Future<void> _processImage() async {
    final bytes = _originalBytes;
    if (bytes == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final result = await compute(
        removeSolidBackground,
        BackgroundRemovalRequest(bytes: bytes, threshold: _threshold.round()),
      );
      if (!mounted) return;
      setState(() => _processedBytes = result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to remove flat background: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveImage() async {
    final bytes = _processedBytes;
    if (bytes == null) return;
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save transparent PNG',
        fileName: '${_fileName}_transparent.png',
        bytes: bytes,
      );
      if (!mounted || (path == null && !kIsWeb)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? 'PNG export started.' : 'Image saved to $path',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save image: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flat Background Remover'),
        actions: [
          IconButton(
            tooltip: 'Save transparent PNG',
            icon: const Icon(Icons.download),
            onPressed: _processedBytes == null ? null : _saveImage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Removes edge-connected pixels similar to the four corner colors. Works best on flat backgrounds; it is not AI subject segmentation.',
            ),
            const SizedBox(height: 16),
            _imagePreview('Original', _originalBytes),
            const SizedBox(height: 12),
            _imagePreview('Transparent result', _processedBytes),
            const SizedBox(height: 16),
            Text('Color tolerance: ${_threshold.round()}'),
            Slider(
              value: _threshold,
              min: 0,
              max: 180,
              divisions: 36,
              onChanged: _originalBytes == null || _isProcessing
                  ? null
                  : (value) => setState(() {
                      _threshold = value;
                      _processedBytes = null;
                    }),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Select image'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _originalBytes == null || _isProcessing
                        ? null
                        : _processImage,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.layers_clear),
                    label: Text(
                      _isProcessing
                          ? 'Processing...'
                          : 'Remove flat background',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview(String title, Uint8List? bytes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: bytes == null
              ? const Text('Select an image to preview')
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
        ),
      ],
    );
  }
}
