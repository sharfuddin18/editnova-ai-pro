import 'package:flutter/material.dart';
import 'package:editnova/ai_assistant.dart';
import 'package:editnova/screens/ai_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Since you are using a real HTTP client,
    // make sure you have internet access.
    final assistant = AiAssistant(
      client: RealHttpClientAdapter(),
      baseUrl: 'https://api.example.com/status',
    );

    return MaterialApp(
      home: AiScreen(assistant: assistant),
    );
  }
}
