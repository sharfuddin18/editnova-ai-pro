import 'package:flutter/material.dart';

class BatchProcessorPage extends StatelessWidget {
  const BatchProcessorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Processor'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Coming soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
