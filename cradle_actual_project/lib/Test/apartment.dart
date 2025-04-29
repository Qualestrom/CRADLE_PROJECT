// c:\Users\Christopher\Desktop\test\CRADLE_PROJECT\cradle_actual_project\lib\Test\apartment.dart

import 'package:flutter/foundation.dart'; // Keep or remove based on wider project context
import 'for_rent.dart'; // <-- Correct import based on your filename

class Apartment extends ForRent {
  final int noOfBedrooms;
  final int noOfBathrooms;
  final int capacity;

  Apartment({
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
    required this.noOfBedrooms,
    required this.noOfBathrooms,
    required this.capacity,
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

  /// Factory constructor to create an Apartment from Firestore data (Map).
  factory Apartment.fromJson(String id, Map<String, dynamic> data) {
    return Apartment(
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
      // Apartment specific fields
      noOfBedrooms: data['noOfBedrooms'] as int? ?? 0,
      noOfBathrooms: data['noOfBathrooms'] as int? ?? 0,
      capacity: data['capacity'] as int? ?? 0,
    );
  }

  // No explicit getters needed. Access fields directly:
  // var apt = Apartment(...);
  // print(apt.noOfBedrooms);
  // print(apt.capacity);
}
