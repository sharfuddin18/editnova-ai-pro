import 'package:flutter/material.dart';
import 'package:editnova/pages/home_page.dart';

void main() {
  runApp(const EditNovaApp());
}

class EditNovaApp extends StatelessWidget {
  const EditNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EditNova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomePage(),
    );
  }
}
