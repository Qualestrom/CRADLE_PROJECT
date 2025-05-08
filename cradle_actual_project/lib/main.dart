import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'User/landing_page.dart'; // Import the landing page
import 'utils/firebase_options.dart'; // Import Firebase options
import 'package:logging/logging.dart'; // Import the logging package
// Import other necessary pages if needed later
// Import Firebase options if using flutterfire_cli (uncomment if needed)
// import 'firebase_options.dart';

void _setupLogging() {
  Logger.root.level = Level.ALL; // Log all messages by default.
  Logger.root.onRecord.listen((record) {
    // Simple console output for logs.
    // You can customize this to write to a file, send to a remote server, etc.
    // ignore: avoid_print
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
}

Future<void> main() async {
  // Make main async
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter bindings are ready
  _setupLogging(); // Initialize logging
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
