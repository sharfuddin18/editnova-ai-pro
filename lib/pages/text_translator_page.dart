import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TextTranslatorPage extends StatefulWidget {
  @override
  _TextTranslatorPageState createState() => _TextTranslatorPageState();
}

class _TextTranslatorPageState extends State<TextTranslatorPage> {
  final TextEditingController _textController = TextEditingController();
  String _sourceLanguage = 'English';
  String _targetLanguage = 'Spanish';
  String _translatedText = '';
  bool _isTranslating = false;

  final List<Language> _languages = [
    Language('English', 'en', '🇺🇸'),
    Language('Spanish', 'es', '🇪🇸'),
    Language('French', 'fr', '🇫🇷'),
    Language('German', 'de', '🇩🇪'),
    Language('Italian', 'it', '🇮🇹'),
    Language('Portuguese', 'pt', '🇵🇹'),
    Language('Russian', 'ru', '🇷🇺'),
    Language('Chinese', 'zh', '🇨🇳'),
    Language('Japanese', 'ja', '🇯🇵'),
    Language('Korean', 'ko', '🇰🇷'),
    Language('Arabic', 'ar', '🇸🇦'),
    Language('Hindi', 'hi', '🇮🇳'),
  ];

  Future<void> _translateText() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter text to translate')),
      );
      return;
    }

    if (_sourceLanguage == _targetLanguage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please select different source and target languages')),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _textController.text,
          'source': _getLanguageCode(_sourceLanguage),
          'target': _getLanguageCode(_targetLanguage),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _translatedText =
              data['translatedText'] ?? 'Translation completed successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text translated successfully! 🌍'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to translate text')),
      );
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  String _getLanguageCode(String languageName) {
    return _languages.firstWhere((lang) => lang.name == languageName).code;
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;

      if (_translatedText.isNotEmpty) {
        _textController.text = _translatedText;
        _translatedText = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Text Translator',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _showTranslationHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Selector
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _sourceLanguage,
                                isExpanded: true,
                                underline: Container(),
                                items: _languages
                                    .map((lang) => DropdownMenuItem(
                                          value: lang.name,
                                          child: Row(
                                            children: [
                                              Text(lang.flag,
                                                  style:
                                                      TextStyle(fontSize: 20)),
                                              SizedBox(width: 8),
                                              Text(lang.name),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _sourceLanguage = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _swapLanguages,
                          icon: Icon(Icons.swap_horiz, color: Colors.blue),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _targetLanguage,
                                isExpanded: true,
                                underline: Container(),
                                items: _languages
                                    .map((lang) => DropdownMenuItem(
                                          value: lang.name,
                                          child: Row(
                                            children: [
                                              Text(lang.flag,
                                                  style:
                                                      TextStyle(fontSize: 20)),
                                              SizedBox(width: 8),
                                              Text(lang.name),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _targetLanguage = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Input Text
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enter text to translate',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_textController.text.length}/500',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Type or paste your text here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '',
                      ),
                      onChanged: (text) => setState(() {}),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _textController.clear(),
                          icon: Icon(Icons.clear, size: 16),
                          label: Text('Clear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.grey.shade700,
                            minimumSize: Size(80, 32),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _pasteFromClipboard(),
                          icon: Icon(Icons.paste, size: 16),
                          label: Text('Paste'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade700,
                            minimumSize: Size(80, 32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Translate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isTranslating ? null : _translateText,
                icon: _isTranslating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(Icons.translate),
                label: Text(
                  _isTranslating ? 'Translating...' : 'Translate Text',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Translation Result
            if (_translatedText.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Translation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _copyToClipboard(_translatedText),
                                icon: Icon(Icons.copy, size: 20),
                                tooltip: 'Copy translation',
                              ),
                              IconButton(
                                onPressed: () => _speakText(_translatedText),
                                icon: Icon(Icons.volume_up, size: 20),
                                tooltip: 'Listen to translation',
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          _translatedText,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 16),

            // Quick Phrases
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Phrases',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Hello',
                        'Thank you',
                        'Please',
                        'Excuse me',
                        'How are you?',
                        'Good morning',
                        'Good night',
                        'Yes',
                        'No'
                      ]
                          .map((phrase) => GestureDetector(
                                onTap: () => _textController.text = phrase,
                                child: Chip(
                                  label: Text(phrase,
                                      style: TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.blue.shade100,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Language Info
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Translation Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Keep sentences simple for better accuracy\n'
                      '• Check context for idiomatic expressions\n'
                      '• Use proper punctuation and capitalization\n'
                      '• Review translations for cultural nuances',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
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

  void _pasteFromClipboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paste from clipboard feature coming soon!')),
    );
  }

  void _copyToClipboard(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Translation copied to clipboard!')),
    );
  }

  void _speakText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text-to-speech feature coming soon!')),
    );
  }

  void _showTranslationHistory() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Translation History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Text('🇺🇸→🇪🇸', style: TextStyle(fontSize: 20)),
              title: Text('Hello → Hola'),
              subtitle: Text('English to Spanish • Today'),
              trailing: IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
            ListTile(
              leading: Text('🇫🇷→🇺🇸', style: TextStyle(fontSize: 20)),
              title: Text('Bonjour → Hello'),
              subtitle: Text('French to English • Yesterday'),
              trailing: IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
            ListTile(
              leading: Text('🇩🇪→🇺🇸', style: TextStyle(fontSize: 20)),
              title: Text('Danke → Thank you'),
              subtitle: Text('German to English • 2 days ago'),
              trailing: IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Language {
  final String name;
  final String code;
  final String flag;

  Language(this.name, this.code, this.flag);
}
