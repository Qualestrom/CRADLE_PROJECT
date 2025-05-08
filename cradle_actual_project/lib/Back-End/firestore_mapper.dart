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

const String _firebaseStorageListingsPath = "";

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

class FirestoreMapper {
  static Future<ForRent> mapDocumentToForRent(DocumentSnapshot doc) async {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      _logger
          .e("Document ${doc.id} has null data. Cannot map to ForRent object.");
      // Consider throwing a more specific error or returning a default object
      // depending on how you want to handle missing data in BookmarksScreen.
      throw Exception("Document ${doc.id} data is null.");
    }

    Map<String, dynamic> enrichedData = Map.from(data);
    String? imageFilename = data['imageFilename'] as String?;

    // Ensure imageDownloadUrl is populated in enrichedData
    // Check if imageDownloadUrl is already present and valid, otherwise fetch it
    if (enrichedData['imageDownloadUrl'] == null ||
        (enrichedData['imageDownloadUrl'] is String &&
            (enrichedData['imageDownloadUrl'] as String).isEmpty)) {
      if (imageFilename != null && imageFilename.isNotEmpty) {
        try {
          final String downloadUrl = await _storage
              .ref(
                  '$_firebaseStorageListingsPath$imageFilename') // Ensure _firebaseStorageListingsPath is correct (e.g., 'listings/')
              .getDownloadURL();
          enrichedData['imageDownloadUrl'] = downloadUrl;
        } catch (e) {
          _logger.e(
              "Error getting download URL for $imageFilename (doc ID: ${doc.id}) in mapDocumentToForRent",
              error: e);
          enrichedData['imageDownloadUrl'] = null; // Set to null if fetch fails
        }
      } else {
        enrichedData['imageDownloadUrl'] = null; // No filename, so no URL
      }
    }

    try {
      // Use the same logic as processFirestoreListings to differentiate types
      if (enrichedData.containsKey('noOfBedrooms')) {
        return Apartment.fromJson(doc.id, enrichedData);
      } else {
        // Assumes if not an Apartment (by lacking 'noOfBedrooms'), it's a Bedspace.
        // This relies on 'noOfBedrooms' being exclusive to Apartments or Bedspace data not containing it.
        // A more robust solution might be a 'type' field in your Firestore documents.
        return Bedspace.fromJson(doc.id, enrichedData);
      }
    } catch (e, s) {
      // Log detailed error for easier debugging
      String typeAttempt =
          enrichedData.containsKey('noOfBedrooms') ? 'Apartment' : 'Bedspace';
      _logger.e(
          "Error creating $typeAttempt object for document ${doc.id} in mapDocumentToForRent",
          error: e,
          stackTrace: s);
      _logger.d("Data causing error for ${doc.id}: $enrichedData");
      // Re-throw to allow BookmarksScreen to handle the error (e.g., skip the item or show a message)
      throw Exception("Error mapping document ${doc.id} to $typeAttempt: $e");
    }
  }
}
