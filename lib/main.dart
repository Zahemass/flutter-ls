// main.dart
import 'package:flutter/material.dart';
import 'screens/simple_map_screen.dart'; // 👈 Make sure this file contains the full version

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SimpleMapScreen(), // ✅ This points to your updated screen
    );
  }
}
