import 'package:flutter/material.dart';
// Imports needed for the backend functionality
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';

// Import models and helpers needed for listing display and navigation
import '../Test/for_rent.dart';
import '../Test/apartment.dart';
import '../Test/bedspace.dart';
import '../Test/listing_add_edit_fragment.dart';
import '../utils/string_extensions.dart';

void main() async {
  // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are ready
  await Firebase.initializeApp(); // Initialize Firebase and wait for it
  runApp(const MyApp()); // Then run the app
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Property App',
      debugShowCheckedModeBanner: false, // Removed the debug banner
      home: const MyPropertyScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final String propertyName;
  final String propertyType;
  final String imageUrl;
  final String price;
  final String contractDuration;
  final String description;

  const PropertyCard({
    super.key,
    required this.propertyName,
    required this.propertyType,
    required this.imageUrl,
    required this.price,
    required this.contractDuration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple[400],
                  child: Text(
                    propertyName.isNotEmpty
                        ? propertyName[0].toUpperCase()
                        : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propertyName,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        propertyType,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Options icon (three dots)
                const Icon(Icons.more_vert),
              ],
            ),
          ),
          Image.network(
            imageUrl,
            height: 200.0,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200.0,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      size: 50, color: Colors.grey),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  contractDuration,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14.0,
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

class MyPropertyScreen extends StatefulWidget {
  const MyPropertyScreen({super.key});

  @override
  State<MyPropertyScreen> createState() => _MyPropertyScreenState();
}

class _MyPropertyScreenState extends State<MyPropertyScreen> {
  // --- State for Firebase Backend ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger logger = Logger();
  String? _accountType;
  String? _fullName;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- State for Listings ---
  Stream<QuerySnapshot>? _listingsStream;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser; // Get current user
    _loadUserInfo();
    _auth.authStateChanges().listen((user) {
      _currentUser = user; // Update current user reference
      _loadUserInfo(); // Reload user info on auth state change
      _setupListingsStream(); // Reset listings stream on auth change
      if (mounted) {
        setState(() {}); // Update UI on auth change
      }
    });
    _setupListingsStream(); // Setup the stream to fetch properties
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _accountType = prefs.getString("accountType");
        _fullName = prefs.getString("fullName");
      });
    }
  }

  // --- Method to setup Firestore stream ---
  void _setupListingsStream() {
    if (_currentUser != null) {
      setState(() {
        _listingsStream = _db
            .collection('listings')
            .where('uid', isEqualTo: _currentUser!.uid)
            .snapshots(); // Listen for real-time updates
      });
    } else {
      // Clear the stream if user logs out
      setState(() => _listingsStream = null);
    }
  }

  void _navigateToAddEditScreen({bool isNew = true, String? docId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingAddEditScreen(
          isNew: isNew,
          docId: docId, // Pass docId if editing
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFECE6F0),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const Text(
                  'My Property',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.black87),
                  onPressed: () => _navigateToAddEditScreen(isNew: true),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: buildMenu(),
      body: _currentUser == null
          ? const Center(child: Text("Please log in to see your properties."))
          : StreamBuilder<QuerySnapshot>(
              stream: _listingsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  logger.e("Listings StreamBuilder Error",
                      error: snapshot.error, stackTrace: snapshot.stackTrace);
                  return Center(
                      child:
                          Text('Error loading properties: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('You have not added any properties yet.'));
                }

                // Data is available
                final documents = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    // Get data from document
                    final listing =
                        mapFirestoreDocumentToForRent(documents[index]);
                    final String docId = documents[index].id;

                    // If the listing has image URL, use it; otherwise use a placeholder
                    String imageUrl = listing.imageFilename.isNotEmpty
                        ? listing.imageFilename
                        : 'https://th.bing.com/th/id/R.b2236b714cb9cbd93b43232361faf9ec?rik=dBDMY41CcAh9Tw&riu=http%3a%2f%2f1.bp.blogspot.com%2f-3RlvnNEnq7A%2fUex8jPr7CeI%2fAAAAAAAAALA%2fqRA7a6VQ35E%2fs1600%2fAPARTMENT_WHITE_PERSPECTIVE%2bfor%2bFB.jpg&ehk=lQpkY%2fsndCrVdccrKHJlr0RPyVl7EU4AWWuYyPMV%2bmk%3d&risl=&pid=ImgRaw&r=0';

                    // Get property type string
                    String propertyType =
                        listing is Apartment ? 'Apartment' : 'Bedspace';

                    // Return the property card
                    return GestureDetector(
                      onTap: () =>
                          _navigateToAddEditScreen(isNew: false, docId: docId),
                      onLongPress: () =>
                          _showDeleteConfirmationDialog(listing.name, docId),
                      child: PropertyCard(
                        propertyName: listing.name.isNotEmpty
                            ? listing.name
                            : "Untitled Property",
                        propertyType: propertyType,
                        imageUrl: imageUrl,
                        price: '₱${listing.price.toStringAsFixed(0)} / Month',
                        contractDuration: '${listing.contract} month contract',
                        description: listing.otherDetails.isNotEmpty
                            ? listing.otherDetails
                            : 'No description available.',
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // --- buildMenu Method ---
  Widget buildMenu() {
    final User? currentUser = _auth.currentUser;
    final bool isLoggedIn = currentUser != null;

    return Drawer(
      child: Container(
        color: const Color(0xFFede9f3), // Light purple background
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                (_fullName ?? (isLoggedIn ? "User" : "Guest")) +
                    (_accountType != null
                        ? " (${_accountType?.capitalizeFirstLetter()})"
                        : ""),
              ),
              accountEmail: Text(currentUser?.email ?? "Not signed in"),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile (Not Implemented)')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text("Bookmarks"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Bookmarks (Not Implemented)')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text("My Properties"),
              selected: true,
              selectedTileColor: Colors.grey.withOpacity(0.2),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Settings (Not Implemented)')));
              },
            ),
            const Divider(),
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[700]),
                title:
                    Text('Log Out', style: TextStyle(color: Colors.red[700])),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _auth.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    await Future.wait([
                      prefs.remove("accountType"),
                      prefs.remove("fullName"),
                    ]);
                    logger.i("User logged out successfully.");
                  } catch (e, s) {
                    logger.e("Error logging out", error: e, stackTrace: s);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error logging out: $e')));
                  }
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Log In / Sign Up'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Login/Signup (Not Implemented)')));
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- Delete Confirmation Dialog ---
  void _showDeleteConfirmationDialog(String listingName, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete property?"),
          content: Text(
              "Are you sure you want to delete ${listingName.isNotEmpty ? listingName : 'this property'}?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                await _deleteListing(docId); // Call delete function
              },
            ),
          ],
        );
      },
    );
  }

  // --- Delete Listing Function ---
  Future<void> _deleteListing(String docId) async {
    try {
      await _db.collection('listings').doc(docId).delete();
      // TODO: Also delete associated image from Firebase Storage if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleted successfully")),
      );
    } catch (e) {
      logger.e("Error deleting listing $docId", error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting listing: $e")),
      );
    }
  }

  // --- Mapping Function ---
  ForRent mapFirestoreDocumentToForRent(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Document data is null for doc ID: ${doc.id}");
    }
    final type = data['type'] as String?;
    try {
      if (type == 'apartment') {
        return Apartment.fromJson(doc.id, data);
      } else if (type == 'bedspace') {
        return Bedspace.fromJson(doc.id, data);
      } else {
        logger.w("Unknown listing type '$type' for doc ID: ${doc.id}");
        throw Exception("Unknown listing type: $type");
      }
    } catch (e) {
      logger.e("Error parsing document ${doc.id}", error: e);
      rethrow;
    }
  }
}
