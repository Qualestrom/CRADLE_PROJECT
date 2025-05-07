import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'User/landing_page.dart'; // Import the landing page
import 'firebase_options.dart'; // Import Firebase options
// Import other necessary pages if needed later
// Import Firebase options if using flutterfire_cli (uncomment if needed)
// import 'firebase_options.dart';

Future<void> main() async {
  // Make main async
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter bindings are ready
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // Initialize with options here
  );
  runApp(const CradleApp()); // Then run the app
}

class CradleApp extends StatelessWidget {
  const CradleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase is already initialized in main(), so no need for FutureBuilder here
    return MaterialApp(
      title: 'Cradle', // Your main app title
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Your app theme
      ),
      home: const LandingPage(), // Start with the LandingPage
    );
  }
}
