import 'package:flutter/material.dart';

class GpuView extends StatelessWidget {
  const GpuView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'GPU View',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }
}
