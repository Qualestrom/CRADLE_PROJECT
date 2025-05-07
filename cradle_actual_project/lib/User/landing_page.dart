import 'dart:async'; // Import async library for Timer
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import 'settle_now.dart'; // Import the WelcomeScreen
import '../Renter UI/renter_home_screen.dart'; // Import Renter Home Screen
import '../Owner UI/owner_properties.dart'; // Import Owner Home Screen (MyPropertyScreen)
// Removed the main() function and CradleApp class as they are now in main.dart

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

// Helper function for creating a slide transition PageRoute
PageRouteBuilder<dynamic> _createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 500),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate(); // Start the check process
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for the splash screen duration
    await Future.delayed(
        const Duration(seconds: 3)); // Adjust duration as needed

    if (!mounted) return; // Check if widget is still mounted after delay

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // --- User Not Logged In ---
      // Navigate to WelcomeScreen
      Navigator.of(context)
          .pushReplacement(_createSlideRoute(const WelcomeScreen()));
    } else {
      // --- User Logged In ---
      try {
        // Fetch user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final accountType = userDoc.data()?['accountType'];

          if (accountType == 'renter') {
            Navigator.of(context)
                .pushReplacement(_createSlideRoute(const RenterHomeScreen()));
          } else if (accountType == 'owner') {
            Navigator.of(context)
                .pushReplacement(_createSlideRoute(const MyPropertyScreen()));
          } else {
            // Fallback: Account type missing or invalid, go to WelcomeScreen
            print(
                "Warning: Logged in user (${user.uid}) has missing or invalid accountType ('$accountType'). Navigating to WelcomeScreen.");
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          }
        } else {
          // User document doesn't exist in Firestore (might be an error state)
          print(
              "Warning: User document not found for logged in user (${user.uid}). Navigating to WelcomeScreen.");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      } catch (e) {
        print(
            "Error fetching user data during auth check: $e. Navigating to WelcomeScreen.");
        Navigator.of(context).pushReplacement(
          // Use pushReplacement to prevent going back
          MaterialPageRoute(
              builder: (context) => const WelcomeScreen()), // Fallback on error
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The UI remains the same
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
