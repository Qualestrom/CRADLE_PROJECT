// File: firestore_mapper.dart
// Description: This file contains a function to process Firestore QuerySnapshots
// into a list of ForRent objects (either Apartment or Bedspace). It includes error handling and logging.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'for_rent.dart';
import 'apartment.dart';
import 'bedspace.dart';
import 'package:logger/logger.dart'; // Import logger

// Initialize logger for this file
final logger = Logger();

/// Processes a Firestore QuerySnapshot to create a list of ForRent objects
/// (either Apartment or Bedspace).
List<ForRent> processFirestoreListings(QuerySnapshot snapshot) {
  List<ForRent> listings = [];

  for (DocumentSnapshot doc in snapshot.docs) {
    // Cast the data to the expected Map type
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      try {
        // Check for the distinguishing field
        if (data.containsKey('noOfBedrooms')) {
          // Use the Apartment's factory constructor
          listings.add(Apartment.fromJson(doc.id, data));
        } else {
          // Use the Bedspace's factory constructor
          listings.add(Bedspace.fromJson(doc.id, data));
        }
      } catch (e) {
        // Log the error and potentially skip this document
        // Determine type for better error message if possible
        String type = data.containsKey('noOfBedrooms')
            ? 'Apartment'
            : 'Bedspace'; // Keep type determination
        logger.e("Error processing document ${doc.id} as $type",
            error: e); // Use logger.e for errors
        // Optionally log data at debug level if needed for troubleshooting
        // logger.d("Data causing error for ${doc.id}: $data");
      }
    } else {
      logger.w(
          "Document ${doc.id} has null data."); // Use logger.w for warnings like null data
    }
  }
  return listings;
}

// --- Optional: More functional approach using map ---
/*
List<ForRent> processFirestoreListingsFunctional(QuerySnapshot snapshot) {
  return snapshot.docs
      .map((doc) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
           logger.w("Document ${doc.id} has null data in functional approach."); // Use logger.w
           return null; // Skip documents with null data
        }

        try {
          if (data.containsKey('noOfBedrooms')) {
            return Apartment.fromJson(doc.id, data);
          } else {
            return Bedspace.fromJson(doc.id, data);
          }
        } catch (e) {
          logger.e("Error processing document ${doc.id} in functional approach", error: e); // Use logger.e
          // Optionally log data at debug level
          // logger.d("Data causing error for ${doc.id} (functional): $data");
          return null; // Skip documents that cause errors during parsing
        }
      })
      .whereType<ForRent>() // Filter out any nulls that resulted from errors or null data
      .toList();
}
*/
