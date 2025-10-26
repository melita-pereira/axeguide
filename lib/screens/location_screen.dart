import 'package:flutter/material.dart';

class location_screen extends StatelessWidget {
  const location_screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
      ),
      body: const Center(
        child: Text(
          'This is a placeholder for the Locations screen.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
