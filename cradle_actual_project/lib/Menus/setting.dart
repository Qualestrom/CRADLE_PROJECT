// Front-End Developer: Ana Marie Ramos

import 'package:flutter/material.dart';

void main() {
  runApp(CradleApp());
}

class CradleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cradle',
      theme: ThemeData(
        primaryColor: Color(0xFF6B5B95),
        scaffoldBackgroundColor: Color(0xFFF2ECF8),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF6B5B95),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('CRADLE'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Welcome to Cradle!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFFF2ECF8),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF6B5B95),
              ),
              child: Image.asset('assets/logo.png'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SettingsPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsOn = true;

  void navigateToPlaceholder(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceholderPage(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFE8E1F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_none, color: Colors.black54),
                    SizedBox(width: 12),
                    Text('Notification', style: TextStyle(fontSize: 16)),
                  ],
                ),
                Switch(
                  value: _notificationsOn,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsOn = value;
                    });
                  },
                  activeColor: Color(0xFF6B5B95),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.star_border),
            title: Text('Rate App'),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ReviewsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share App'),
            onTap: () => navigateToPlaceholder(context, 'Share App'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
            onTap: () => navigateToPlaceholder(context, 'Privacy Policy'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Terms and Conditions'),
            onTap: () => navigateToPlaceholder(context, 'Terms and Conditions'),
          ),
          ListTile(
            leading: Icon(Icons.cookie_outlined),
            title: Text('Cookies Policy'),
            onTap: () => navigateToPlaceholder(context, 'Cookies Policy'),
          ),
          ListTile(
            leading: Icon(Icons.contact_mail_outlined),
            title: Text('Contact'),
            onTap: () => navigateToPlaceholder(context, 'Contact'),
          ),
          ListTile(
            leading: Icon(Icons.feedback_outlined),
            title: Text('Feedback'),
            onTap: () => navigateToPlaceholder(context, 'Feedback'),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => navigateToPlaceholder(context, 'Logged Out'),
          ),
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
      appBar: AppBar(title: Text(title)),
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
      backgroundColor: Color(0xFFF5EDF8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
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
                        return Icon(Icons.star, color: Colors.purple, size: 24);
                      } else {
                        return Icon(Icons.star_border,
                            color: Colors.grey, size: 24);
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
