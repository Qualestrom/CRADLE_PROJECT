// Front-End Developer: Ana Marie Ramos

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import '../User/settle_now.dart'; // For WelcomeScreen after logout
import 'package:shared_preferences/shared_preferences.dart'; // For clearing prefs on logout

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void navigateToPlaceholder(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceholderPage(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using AnnotatedRegion for better control over system UI overlay
    return Scaffold(
      // backgroundColor: Colors.white, // This is already handled by the theme or Scaffold default
      backgroundColor: Colors.white, // Set the background color to white
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.only(
              top: 48.0,
              bottom: 10.0,
              left: 16.0,
              right: 16.0), // Increased top padding
          child: Container(
            decoration: BoxDecoration(
              color: const Color(
                  0xFFFEF7FF), // FIXED: Using the color scheme from design
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Center(
                    child: Text('Settings',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87)),
                  ),
                ),
                const SizedBox(
                    width: 48), // Placeholder for alignment if no actions
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Removed Notification Container
          // Removed SizedBox(height: 20)
          ListTile(
            leading: Icon(Icons.star_border),
            title: Text('Rate App'),
            onTap: () {
              // Decoy action: Show SnackBar instead of navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rate App (Placeholder)')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share App'),
            onTap: () {
              // Decoy action: Show SnackBar instead of navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share App (Placeholder)')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
            onTap: () {
              // Decoy action: Show SnackBar instead of navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy (Placeholder)')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Terms and Conditions'),
            onTap: () {
              // Decoy action: Show SnackBar instead of navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Terms and Conditions (Placeholder)')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.cookie_outlined),
            title: Text('Cookies Policy'),
            onTap: () {
              // Decoy action: Show SnackBar instead of navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cookies Policy (Placeholder)')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.contact_mail_outlined),
            title: Text('Contact'),
            onTap: () {
              // Decoy action: Show SnackBar instead of navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact (Placeholder)')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback_outlined),
            title: Text('Feedback'),
            onTap: () {
              // Decoy action: Show SnackBar instead of navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback (Placeholder)')),
              );
            },
          ),
          // Removed Logout ListTile
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Padding(
          padding: const EdgeInsets.only(
              top: 48.0, bottom: 10.0, left: 16.0, right: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBEFFD),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 48), // Placeholder
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Text(
          '$title Page (Placeholder)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class ReviewsPage extends StatelessWidget {
  final List<Map<String, dynamic>> reviews = [
    {
      'username': 'Cheese Pimiento Revisa',
      'date': 'July 13, 2024',
      'text':
          'Iniisip ko kung bakit ganito ang langit nilay ako sayo. Hindi ko matanggap mahirap magpagpaga Na ako\'y hindi bigo...',
    },
    {
      'username': 'Cheese Pimiento Revisa',
      'date': 'July 13, 2024',
      'text':
          'Iniisip ko kung bakit ganito ang langit nilay ako sayo. Hindi ko matanggap mahirap magpagpaga Na ako\'y hindi bigo...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use theme-aware background color
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  // Use theme-aware color
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, size: 24),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Reviews',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Text(
                    '4.3',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Row(
                    children: List.generate(5, (index) {
                      if (index == 3) {
                        // Use theme color for stars
                        return Icon(Icons.star,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24);
                      } else {
                        return Icon(Icons.star_border,
                            // Use a less prominent theme color or grey
                            color: Theme.of(context).colorScheme.outline,
                            size: 24);
                      }
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Divider(),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: reviews.length,
                separatorBuilder: (context, index) => Divider(height: 32),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['username'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              review['date'],
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              review['text'],
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
