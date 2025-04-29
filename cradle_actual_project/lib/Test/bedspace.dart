// c:\Users\Christopher\Desktop\test\CRADLE_PROJECT\cradle_actual_project\lib\Test\bedspace.dart

import 'package:flutter/foundation.dart'; // Keep or remove based on wider project context
import 'for_rent.dart';

// --- Define Enum and Helper Function specific to Bedspace here ---

/// Enum representing the gender preference for a rental space (Bedspace specific).
enum GenderPreference { any, maleOnly, femaleOnly }

/// Helper function to parse gender preference from Firestore data (Bedspace specific).
/// Handles potential int or string values.
GenderPreference parseGenderPreference(dynamic value) {
  if (value is int) {
    // Assumes 0=any, 1=maleOnly, 2=femaleOnly based on enum order
    if (value >= 0 && value < GenderPreference.values.length) {
      return GenderPreference.values[value];
    }
  } else if (value is String) {
    switch (value.toLowerCase()) {
      case 'maleonly':
      case 'male_only':
        return GenderPreference.maleOnly;
      case 'femaleonly':
      case 'female_only':
        return GenderPreference.femaleOnly;
      default:
        return GenderPreference.any;
    }
  }
  // Default if type is unexpected or value is invalid
  return GenderPreference.any;
}

// --- Bedspace Class Definition ---

class Bedspace extends ForRent {
  final int roommateCount;
  final int bathroomShareCount;
  // Use the GenderPreference enum defined above
  final GenderPreference gender;

  Bedspace({
    required String uid,
    required String imageFilename,
    required String name,
    required String contactPerson,
    required String contactNumber,
    required double price,
    required List<String> billsIncluded,
    required String address,
    String? curfew,
    required int contract,
    required double latitude,
    required double longitude,
    required String otherDetails,
    required this.roommateCount,
    required this.bathroomShareCount,
    required this.gender, // Parameter type is GenderPreference
  }) : super(
         uid: uid,
         imageFilename: imageFilename,
         name: name,
         contactPerson: contactPerson,
         contactNumber: contactNumber,
         price: price,
         billsIncluded: billsIncluded,
         address: address,
         curfew: curfew,
         contract: contract,
         latitude: latitude,
         longitude: longitude,
         otherDetails: otherDetails,
         docId: uid, // Assuming uid is used as the document ID
       );

  /// Factory constructor to create a Bedspace from Firestore data (Map).
  /// (Keeping this here as it was added in the previous step, uses the local enum/parser)
  factory Bedspace.fromJson(String id, Map<String, dynamic> data) {
    // Use the helper function defined in this file
    GenderPreference genderValue = parseGenderPreference(data['gender']);

    return Bedspace(
      uid: id, // Use the document ID passed in
      imageFilename: data['imageFilename'] as String? ?? '',
      name: data['name'] as String? ?? '',
      contactPerson: data['contactPerson'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      billsIncluded: List<String>.from(data['billsIncluded'] ?? []),
      address: data['address'] as String? ?? '',
      curfew: data['curfew'] as String?, // Handles null from Firestore
      contract: data['contract'] as int? ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      otherDetails: data['otherDetails'] as String? ?? '',
      // Bedspace specific fields
      roommateCount: data['roommateCount'] as int? ?? 0,
      bathroomShareCount: data['bathroomShareCount'] as int? ?? 0,
      gender: genderValue, // Assign the parsed enum value
    );
  }

  // No explicit getters needed. Access fields directly:
  // var bs = Bedspace(...);
  // print(bs.roommateCount);
  // print(bs.gender); // Output would be like GenderPreference.femaleOnly
}
