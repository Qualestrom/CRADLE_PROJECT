// File: firestore_mapper.dart
// Description: This file contains a function to process Firestore QuerySnapshots
// into a list of ForRent objects (either Apartment or Bedspace). It includes error handling and logging.
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'for_rent.dart';
import 'apartment.dart';
import 'bedspace.dart';
import 'package:logger/logger.dart'; // Import logger

// Initialize logger for this file
final _logger = Logger(); // Make it private to this file if not used elsewhere
final _storage = FirebaseStorage.instance; // Firebase Storage instance

// IMPORTANT: Define the correct path to your images in Firebase Storage.
// If your images are in a folder named "listing_images", it would be "listing_images/".
// If they are at the root, you can leave this as an empty string or handle it accordingly.
const String _firebaseStorageListingsPath = ""; // <<< --- REPLACE THIS

/// Processes a Firestore QuerySnapshot to create a list of ForRent objects
/// (either Apartment or Bedspace).
/// This function is now asynchronous as it fetches image download URLs.
Future<List<ForRent>> processFirestoreListings(QuerySnapshot snapshot) async {
  List<ForRent> listings = [];

  for (DocumentSnapshot doc in snapshot.docs) {
    // Cast the data to the expected Map type
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      // Create a mutable copy of the data to enrich it with the imageDownloadUrl
      Map<String, dynamic> enrichedData = Map.from(data);
      String? imageFilename = data['imageFilename'] as String?;

      if (imageFilename != null && imageFilename.isNotEmpty) {
        try {
          final String downloadUrl = await _storage
              .ref('$_firebaseStorageListingsPath$imageFilename')
              .getDownloadURL();
          enrichedData['imageDownloadUrl'] = downloadUrl;
        } catch (e) {
          _logger.e(
              "Error getting download URL for $imageFilename (doc ID: ${doc.id})",
              error: e);
          enrichedData['imageDownloadUrl'] =
              null; // Ensure it's null if fetch fails
        }
      } else {
        enrichedData['imageDownloadUrl'] = null;
      }

      try {
        // Check for the distinguishing field
        if (enrichedData.containsKey('noOfBedrooms')) {
          // Check enrichedData
          // Use the Apartment's factory constructor
          listings.add(Apartment.fromJson(doc.id, enrichedData));
        } else {
          // Use the Bedspace's factory constructor
          listings.add(Bedspace.fromJson(doc.id, enrichedData));
        }
      } catch (e) {
        // Log the error and potentially skip this document
        // Determine type for better error message if possible
        String type = data.containsKey('noOfBedrooms')
            ? 'Apartment'
            : 'Bedspace'; // Keep type determination
        _logger.e("Error creating object for document ${doc.id} as $type",
            error: e); // Use logger.e for errors
        // Optionally log data at debug level if needed for troubleshooting
        // _logger.d("Data causing error for ${doc.id}: $enrichedData");
      }
    } else {
      _logger.w("Document ${doc.id} has null data.");
    }
  }
  return listings;
}

// --- Optional: More functional approach using map ---
/*
Future<List<ForRent>> processFirestoreListingsFunctional(QuerySnapshot snapshot) async {
  List<Future<ForRent?>> futureListings = snapshot.docs.map((doc) async {
    try {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
           _logger.w("Document ${doc.id} has null data in functional approach.");
           return null; // Skip documents with null data
        }

        Map<String, dynamic> enrichedData = Map.from(data);
        String? imageFilename = data['_imageFilename'] as String?;

        if (imageFilename != null && imageFilename.isNotEmpty) {
          try {
            final String downloadUrl = await _storage.ref('$_firebaseStorageListingsPath$imageFilename').getDownloadURL();
            enrichedData['imageDownloadUrl'] = downloadUrl;
          } catch (e) {
            _logger.e("Error getting download URL for $imageFilename (doc ID: ${doc.id}) in functional", error: e);
            enrichedData['imageDownloadUrl'] = null;
          }
        } else {
          enrichedData['imageDownloadUrl'] = null;
        }

        if (enrichedData.containsKey('noOfBedrooms')) {
          return Apartment.fromJson(doc.id, enrichedData);
        } else {
          return Bedspace.fromJson(doc.id, enrichedData);
        }
    } catch (e) {
      _logger.e("Error processing document ${doc.id} in functional approach", error: e);
      return null;
    }
  }).toList();
  final results = await Future.wait(futureListings);
  return results.whereType<ForRent>().toList();
}
*/
