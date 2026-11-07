import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextUtilitiesPage extends StatefulWidget {
  const TextUtilitiesPage({super.key});

  @override
  State<TextUtilitiesPage> createState() => _TextUtilitiesPageState();
}

class _TextUtilitiesPageState extends State<TextUtilitiesPage> {
  static const _tools = [
    'Base64 encode',
    'Base64 decode',
    'Format JSON',
    'Regex match',
    'Lorem Ipsum',
  ];

  final _inputController = TextEditingController();
  final _patternController = TextEditingController();
  String _selectedTool = _tools.first;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    _patternController.dispose();
    super.dispose();
  }

  void _runTool() {
    try {
      final input = _inputController.text;
      final result = switch (_selectedTool) {
        'Base64 encode' => base64Encode(utf8.encode(input)),
        'Base64 decode' => utf8.decode(base64Decode(input.trim())),
        'Format JSON' => const JsonEncoder.withIndent(
          '  ',
        ).convert(jsonDecode(input)),
        'Regex match' => _formatMatches(input),
        'Lorem Ipsum' =>
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        _ => throw StateError('Unknown text tool.'),
      };
      setState(() {
        _result = result;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _error = error.message;
      });
    } catch (error) {
      setState(() {
        _result = null;
        _error = error.toString();
      });
    }
  }

  String _formatMatches(String input) {
    final pattern = _patternController.text;
    if (pattern.isEmpty)
      throw const FormatException('Enter a regular expression.');
    final matches = RegExp(pattern).allMatches(input).toList();
    if (matches.isEmpty) return 'No matches.';
    return matches
        .map((match) => '${match.start}: ${match.group(0)}')
        .join('\n');
  }

  Future<void> _copyResult() async {
    final result = _result;
    if (result == null) return;
    await Clipboard.setData(ClipboardData(text: result));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Result copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final needsInput = _selectedTool != 'Lorem Ipsum';
    return Scaffold(
      appBar: AppBar(title: const Text('Text Utilities')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _selectedTool,
            decoration: const InputDecoration(labelText: 'Tool'),
            items: _tools
                .map((tool) => DropdownMenuItem(value: tool, child: Text(tool)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedTool = value;
                _result = null;
                _error = null;
              });
            },
          ),
          if (_selectedTool == 'Regex match') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _patternController,
              decoration: const InputDecoration(
                labelText: 'Regular expression',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (needsInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Input text',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _runTool,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Result',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy result',
                  onPressed: _copyResult,
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            SelectableText(_result!),
          ],
        ],
      ),
    );
  }
}
