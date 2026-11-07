import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class _LanguageOption {
  const _LanguageOption(this.name, this.language);

  final String name;
  final TranslateLanguage language;
}

class TextTranslatorPage extends StatefulWidget {
  const TextTranslatorPage({super.key});

  @override
  State<TextTranslatorPage> createState() => _TextTranslatorPageState();
}

class _TextTranslatorPageState extends State<TextTranslatorPage> {
  static const _languages = <_LanguageOption>[
    _LanguageOption('Arabic', TranslateLanguage.arabic),
    _LanguageOption('Chinese', TranslateLanguage.chinese),
    _LanguageOption('English', TranslateLanguage.english),
    _LanguageOption('French', TranslateLanguage.french),
    _LanguageOption('German', TranslateLanguage.german),
    _LanguageOption('Hindi', TranslateLanguage.hindi),
    _LanguageOption('Italian', TranslateLanguage.italian),
    _LanguageOption('Japanese', TranslateLanguage.japanese),
    _LanguageOption('Korean', TranslateLanguage.korean),
    _LanguageOption('Portuguese', TranslateLanguage.portuguese),
    _LanguageOption('Russian', TranslateLanguage.russian),
    _LanguageOption('Spanish', TranslateLanguage.spanish),
  ];

  final _inputController = TextEditingController();
  final _modelManager = OnDeviceTranslatorModelManager();
  _LanguageOption _source = _languages[2];
  _LanguageOption _target = _languages[11];
  String? _translatedText;
  bool _modelsReady = false;
  bool _isBusy = false;
  bool _wifiOnly = true;
  String? _error;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _checkModels() async {
    if (!_isSupportedPlatform || _isBusy) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final sourceReady = await _modelManager.isModelDownloaded(
        _source.language.bcpCode,
      );
      final targetReady = await _modelManager.isModelDownloaded(
        _target.language.bcpCode,
      );
      if (!mounted) return;
      setState(() => _modelsReady = sourceReady && targetReady);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _modelsReady = false;
        _error = 'Unable to check language models: $error';
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _downloadModels() async {
    if (!_isSupportedPlatform || _isBusy) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final sourceReady = await _modelManager.isModelDownloaded(
        _source.language.bcpCode,
      );
      final targetReady = await _modelManager.isModelDownloaded(
        _target.language.bcpCode,
      );
      final sourceDownloaded =
          sourceReady ||
          await _modelManager.downloadModel(
            _source.language.bcpCode,
            isWifiRequired: _wifiOnly,
          );
      final targetDownloaded =
          targetReady ||
          await _modelManager.downloadModel(
            _target.language.bcpCode,
            isWifiRequired: _wifiOnly,
          );
      if (!sourceDownloaded || !targetDownloaded) {
        throw StateError('A language model could not be downloaded.');
      }
      if (!mounted) return;
      setState(() {
        _modelsReady = true;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Language models are ready for offline use.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _modelsReady = false;
        _error = 'Unable to download language models: $error';
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isBusy) return;
    if (_source.language == _target.language) {
      setState(() {
        _translatedText = text;
        _error = null;
      });
      return;
    }
    if (!_modelsReady) {
      setState(
        () => _error = 'Download both language models before translating.',
      );
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
      _translatedText = null;
    });
    final translator = OnDeviceTranslator(
      sourceLanguage: _source.language,
      targetLanguage: _target.language,
    );
    try {
      final result = await translator.translateText(text);
      if (!mounted) return;
      setState(() => _translatedText = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Translation failed: $error');
    } finally {
      await translator.close();
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _copyTranslation() async {
    final text = _translatedText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Translation copied.')));
  }

  void _updateLanguage({_LanguageOption? source, _LanguageOption? target}) {
    setState(() {
      if (source != null) _source = source;
      if (target != null) _target = target;
      _modelsReady = false;
      _translatedText = null;
      _error = null;
    });
    _checkModels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Translator')),
      body: !_isSupportedPlatform
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'On-device translation is supported on Android and iOS only.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Translations run on-device after language models are downloaded. Model downloads require an internet connection and are Wi-Fi-only by default.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<_LanguageOption>(
                  value: _source,
                  decoration: const InputDecoration(
                    labelText: 'Translate from',
                  ),
                  items: _languages
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isBusy
                      ? null
                      : (value) {
                          if (value != null) _updateLanguage(source: value);
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use Wi-Fi only for model downloads'),
                  value: _wifiOnly,
                  onChanged: _isBusy
                      ? null
                      : (value) => setState(() => _wifiOnly = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_LanguageOption>(
                  value: _target,
                  decoration: const InputDecoration(labelText: 'Translate to'),
                  items: _languages
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isBusy
                      ? null
                      : (value) {
                          if (value != null) _updateLanguage(target: value);
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inputController,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    labelText: 'Text to translate',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {
                    _translatedText = null;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _downloadModels,
                  icon: const Icon(Icons.download),
                  label: Text(
                    _modelsReady
                        ? 'Language models downloaded'
                        : 'Download language models',
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      _isBusy ||
                          !_modelsReady ||
                          _inputController.text.trim().isEmpty
                      ? null
                      : _translate,
                  icon: _isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate),
                  label: Text(_isBusy ? 'Working...' : 'Translate'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_translatedText != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Machine-generated translation may be inaccurate.',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Translation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy translation',
                        onPressed: _copyTranslation,
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                  SelectableText(_translatedText!),
                ],
              ],
            ),
    );
  }
}
