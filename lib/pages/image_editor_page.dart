import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({super.key});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  Color _filterColor = Colors.transparent;
  final List<List<double>> _history = [const [0.0, 0.0, 0.0]];
  int _historyIndex = 0;

  List<double> get _currentAdjustment => _history[_historyIndex];

  void _setAdjustment(int index, double value) {
    final next = List<double>.from(_currentAdjustment);
    next[index] = value;
    if (next[index] == _currentAdjustment[index]) return;
    setState(() {
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      _history.add(next);
      _historyIndex++;
      _brightness = next[0];
      _contrast = next[1];
      _saturation = next[2];
    });
  }

  void _undo() {
    if (_historyIndex == 0) return;
    setState(() {
      _historyIndex--;
      _applyAdjustment(_currentAdjustment);
    });
  }

  void _redo() {
    if (_historyIndex == _history.length - 1) return;
    setState(() {
      _historyIndex++;
      _applyAdjustment(_currentAdjustment);
    });
  }

  void _resetAdjustments() {
    const reset = [0.0, 0.0, 0.0];
    if (_historyIndex == 0 && _currentAdjustment.every((value) => value == 0.0)) {
      return;
    }
    setState(() {
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      _history.add(reset);
      _historyIndex++;
      _applyAdjustment(reset);
    });
  }

  void _applyAdjustment(List<double> adjustment) {
    _brightness = adjustment[0];
    _contrast = adjustment[1];
    _saturation = adjustment[2];
  }

  ColorFilter _adjustmentFilter() {
    final brightness = _brightness * 255;
    final contrast = _contrast + 1;
    final saturation = _saturation + 1;
    final inverse = 1 - saturation;
    final red = 0.213 * inverse;
    final green = 0.715 * inverse;
    final blue = 0.072 * inverse;
    final offset = 128 * (1 - contrast) + brightness;
    return ColorFilter.matrix([
      (red + saturation) * contrast, green * contrast, blue * contrast, 0, offset,
      red * contrast, (green + saturation) * contrast, blue * contrast, 0, offset,
      red * contrast, green * contrast, (blue + saturation) * contrast, 0, offset,
      0, 0, 0, 1, 0,
    ]);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _image = File(image.path);
        _history
          ..clear()
          ..add(const [0.0, 0.0, 0.0]);
        _historyIndex = 0;
        _applyAdjustment(_history.first);
        _filterColor = Colors.transparent;
      });
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

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color filter'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _filterColor,
              onColorChanged: (Color color) {
                setState(() {
                  _filterColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done'),
            ),
          ],
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
              onPressed: _image != null ? _saveImage : null,
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
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColorFiltered(
                        colorFilter: _adjustmentFilter(),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            _filterColor.withValues(alpha: 0.3),
                            BlendMode.overlay,
                          ),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No image selected',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
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
                    _setAdjustment(0, value);
                  }),
                  _buildSlider('Contrast', _contrast, (value) {
                    _setAdjustment(1, value);
                  }),
                  _buildSlider('Saturation', _saturation, (value) {
                    _setAdjustment(2, value);
                  }),
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
                        onPressed: _showColorPicker,
                        icon: Icon(Icons.color_lens),
                        label: Text('Filter'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _historyIndex > 0 ? _undo : null,
                        icon: const Icon(Icons.undo),
                        tooltip: 'Undo adjustments',
                      ),
                      IconButton(
                        onPressed: _historyIndex < _history.length - 1 ? _redo : null,
                        icon: const Icon(Icons.redo),
                        tooltip: 'Redo adjustments',
                      ),
                      TextButton(
                        onPressed: _historyIndex == 0 ? null : _resetAdjustments,
                        child: const Text('Reset'),
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
      String label, double value, ValueChanged<double> onChanged) {
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
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _saveImage() async {
    if (_image == null) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/editnova_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final source = img.decodeImage(await _image!.readAsBytes());
      if (source == null) throw const FormatException('Unsupported image');
      final edited = img.adjustColor(
        source,
        brightness: _brightness * 100,
        contrast: _contrast * 100,
        saturation: _saturation * 100,
      );
      await File(path).writeAsBytes(img.encodeJpg(edited, quality: 92));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported image to $path')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export the image.')),
        );
      }
    }
  }
}
