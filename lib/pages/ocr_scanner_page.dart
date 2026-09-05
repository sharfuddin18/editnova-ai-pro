import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';

class OCRScannerPage extends StatefulWidget {
  const OCRScannerPage({super.key});

  @override
  State<OCRScannerPage> createState() => _OCRScannerPageState();
}

class _OCRScannerPageState extends State<OCRScannerPage> {
  String? _fileName;
  String _result = '';
  bool _loading = false;

  Future<void> _scan() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null || picked.files.single.name.isEmpty) return;
    final fileName = picked.files.single.name;
    setState(() { _fileName = fileName; _loading = true; _result = ''; });
    try {
      final request = http.MultipartRequest('POST', ApiConfig.endpoint('/api/ocr-extract'));
      if (picked.files.single.path != null) {
        request.files.add(await http.MultipartFile.fromPath('file', picked.files.single.path!));
      } else if (picked.files.single.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', picked.files.single.bytes!, filename: fileName));
      } else {
        throw Exception('Image bytes unavailable');
      }
      final response = await http.Response.fromStream(await request.send());
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw Exception(data['message']);
      if (!mounted) return;
      setState(() => _result = data['extractedText']?.toString() ?? 'No text found.');
    } catch (_) {
      _notify('OCR service is unavailable. Check the backend connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notify(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Scanner')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Extract text from an image', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Select a clear image and send it to the configured OCR service.'),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: _loading ? null : _scan, icon: const Icon(Icons.upload_file), label: Text(_loading ? 'Scanning...' : 'Choose image')),
        if (_fileName != null) ListTile(leading: const Icon(Icons.image_outlined), title: Text(_fileName!), subtitle: const Text('Selected for recognition')),
        if (_loading) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: LinearProgressIndicator()),
        if (_result.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(18), child: SelectableText(_result, style: const TextStyle(fontSize: 17)))),
      ]),
    );
  }
}
