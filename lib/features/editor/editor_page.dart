import 'package:flutter/material.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation App'),
      ),
      body: const Center(
        child: Text('Animation Editor'),
      ),
    );
  }
}
