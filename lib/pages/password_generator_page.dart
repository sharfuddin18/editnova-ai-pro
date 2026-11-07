import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  static const _characterSets = <String, String>{
    'Uppercase': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'Lowercase': 'abcdefghijklmnopqrstuvwxyz',
    'Numbers': '0123456789',
    'Symbols': '!@#\$%^&*()-_=+[]{}',
  };

  final Random _random = Random.secure();
  final Set<String> _selectedSets = {'Uppercase', 'Lowercase', 'Numbers'};
  int _length = 20;
  String _password = '';

  void _generate() {
    final selected = _characterSets.entries
        .where((entry) => _selectedSets.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    if (selected.isEmpty) return;

    final allCharacters = selected.join();
    final characters = <String>[
      for (final set in selected) set[_random.nextInt(set.length)],
    ];
    while (characters.length < _length) {
      characters.add(allCharacters[_random.nextInt(allCharacters.length)]);
    }
    characters.shuffle(_random);
    setState(() => _password = characters.join());
  }

  Future<void> _copyPassword() async {
    await Clipboard.setData(ClipboardData(text: _password));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Generated locally with a cryptographically secure random source.',
          ),
          const SizedBox(height: 16),
          SelectableText(
            _password.isEmpty ? 'Generate a password' : _password,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate'),
          ),
          OutlinedButton.icon(
            onPressed: _password.isEmpty ? null : _copyPassword,
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          const SizedBox(height: 20),
          Text('Length: $_length characters'),
          Slider(
            value: _length.toDouble(),
            min: 8,
            max: 64,
            divisions: 56,
            label: '$_length',
            onChanged: (value) => setState(() => _length = value.round()),
          ),
          for (final name in _characterSets.keys)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              value: _selectedSets.contains(name),
              onChanged: (enabled) {
                setState(() {
                  if (enabled == true) {
                    _selectedSets.add(name);
                  } else if (_selectedSets.length > 1) {
                    _selectedSets.remove(name);
                  }
                });
              },
            ),
        ],
      ),
    );
  }
}
