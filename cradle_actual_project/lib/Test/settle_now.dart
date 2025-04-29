import 'package:flutter/material.dart';

void main() {
  runApp(CradleApp());
}

class CradleApp extends StatelessWidget {
  const CradleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settle Now',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        // Removed fontFamily: 'YourCustomFont',
      ),
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Content Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // "Settle Now" Text
                  Text(
                    'Settle Now',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Description Text
                  Text(
                    'Start finding a place to settle inside GCH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  // Log In Button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle Log In button press
                        print('Log In pressed');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple[700],
                        side: BorderSide(color: Colors.deepPurple[700]!),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Log In',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Sign Up Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Sign Up button press
                        print('Sign Up pressed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[700],
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Terms and Privacy Policy Text
                  Text(
                    'By signing up or logging in, I accept the Cradle\'s Terms of Services and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logo (positioned at the top-center)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15, // Adjust as needed
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset(
                  'assets/CRADLE LOGO 1.1.png', // Replace with your actual logo path
                  height: 120, // Adjust the size as needed
                ),
                SizedBox(height: 8),
                Text(
                  'CRADLE',
                  style: TextStyle(
                    // Removed fontFamily: 'YourCustomFont',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                    shadows: [
                      Shadow(
                        blurRadius: 3.0,
                        color: Colors.purple.shade200,
                        offset: Offset(1.5, 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}