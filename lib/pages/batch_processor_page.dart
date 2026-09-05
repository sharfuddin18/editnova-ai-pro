import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';

class BatchProcessorPage extends StatefulWidget {
  const BatchProcessorPage({super.key});

  @override
  State<BatchProcessorPage> createState() => _BatchProcessorPageState();
}

class _BatchProcessorPageState extends State<BatchProcessorPage> {
  List<PlatformFile> _files = [];
  String _operation = 'enhance';
  bool _loading = false;
  String _status = '';

  Future<void> _chooseFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
    if (result != null) setState(() { _files = result.files; _status = ''; });
  }

  Future<void> _process() async {
    if (_files.isEmpty) { _notify('Choose at least one file first.'); return; }
    setState(() => _loading = true);
    try {
      final fileIds = <String>[];
      for (final file in _files) {
        final upload = http.MultipartRequest('POST', ApiConfig.endpoint('/api/upload-image'));
        if (file.path != null) {
          upload.files.add(await http.MultipartFile.fromPath('file', file.path!));
        } else if (file.bytes != null) {
          upload.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
        } else {
          throw Exception('File bytes unavailable');
        }
        final uploadResponse = await http.Response.fromStream(await upload.send());
        if (uploadResponse.statusCode != 200) throw Exception('Upload failed');
        fileIds.add((jsonDecode(uploadResponse.body) as Map<String, dynamic>)['imageId'].toString());
      }
      final response = await http.post(ApiConfig.endpoint('/api/batch-process'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'fileIds': fileIds, 'operation': _operation}));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw Exception(data['message']);
      if (!mounted) return;
      setState(() => _status = 'Job ${data['jobId']} queued for ${data['total']} files.');
    } catch (_) {
      _notify('Batch service is unavailable. Check the backend connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notify(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Batch Processor')), body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Process a whole set at once', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Queue multiple files for a single operation and keep the workflow moving.'),
      const SizedBox(height: 24),
      DropdownButtonFormField<String>(initialValue: _operation, decoration: const InputDecoration(labelText: 'Operation'), items: const [DropdownMenuItem(value: 'enhance', child: Text('Enhance')), DropdownMenuItem(value: 'resize', child: Text('Resize')), DropdownMenuItem(value: 'convert', child: Text('Convert'))], onChanged: (value) { if (value != null) setState(() => _operation = value); }),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: _loading ? null : _chooseFiles, icon: const Icon(Icons.folder_open), label: Text(_files.isEmpty ? 'Choose files' : '${_files.length} files selected')),
      ..._files.map((file) => ListTile(dense: true, leading: const Icon(Icons.insert_drive_file_outlined), title: Text(file.name), subtitle: Text('${file.size} bytes'))),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _loading ? null : _process, icon: _loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow), label: Text(_loading ? 'Queueing...' : 'Start batch job')),
      if (_status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_status)))),
    ]));
  }
}
