import 'package:flutter/material.dart';
import 'package:editnova/ai_assistant.dart';
import 'package:editnova/models/ai_response.dart';

class AiScreen extends StatelessWidget {
  final AiAssistant assistant;
  const AiScreen({super.key, required this.assistant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Editor')),
      body: FutureBuilder<AiResponse>(
        future: assistant.getData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Center(child: Text('Status: ${snapshot.data!.status}'));
          }
        },
      ),
    );
  }
}
