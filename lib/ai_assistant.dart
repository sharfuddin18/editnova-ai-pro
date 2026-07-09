import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';

import 'network/http_backend.dart';

class NovaAssistant {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  final HttpBackend _backend;
  final Uri _baseUri;

  NovaAssistant({
    HttpBackend? backend,
    Uri? baseUri,
  })  : _backend = backend ?? HttpBackendImpl(),
        _baseUri = baseUri ?? Uri.parse('http://localhost:5001');

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<String?> listen() async {
    bool available = await _speechToText.initialize();
    if (available) {
      await _speechToText.listen();
      return _speechToText.lastRecognizedWords;
    } else {
      return null;
    }
  }

  void stopListening() {
    _speechToText.stop();
  }

  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
  }

  Future<void> handleCommand(String command) async {
    if (command.contains('remove background')) {
      await speak('Removing the background. Please wait.');
      // Trigger background removal logic here
    } else if (command.contains('make it brighter')) {
      await speak('Enhancing brightness. Please wait.');
      // Trigger brightness enhancement logic here
    } else {
      await speak('Sorry, I did not understand the command.');
    }
  }

  Future<void> handleAdvancedCommand(String command) async {
    if (command.contains('create poster')) {
      await speak('Creating a poster. Please describe the theme.');

      final response = await _backend.postJson(
        _baseUri.replace(path: '/api/create-poster'),
        body: const {'theme': 'default'},
      );

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        await speak(decoded['message']?.toString() ?? 'Poster created');
      } else {
        await speak('Failed to create poster. Please try again.');
      }
    } else if (command.contains('generate art')) {
      await speak('Generating AI art. Please provide a description.');

      final response = await _backend.postJson(
        _baseUri.replace(path: '/api/generate-art'),
        body: const {'description': 'abstract'},
      );

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        await speak(decoded['message']?.toString() ?? 'AI art generated');
      } else {
        await speak('Failed to generate art. Please try again.');
      }
    } else if (command.contains('translate text')) {
      await speak('Translating text. Please specify the target language.');

      final response = await _backend.postJson(
        _baseUri.replace(path: '/api/translate-text'),
        body: const {'text': 'Hello', 'language': 'es'},
      );

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        await speak(decoded['message']?.toString() ?? 'Text translated');
      } else {
        await speak('Failed to translate text. Please try again.');
      }
    } else {
      await speak('Sorry, I did not understand the advanced command.');
    }
  }

  Map<String, dynamic> _decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return <String, dynamic>{};
  }
}
