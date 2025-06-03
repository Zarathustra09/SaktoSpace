import 'package:flutter/material.dart';

class OnSaleScreen extends StatelessWidget {
  const OnSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('On Sale'),
      ),
      body: Center(
        child: const Text(
          'On Sale Products List',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
