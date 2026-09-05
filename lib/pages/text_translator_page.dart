import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';

class TextTranslatorPage extends StatefulWidget {
  const TextTranslatorPage({super.key});

  @override
  State<TextTranslatorPage> createState() => _TextTranslatorPageState();
}

class _TextTranslatorPageState extends State<TextTranslatorPage> {
  final _textController = TextEditingController();
  final _languages = const ['English', 'Spanish', 'French', 'German', 'Italian'];
  String _source = 'English';
  String _target = 'Spanish';
  String _result = '';
  bool _loading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _notify('Enter text to translate.');
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await http.post(
        ApiConfig.endpoint('/api/translate-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'sourceLang': _source.substring(0, 2).toLowerCase(), 'targetLang': _target.substring(0, 2).toLowerCase()}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw Exception(data['message']);
      if (!mounted) return;
      setState(() => _result = data['translatedText']?.toString() ?? '');
    } catch (_) {
      _notify('Translation service is unavailable. Check the backend connection.');
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
      appBar: AppBar(title: const Text('Text Translator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Translate with Nova', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Choose languages, write your message, and get a response from the connected service.'),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _languageMenu('From', _source, (value) => setState(() => _source = value!))),
            IconButton(onPressed: () => setState(() { final old = _source; _source = _target; _target = old; }), icon: const Icon(Icons.swap_horiz)),
            Expanded(child: _languageMenu('To', _target, (value) => setState(() => _target = value!))),
          ]),
          const SizedBox(height: 16),
          TextField(controller: _textController, maxLines: 7, decoration: const InputDecoration(labelText: 'Your text', hintText: 'Type or paste text here...', alignLabelWithHint: true, border: OutlineInputBorder())),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _loading ? null : _translate, icon: _loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.translate), label: Text(_loading ? 'Translating...' : 'Translate')),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(child: Padding(padding: const EdgeInsets.all(18), child: SelectableText(_result, style: const TextStyle(fontSize: 18)))),
          ],
        ],
      ),
    );
  }

  Widget _languageMenu(String label, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(initialValue: value, decoration: InputDecoration(labelText: label), items: _languages.map((language) => DropdownMenuItem(value: language, child: Text(language))).toList(), onChanged: onChanged);
  }
}
