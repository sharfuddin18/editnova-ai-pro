import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

class PosterCreatorPage extends StatefulWidget {
  const PosterCreatorPage({super.key});

  @override
  State<PosterCreatorPage> createState() => _PosterCreatorPageState();
}

class _PosterCreatorPageState extends State<PosterCreatorPage> {
  final _posterKey = GlobalKey();
  final _titleController = TextEditingController(text: 'Make it memorable');
  final _bodyController = TextEditingController(text: 'Add your message here');
  Color _background = const Color(0xFF176B63);
  bool _isSaving = false;

  static const _backgrounds = [
    Color(0xFF176B63),
    Color(0xFF263B67),
    Color(0xFF983F43),
    Color(0xFF8A6127),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _savePoster() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final boundary = _posterKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Poster preview is not ready.');
      }
      final rendered = await boundary.toImage(pixelRatio: 3);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      if (data == null) throw StateError('Could not encode the poster image.');

      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save poster',
        fileName: 'editnova-poster.png',
        bytes: bytes,
      );
      if (!mounted || (path == null && !kIsWeb)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? 'Poster download started.' : 'Poster saved to $path',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save poster: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poster Creator'),
        actions: [
          IconButton(
            tooltip: 'Save poster as PNG',
            onPressed: _isSaving ? null : _savePoster,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: RepaintBoundary(
              key: _posterKey,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _background,
                  gradient: LinearGradient(
                    colors: [
                      _background,
                      Color.lerp(_background, Colors.black, 0.4)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EDITNOVA  /  POSTER',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text.trim().isEmpty
                                ? 'Your headline'
                                : _titleController.text.trim(),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _bodyController.text.trim().isEmpty
                                ? 'Supporting message'
                                : _bodyController.text.trim(),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'DESIGNED WITH EDITNOVA',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Headline',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _bodyController,
            maxLength: 180,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Supporting text',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          const Text('Background color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              for (final color in _backgrounds)
                Semantics(
                  label: 'Choose background color',
                  button: true,
                  selected: color == _background,
                  child: InkWell(
                    onTap: () => setState(() => _background = color),
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      backgroundColor: color,
                      child: color == _background
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
