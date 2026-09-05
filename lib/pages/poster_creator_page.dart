import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';

class PosterCreatorPage extends StatefulWidget {
  const PosterCreatorPage({super.key});

  @override
  State<PosterCreatorPage> createState() => _PosterCreatorPageState();
}

class _PosterCreatorPageState extends State<PosterCreatorPage> {
  final _textController = TextEditingController(text: 'EditNova Studio');
  final _themes = const ['Modern', 'Minimal', 'Neon', 'Elegant'];
  String _theme = 'Modern';
  bool _loading = false;
  String _status = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _createPoster() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title for your poster.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await http.post(ApiConfig.endpoint('/api/create-poster'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'theme': _theme.toLowerCase(), 'text': text}));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw Exception(data['message']);
      if (mounted) setState(() => _status = data['message']?.toString() ?? 'Poster created successfully.');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poster service is unavailable. Check the backend connection.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poster Creator')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Design a poster with Nova', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Choose a visual direction and create a poster brief from your message.'),
        const SizedBox(height: 24),
        TextField(controller: _textController, maxLines: 3, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Poster title or message', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(initialValue: _theme, decoration: const InputDecoration(labelText: 'Theme'), items: _themes.map((theme) => DropdownMenuItem(value: theme, child: Text(theme))).toList(), onChanged: (value) { if (value != null) setState(() => _theme = value); }),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16)), child: Column(children: [const Icon(Icons.auto_awesome, size: 40, color: Colors.green), const SizedBox(height: 12), Text(_textController.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: _loading ? null : _createPoster, icon: _loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.create), label: Text(_loading ? 'Creating...' : 'Create poster')),
        if (_status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_status)))),
      ]),
    );
  }
}
