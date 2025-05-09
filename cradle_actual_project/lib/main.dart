import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'User/landing_page.dart'; // Import the landing page
import 'utils/firebase_options.dart'; // Import Firebase options
import 'package:logging/logging.dart'; // Import the logging package
// Import other necessary pages if needed later

// The following commented-out import might be redundant if 'utils/firebase_options.dart' is the correct one.
// Consider removing if 'utils/firebase_options.dart' is the intended file from flutterfire_cli.
// import 'firebase_options.dart';

final _logger = Logger('CradleApp');

void _setupLogging() {
  Logger.root.level = Level.ALL; // Log all messages by default.
  Logger.root.onRecord.listen((record) {
    // Simple console output for logs.
    // You can customize this to write to a file, send to a remote server, etc.
    // Using debugPrint for better console output in Flutter.
    debugPrint(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter bindings are ready
  _setupLogging(); // Initialize logging early

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.info("Firebase initialized successfully.");
    runApp(const CradleApp());
  } catch (e, stackTrace) {
    _logger.severe("Failed to initialize Firebase or run app", e, stackTrace);
    // Optionally, you could run a different app here to show an error message to the user
    // runApp(ErrorApp(error: e.toString()));
  }
}

class CradleApp extends StatelessWidget {
  const CradleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase is already initialized in main(), so no need for FutureBuilder here
    return MaterialApp(
      title: 'Cradle', // Your main app title
      theme: ThemeData(
        // Using ColorScheme for more modern and flexible theming
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          // You can further customize brightness, primary, secondary colors etc.
          // brightness: Brightness.light,
        ),
        // primarySwatch is still useful for some older components or as a fallback
        primarySwatch: Colors.deepPurple,
        useMaterial3: true, // Recommended for new apps
      ),
      home: const LandingPage(), // Start with the LandingPage
    );
  }
}
