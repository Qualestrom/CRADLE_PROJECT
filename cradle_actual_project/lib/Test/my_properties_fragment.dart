import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'dart:async'; // For StreamSubscription if not using StreamBuilder directly for listener management

// Assuming you have these files from previous context:
import 'for_rent.dart'; // Contains the ForRent model (needs fromJson)
import 'listing_add_edit_fragment.dart'; // The screen to navigate to for editing/adding
import 'apartment.dart'; // Needed if mapFirestoreDocumentToForRent uses it
import 'bedspace.dart'; // Needed if mapFirestoreDocumentToForRent uses it

// Initialize logger (you can configure levels, printers, etc.)
final logger = Logger();

// Helper function to determine the type and create the correct object
// This replaces the logic implicitly handled by separate fromJson in Java/previous Dart models
ForRent mapFirestoreDocumentToForRent(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>?;
  if (data == null) {
    // Handle error case appropriately, maybe throw an exception or return a default
    throw Exception("Document data is null for doc ID: ${doc.id}");
  }

  // Add the document ID to the data map before passing to fromJson
  // data['docId'] = doc.id; // Pass doc.id if needed by fromJson

  final type = data['type'] as String?;

  try {
    if (type == 'apartment') {
      // Use the specific fromJson factory for Apartment
      return Apartment.fromJson(doc.id, data);
    } else if (type == 'bedspace') {
      // Use the specific fromJson factory for Bedspace
      return Bedspace.fromJson(doc.id, data);
    } else {
      // Handle unknown type or fallback if necessary
      // Maybe throw an error or log a warning
      logger.w(
          "Unknown listing type '$type' for doc ID: ${doc.id}"); // Changed print to logger.w
      // You might need a default/base implementation or throw an error
      // For now, let's throw, assuming type should always be present and valid
      throw Exception("Unknown listing type: $type");
    }
  } catch (e) {
    logger.e("Error parsing document ${doc.id}",
        error: e); // Changed print to logger.e
    // Rethrow or handle gracefully
    rethrow;
  }
}

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  static const String routeName = '/my-properties'; // Example route name

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<QuerySnapshot>? _listingsStream;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _setupListingsStream();
  }

  void _setupListingsStream() {
    if (_currentUser != null) {
      setState(() {
        _listingsStream = _db
            .collection('listings')
            .where('uid', isEqualTo: _currentUser!.uid)
            // .orderBy('dateCreated', descending: true) // Add this if you have a dateCreated field
            .snapshots(); // Listen for real-time updates
      });
    } else {
      // Handle case where user is not logged in (e.g., show login screen)
      logger.i("User not logged in."); // Changed print to logger.i
      // Optionally navigate to login screen:
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Navigator.of(context).pushReplacementNamed('/login');
      // });
    }
  }

  Future<String?> _getImageUrl(String? imageFilename) async {
    if (imageFilename == null || imageFilename.isEmpty) {
      return null; // No image filename provided
    }
    try {
      return await _storage.ref().child(imageFilename).getDownloadURL();
    } catch (e) {
      // Handle errors, e.g., file not found
      logger.e("Error getting image URL for $imageFilename",
          error: e); // Changed print to logger.e
      return null; // Return null or a placeholder URL
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
    // Or using named routes if set up:
    // Navigator.pushNamed(
    //   context,
    //   ListingAddEditScreen.routeName,
    //   arguments: {'isNew': isNew, 'docId': docId},
    // );
  }

  // --- Adjusted _buildListItem to accept DocumentSnapshot ---
  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    final ForRent listing;
    try {
      listing = mapFirestoreDocumentToForRent(document);
    } catch (e) {
      // Handle parsing error for this specific item
      return ListTile(
        title: Text("Error loading listing"),
        subtitle: Text(e.toString()),
        leading: Icon(Icons.error, color: Colors.red),
      );
    }
    final String docId = document.id; // Get the document ID directly

    return FutureBuilder<String?>(
      future: _getImageUrl(listing.imageFilename),
      builder: (context, snapshot) {
        String? imageUrl = snapshot.data;
        ImageProvider? leadingImage = (imageUrl != null)
            ? NetworkImage(imageUrl)
            : null; // Or a placeholder AssetImage

        return Card(
          // Using Card for better visual separation
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: leadingImage,
              backgroundColor: Colors.grey[300], // Placeholder color
              child: leadingImage == null
                  ? const Icon(Icons.house,
                      color: Colors.white) // Placeholder icon
                  : null,
            ),
            title: Text(listing.name),
            subtitle: Text(
              '₱${listing.price.toStringAsFixed(0)}/month - ${listing.address}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _navigateToAddEditScreen(isNew: false, docId: docId);
            },
            onLongPress: () {
              // Now we pass the correct docId to the delete function
              _showDeleteConfirmationDialog(listing.name, docId);
            },
          ),
        );
      },
    );
  }

  // --- Adjusted Delete Confirmation to accept docId directly ---
  void _showDeleteConfirmationDialog(String listingName, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete listing?"),
          content: Text("Are you sure you want to delete $listingName?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                try {
                  await _db
                      .collection('listings')
                      .doc(docId)
                      .delete(); // Use the passed docId
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Deleted successfully")),
                  );
                } catch (e) {
                  logger.e("Error deleting listing $docId",
                      error: e); // Changed print to logger.e
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting listing: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Properties"),
        // No need for back button if pushed onto stack, it's usually automatic
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Listing',
            onPressed: () {
              _navigateToAddEditScreen(isNew: true);
            },
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(
              child: Text("Please log in.")) // Show message if not logged in
          : StreamBuilder<QuerySnapshot>(
              stream: _listingsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  logger.e("Listings StreamBuilder Error",
                      error: snapshot.error,
                      stackTrace:
                          snapshot.stackTrace); // Changed print to logger.e
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No properties found.'));
                }

                // Data is available
                final documents = snapshot.data!.docs;

                return ListView.builder(
                  // Add padding similar to DividerItemDecoration (adjust as needed)
                  padding: const EdgeInsets.all(8.0), // General padding
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    // Pass the DocumentSnapshot to the builder method
                    return _buildListItem(context, documents[index]);
                  },
                  // Or use ListView.separated for explicit dividers:
                  // separatorBuilder: (context, index) => Divider(height: 16, thickness: 0, color: Colors.transparent), // Adjust height for spacing
                );
              },
            ),
    );
  }
}
