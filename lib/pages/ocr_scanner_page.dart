import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

class OCRScannerPage extends StatefulWidget {
  const OCRScannerPage({super.key});

  @override
  State<OCRScannerPage> createState() => _OCRScannerPageState();
}

class _OCRScannerPageState extends State<OCRScannerPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imagePath;
  String _recognizedText = '';
  bool _hasRecognized = false;
  bool _isProcessing = false;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _selectImage() async {
    try {
      final selected = await _picker.pickImage(source: ImageSource.gallery);
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imagePath = selected.path;
        _recognizedText = '';
        _hasRecognized = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open image: $error')));
    }
  }

  Future<void> _recognizeText() async {
    if (!_isSupportedPlatform || _isProcessing) return;
    final imagePath = _imagePath;
    if (imagePath == null) return;

    setState(() => _isProcessing = true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      if (!mounted) return;
      setState(() {
        _recognizedText = result.text;
        _hasRecognized = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Text recognition failed: $error')),
      );
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _recognizedText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Recognized text copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Scanner')),
      body: !_isSupportedPlatform
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'On-device OCR is supported on Android and iOS only.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Text is recognized on-device. English/Latin text is supported by this configuration.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _selectImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select image'),
                ),
                if (_imageBytes != null) ...[
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  onPressed: _imageBytes == null || _isProcessing
                      ? null
                      : _recognizeText,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.document_scanner),
                  label: Text(
                    _isProcessing ? 'Recognizing...' : 'Extract text',
                  ),
                ),
                if (_recognizedText.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recognized text',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy recognized text',
                        onPressed: _copyText,
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                  SelectableText(_recognizedText),
                ] else if (_hasRecognized) ...[
                  const SizedBox(height: 16),
                  const Text('No text was detected in this image.'),
                ] else if (!_isProcessing && _imageBytes != null) ...[
                  const SizedBox(height: 16),
                  const Text('Select Extract text to run OCR.'),
                ],
              ],
            ),
    );
  }
}
