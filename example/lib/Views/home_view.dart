import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home View',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }
}
