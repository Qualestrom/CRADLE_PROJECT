import 'package:flutter/material.dart';

void main() {
  runApp(const CradleApp());
}

class CradleApp extends StatelessWidget {
  const CradleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cradle',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/cradle background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Logo and potentially other content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/CRADLE LOGO 1.1.png',
                  width: 250, // Adjust width as needed
                  height: 150, // Adjust height as needed
                ),
                const SizedBox(height: 20), // Add some spacing
                // You can add more widgets here like buttons, text, etc.
                // For example:
                /*
                ElevatedButton(
                  onPressed: () {
                    // Handle button press
                  },
                  child: const Text('Enter'),
                ),
                */
              ],
            ),
          ),
        ],
      ),
    );
  }
}