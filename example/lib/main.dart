import 'package:flutter/material.dart';
import 'Views/navbar_view.dart';

void main() {
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AppShell(),
    );
  }
}