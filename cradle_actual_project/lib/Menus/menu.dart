// Front-End Developer: Ana Marie Ramos

import 'package:flutter/material.dart';

void main() {
  runApp(CradleApp());
}

class CradleApp extends StatelessWidget {
  const CradleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cradle',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF2ECF8), // light pastel violet
        primaryColor: Color(0xFF6B5B95), // deep violet
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
  const HomePage({super.key});

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
          'Home Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: Container(
        color: Color(0xFFF2ECF8),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF6B5B95)),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 80,
                ),
              ),
            ),
            _drawerItem(
              context,
              icon: Icons.person,
              text: 'Profile',
              page: PlaceholderPage(title: 'Profile'),
            ),
            _drawerItem(
              context,
              icon: Icons.bookmark,
              text: 'Bookmarks',
              page: PlaceholderPage(title: 'Bookmarks'),
            ),
            _drawerItem(
              context,
              icon: Icons.settings,
              text: 'Settings',
              page: PlaceholderPage(title: 'Settings'),
            ),
            _drawerItem(
              context,
              icon: Icons.logout,
              text: 'Logout',
              page: PlaceholderPage(title: 'Logged Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context,
      {required IconData icon, required String text, required Widget page}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(text, style: TextStyle(color: Colors.black87)),
      onTap: () {
        Navigator.pop(context); // close the drawer
        Future.delayed(Duration(milliseconds: 250), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        });
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Page',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
