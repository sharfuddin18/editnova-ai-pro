import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

class NovaAssistant {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

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
      // Example: Call backend for poster creation
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/create-poster'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'theme': 'default'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await speak(data['message']);
      } else {
        await speak('Failed to create poster. Please try again.');
      }
    } else if (command.contains('generate art')) {
      await speak('Generating AI art. Please provide a description.');
      // Example: Call backend for AI art generation
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/generate-art'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': 'abstract'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await speak(data['message']);
      } else {
        await speak('Failed to generate art. Please try again.');
      }
    } else if (command.contains('translate text')) {
      await speak('Translating text. Please specify the target language.');
      // Example: Call backend for text translation
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/translate-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': 'Hello', 'language': 'es'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await speak(data['message']);
      } else {
        await speak('Failed to translate text. Please try again.');
      }
    } else {
      await speak('Sorry, I did not understand the advanced command.');
    }
  }
}
