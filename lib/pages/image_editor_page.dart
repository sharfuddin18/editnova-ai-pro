import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import '../utils/image_adjustments.dart';

class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({super.key});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  Uint8List? _originalImageBytes;
  Uint8List? _previewImageBytes;
  final ImagePicker _picker = ImagePicker();
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  bool _isProcessing = false;
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _originalImageBytes = bytes;
        _previewImageBytes = bytes;
        _brightness = 0;
        _contrast = 0;
        _saturation = 0;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open image: $error')));
    }
  }

  Future<void> _applyAdjustments() async {
    final bytes = _originalImageBytes;
    if (bytes == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final preview = await compute(
        adjustImageBytes,
        ImageAdjustmentRequest(
          bytes: bytes,
          brightness: 1 + _brightness,
          contrast: 1 + _contrast,
          saturation: 1 + _saturation,
        ),
      );
      if (!mounted) return;
      setState(() => _previewImageBytes = preview);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to process image: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveImage() async {
    final bytes = _previewImageBytes;
    if (bytes == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save edited image',
        fileName: 'editnova-${DateTime.now().millisecondsSinceEpoch}.png',
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path != null
                ? 'Image saved to $path'
                : kIsWeb
                ? 'Image download started.'
                : 'Save canceled.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save image: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Editor'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Save edited image',
            onPressed:
                _previewImageBytes != null && !_isProcessing && !_isSaving
                ? _saveImage
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _previewImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _previewImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No image selected',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _showImageSourceDialog,
                            child: Text('Select Image'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Editing Tools',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 16),
                  _buildSlider('Brightness', _brightness, (value) {
                    setState(() => _brightness = value);
                  }),
                  _buildSlider('Contrast', _contrast, (value) {
                    setState(() => _contrast = value);
                  }),
                  _buildSlider('Saturation', _saturation, (value) {
                    setState(() => _saturation = value);
                  }),
                  if (_isProcessing) const LinearProgressIndicator(),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: Icon(Icons.add_photo_alternate),
                        label: Text('Add Image'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _originalImageBytes == null || _isProcessing
                            ? null
                            : _applyAdjustments,
                        icon: Icon(Icons.tune),
                        label: Text('Apply adjustments'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        Slider(
          value: value,
          min: -1.0,
          max: 1.0,
          divisions: 20,
          label: value.toStringAsFixed(1),
          onChanged: _isProcessing ? null : onChanged,
          onChangeEnd: _isProcessing ? null : (_) => _applyAdjustments(),
        ),
      ],
    );
  }
}
