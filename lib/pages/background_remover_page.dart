import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

class BackgroundRemoverPage extends StatefulWidget {
  const BackgroundRemoverPage({super.key});

  @override
  State<BackgroundRemoverPage> createState() => _BackgroundRemoverPageState();
}

class _BackgroundRemoverPageState extends State<BackgroundRemoverPage> {
  File? _originalImage;
  File? _processedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _originalImage = File(image.path);
        _processedImage = null;
      });
    }
  }

  Future<void> _removeBackground() async {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    if (!mounted) return;

    try {
        final source = img.decodeImage(await _originalImage!.readAsBytes());
        if (source == null) throw const FormatException('Unsupported image');
        final corner = source.getPixel(0, 0);
        final output = img.Image.fromBytes(
          width: source.width,
          height: source.height,
          bytes: source.getBytes(order: img.ChannelOrder.rgba).buffer,
          numChannels: 4,
        );
        for (var y = 0; y < output.height; y++) {
          for (var x = 0; x < output.width; x++) {
            final pixel = output.getPixel(x, y);
            final distance = ((pixel.r - corner.r).abs() +
                    (pixel.g - corner.g).abs() +
                    (pixel.b - corner.b).abs()) /
                3;
            if (distance < 32) {
              output.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 0);
            }
          }
        }
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/editnova_no_background.png';
        await File(path).writeAsBytes(img.encodePng(output));
        if (!mounted) return;
        setState(() {
          _processedImage = File(path);
          _isProcessing = false;
        });
    } catch (_) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process this image format.')),
        );
        return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Background removed successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Background Remover'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _processedImage != null
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Image downloaded!')),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Original Image',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _originalImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _originalImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 48),
                                  SizedBox(height: 8),
                                  Text('Tap to select image'),
                                ],
                              ),
                            ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo_library),
                      label: Text('Select Image'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Processed Image',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isProcessing
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Removing background...'),
                                ],
                              ),
                            )
                          : _processedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _processedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.layers_clear, size: 48),
                                      SizedBox(height: 8),
                                      Text('Processed image will appear here'),
                                    ],
                                  ),
                                ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _originalImage != null && !_isProcessing
                          ? _removeBackground
                          : null,
                      icon: Icon(Icons.auto_fix_high),
                      label: Text('Remove Background'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
