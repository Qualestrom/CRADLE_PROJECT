import 'package:flutter/material.dart';
// Imports needed for the shared menu logic
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:async'; // For async operations
// Import the string extension if needed by menu items (e.g., for capitalizing type)
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core

// Import models and helpers needed for listing display and navigation
import '../Test/for_rent.dart';
import '../Test/apartment.dart';
import '../Test/bedspace.dart';
import '../Test/listing_add_edit_fragment.dart'; // Screen for adding/editing

import '../utils/string_extensions.dart';

class PropertyCard extends StatelessWidget {
  final String propertyName;
  final String propertyType;
  final String imageUrl;
  final String price;
  final String contractDuration;
  final String description;

  const PropertyCard({
    Key? key,
    required this.propertyName,
    required this.propertyType,
    required this.imageUrl,
    required this.price,
    required this.contractDuration,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                    ),
                  ],
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
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
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
                  style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8.0),
                Text(description, style: const TextStyle(fontSize: 14.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Example usage in a Scaffold
class MyPropertyScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const MyPropertyScreen({Key? key}) : super(key: key);

  @override
  State<MyPropertyScreen> createState() => _MyPropertyScreenState();
}

class _MyPropertyScreenState extends State<MyPropertyScreen> {
  // State class
  // --- State for Menu (Copied from renter_home_screen.dart) ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db =
      FirebaseFirestore.instance; // Add Firestore instance
  final Logger logger = Logger();
  String? _accountType;
  String? _fullName;
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Key for drawer

  // --- State for Listings ---
  Stream<QuerySnapshot>? _listingsStream;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser; // Get current user
    _loadUserInfo();
    _auth.authStateChanges().listen((user) {
      _loadUserInfo(); // Reload user info on auth state change
      if (mounted) {
        setState(() {}); // Update drawer on auth change
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

  // --- Method to setup Firestore stream (from my_properties_fragment.dart) ---
  void _setupListingsStream() {
    if (_currentUser != null) {
      setState(() {
        _listingsStream = _db
            .collection('listings')
            .where('uid', isEqualTo: _currentUser!.uid)
            // .orderBy('dateCreated', descending: true) // Optional: Add if you have this field
            .snapshots(); // Listen for real-time updates
      });
    } else {
      // Handle case where user is not logged in (e.g., show login screen or message)
      logger.i("User not logged in, cannot fetch properties.");
      // Optionally clear the stream if user logs out
      setState(() => _listingsStream = null);
    }
  }
  // --- End State for Menu ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign key
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0.0,
        title: const Text('My Property', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Use the key to open the drawer
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: 'Add New Property',
            onPressed: () {
              // Navigate to the Add/Edit screen for a new listing
              _navigateToAddEditScreen(isNew: true);
            },
          ),
        ],
      ),
      drawer: buildMenu(), // Use the shared menu builder method
      // --- Replace hardcoded ListView with StreamBuilder ---
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
                  padding: const EdgeInsets.all(8.0), // Add some padding
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    // Build list item from document snapshot
                    return _buildListItem(context, documents[index]);
                  },
                );
              },
            ),
    );
  }

  // --- Method to navigate to Add/Edit Screen (from my_properties_fragment.dart) ---
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

  // --- buildMenu Method (Copied & Adapted from renter_home_screen.dart) ---
  Widget buildMenu() {
    final User? currentUser = _auth.currentUser;
    final bool isLoggedIn = currentUser != null;

    return Drawer(
      child: Container(
        color: const Color(0xFFede9f3), // Match renter home screen color
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Use UserAccountsDrawerHeader for a standard look
            UserAccountsDrawerHeader(
              accountName: Text(
                (_fullName ?? (isLoggedIn ? "User" : "Guest")) +
                    (_accountType != null
                        ? " (${_accountType?.capitalizeFirstLetter()})"
                        : ""), // Capitalize type
              ),
              accountEmail: Text(currentUser?.email ?? "Not signed in"),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor, // Use theme color
              ),
              // currentAccountPicture: CircleAvatar(
              //   // Add user image if available
              //   // backgroundImage: NetworkImage(currentUser?.photoURL ?? ''),
              // ),
            ),
            // --- Menu Items (Match renter_home_screen.dart structure) ---
            ListTile(
              // Profile Tile
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Profile Screen
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile (Not Implemented)')));
              },
            ),
            ListTile(
              // Bookmarks Tile (If applicable for Owner)
              leading: const Icon(Icons.bookmark_border),
              title: const Text("Bookmarks"), // Or maybe "Saved Searches"?
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Bookmarks/Saved Screen
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Bookmarks (Not Implemented)')));
              },
            ),
            ListTile(
              // My Properties Tile (Highlight if current screen)
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text("My Properties"),
              selected: true, // Highlight this item
              selectedTileColor:
                  Colors.grey.withOpacity(0.2), // Optional highlight color
              onTap: () {
                Navigator.pop(context); // Just close drawer if already here
              },
            ),
            ListTile(
              // Settings Tile
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Settings Screen
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Settings (Not Implemented)')));
              },
            ),
            const Divider(),
            if (isLoggedIn)
              ListTile(
                // Log Out Tile
                leading: Icon(Icons.logout, color: Colors.red[700]),
                title:
                    Text('Log Out', style: TextStyle(color: Colors.red[700])),
                onTap: () async {
                  Navigator.pop(context); // Close drawer first
                  try {
                    await _auth.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    await Future.wait([
                      prefs.remove("accountType"),
                      prefs.remove("fullName"),
                      // Remove other relevant user data from prefs
                    ]);
                    logger.i("User logged out successfully.");
                    // No need to call setState here, auth listener handles UI update
                    // TODO: Navigate to Login Screen after logout
                  } catch (e, s) {
                    logger.e("Error logging out", error: e, stackTrace: s);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error logging out: $e')));
                  }
                },
              )
            else
              ListTile(
                // Log In / Sign Up Tile
                leading: const Icon(Icons.login),
                title: const Text('Log In / Sign Up'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to your Login/Signup Screen
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Login/Signup (Not Implemented)')));
                },
              ),
          ],
        ),
      ),
    );
  }
  // --- End buildMenu Method ---

  // --- Method to build list item (adapted from my_properties_fragment.dart) ---
  // You can customize this to use your PropertyCard or keep it as ListTile
  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    final ForRent listing;
    try {
      // Use the mapping function (ensure it's accessible or defined here)
      listing = mapFirestoreDocumentToForRent(document);
    } catch (e) {
      logger.e("Error mapping document ${document.id}", error: e);
      return ListTile(
        title: Text("Error loading listing"),
        subtitle: Text(e.toString()),
        leading: Icon(Icons.error, color: Colors.red),
      );
    }
    final String docId = document.id; // Get the document ID

    // Using ListTile for simplicity, similar to my_properties_fragment.dart
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        // leading: CircleAvatar(...), // Add image loading if needed
        title:
            Text(listing.name.isNotEmpty ? listing.name : "Untitled Listing"),
        subtitle: Text(
          '₱${listing.price.toStringAsFixed(0)}/month - ${listing is Apartment ? 'Apartment' : 'Bedspace'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to edit screen
          _navigateToAddEditScreen(isNew: false, docId: docId);
        },
        onLongPress: () {
          // Show delete confirmation
          _showDeleteConfirmationDialog(listing.name, docId);
        },
      ),
    );
  }

  // --- Delete Confirmation Dialog (from my_properties_fragment.dart) ---
  void _showDeleteConfirmationDialog(String listingName, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete listing?"),
          content: Text(
              "Are you sure you want to delete ${listingName.isNotEmpty ? listingName : 'this listing'}?"),
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

  // --- Delete Listing Function (from my_properties_fragment.dart) ---
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

  // --- Mapping Function (ensure this is accessible) ---
  // You might move this to a separate file (like firestore_mapper.dart) and import it
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

Future<void> main() async {
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
      home: const MyPropertyScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
