// c:\Users\Christopher\Desktop\test\CRADLE_PROJECT\cradle_actual_project\lib\Test\fromJava.dart
// (Or the file containing your Firestore processing logic)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'for_rent.dart';
import 'apartment.dart'; // Now includes Apartment.fromJson
import 'bedspace.dart'; // Includes Bedspace.fromJson

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
        String type =
            data.containsKey('noOfBedrooms') ? 'Apartment' : 'Bedspace';
        print("Error processing document ${doc.id} as $type: $e");
        print("Data: $data"); // Print data for debugging any error
      }
    } else {
      print("Document ${doc.id} has null data.");
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
           print("Document ${doc.id} has null data.");
           return null; // Skip documents with null data
        }

        try {
          if (data.containsKey('noOfBedrooms')) {
            return Apartment.fromJson(doc.id, data);
          } else {
            return Bedspace.fromJson(doc.id, data);
          }
        } catch (e) {
          print("Error processing document ${doc.id}: $e");
          print("Data: $data");
          return null; // Skip documents that cause errors during parsing
        }
      })
      .whereType<ForRent>() // Filter out any nulls that resulted from errors or null data
      .toList();
}
*/
