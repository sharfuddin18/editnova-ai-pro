import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class NovaAssistantPage extends StatefulWidget {
  @override
  _NovaAssistantPageState createState() => _NovaAssistantPageState();
}

class _NovaAssistantPageState extends State<NovaAssistantPage>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  String _response = 'Hello! I\'m Nova, your AI assistant. How can I help you today?';
  double _confidence = 1.0;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeTts();
    _requestPermissions();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _requestPermissions() async {
    await Permission.microphone.request();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _animationController.repeat(reverse: true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _animationController.stop();
      _speech.stop();
      _processCommand(_text);
    }
  }

  void _processCommand(String command) {
    String response = _generateResponse(command.toLowerCase());
    setState(() {
      _response = response;
    });
    _speak(response);
  }

  String _generateResponse(String command) {
    if (command.contains('hello') || command.contains('hi')) {
      return 'Hello! How can I assist you with your editing tasks today?';
    } else if (command.contains('edit') || command.contains('image')) {
      return 'I can help you with image editing! You can use our advanced image editor with filters, brightness, and contrast controls.';
    } else if (command.contains('background') || command.contains('remove')) {
      return 'Our background remover can instantly remove backgrounds from your images using AI technology.';
    } else if (command.contains('scan') || command.contains('file')) {
      return 'The file scanner can help you scan and organize your files while checking for potential threats.';
    } else if (command.contains('help')) {
      return 'I can help you with image editing, background removal, file scanning, and general app navigation. What would you like to do?';
    } else if (command.contains('thank')) {
      return 'You\'re welcome! I\'m always here to help with your editing needs.';
    } else {
      return 'I understand you said: "$command". I can help with image editing, background removal, and file scanning. What would you like to do?';
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nova Voice Assistant',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _scaleAnimation.value : 1.0,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: _isListening ? 10 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isListening ? 'Listening...' : 'You said:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!_isListening && _confidence > 0)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Nova says:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _response,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      FloatingActionButton.extended(
                        onPressed: _listen,
                        backgroundColor: _isListening ? Colors.red : Colors.white,
                        foregroundColor: _isListening ? Colors.white : Colors.deepPurple,
                        icon: Icon(_isListening ? Icons.stop : Icons.mic),
                        label: Text(
                          _isListening ? 'Stop' : 'Talk to Nova',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}