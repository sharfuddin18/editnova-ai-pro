import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EditNova-AI-Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('🎉 EditNova-AI-Pro Web'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.web, size: 100, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'EditNova-AI-Pro',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Web App Successfully Running!'),
              Text('Flutter 3.32.8 + Gradle 8.14.2'),
              Text('Infrastructure Upgrade Complete! 🚀'),
            ],
          ),
        ),
      ),
    );
  }
}
