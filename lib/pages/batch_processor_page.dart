import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/batch_image_processing.dart';

class BatchProcessorPage extends StatefulWidget {
  const BatchProcessorPage({super.key});

  @override
  State<BatchProcessorPage> createState() => _BatchProcessorPageState();
}

class _BatchProcessorPageState extends State<BatchProcessorPage> {
  List<PlatformFile> _files = [];
  int _maxDimension = 1600;
  String _format = 'PNG';
  bool _isProcessing = false;
  String? _status;

  Future<void> _selectImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;
      setState(() {
        _files = result.files;
        _status = _files.isEmpty ? null : '${_files.length} image(s) selected';
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select images: $error')),
      );
    }
  }

  Future<void> _processImages() async {
    if (_files.isEmpty || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _status = 'Preparing ${_files.length} image(s)...';
    });

    var saved = 0;
    var failed = 0;
    var canceled = 0;
    for (final file in _files) {
      try {
        final bytes = file.bytes;
        if (bytes == null) {
          failed++;
          continue;
        }
        final output = await compute(
          resizeAndEncodeImage,
          BatchImageRequest(
            bytes: bytes,
            maxDimension: _maxDimension,
            format: _format,
          ),
        );
        final baseName = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
        final extension = _format.toLowerCase() == 'jpeg' ? 'jpg' : 'png';
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save processed ${file.name}',
          fileName: '${baseName}_$_maxDimension.$extension',
          bytes: output,
        );
        if (path != null || kIsWeb) {
          saved++;
        } else {
          canceled++;
        }
      } catch (_) {
        failed++;
      }
      if (mounted) {
        setState(
          () => _status =
              'Processed ${saved + failed + canceled} of ${_files.length}',
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _status = 'Saved: $saved · Failed: $failed · Canceled: $canceled';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Image Processor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Images'),
            subtitle: Text('${_files.length} selected'),
            trailing: IconButton(
              tooltip: 'Select images',
              onPressed: _isProcessing ? null : _selectImages,
              icon: const Icon(Icons.add_photo_alternate),
            ),
          ),
          for (final file in _files.take(8))
            ListTile(
              dense: true,
              leading: const Icon(Icons.image_outlined),
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
            ),
          if (_files.length > 8) Text('And ${_files.length - 8} more image(s)'),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _maxDimension,
            decoration: const InputDecoration(
              labelText: 'Maximum image dimension',
              border: OutlineInputBorder(),
            ),
            items: const [1024, 1600, 2048, 4096]
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text('$value px')),
                )
                .toList(),
            onChanged: _isProcessing
                ? null
                : (value) {
                    if (value != null) setState(() => _maxDimension = value);
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _format,
            decoration: const InputDecoration(
              labelText: 'Output format',
              border: OutlineInputBorder(),
            ),
            items: const ['PNG', 'JPEG']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: _isProcessing
                ? null
                : (value) {
                    if (value != null) setState(() => _format = value);
                  },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _files.isEmpty || _isProcessing ? null : _processImages,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.transform),
            label: Text(_isProcessing ? 'Processing...' : 'Process images'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
