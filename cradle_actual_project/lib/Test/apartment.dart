// c:\Users\Christopher\Desktop\test\CRADLE_PROJECT\cradle_actual_project\lib\Test\apartment.dart

import 'for_rent.dart'; // <-- Correct import based on your filename

class Apartment extends ForRent {
  final int noOfBedrooms;
  final int noOfBathrooms;
  final int capacity;

  Apartment({
    // Use super parameters to forward directly to ForRent constructor
    required super.uid,
    required super.imageFilename,
    required super.name,
    required super.contactPerson,
    required super.contactNumber,
    required super.price,
    required super.billsIncluded,
    required super.address,
    super.curfew, // Optional parameters are forwarded too
    required super.contract,
    required super.latitude,
    required super.longitude,
    required super.otherDetails,
    super.rating, // Forward rating
    // Keep 'this.' for fields specific to Apartment
    required this.noOfBedrooms,
    required this.noOfBathrooms,
    required this.capacity,
  }); // No need for the ': super(...)' initializer list anymore for these parameters

  /// Factory constructor to create an Apartment from Firestore data (Map).
  factory Apartment.fromJson(String id, Map<String, dynamic> data) {
    return Apartment(
      uid: data['uid'] as String? ?? '', // Use uid from data, id is the doc ID
      imageFilename: data['_imageFilename'] as String? ?? '',
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
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0, // Parse rating
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

  /// Converts this Apartment object into a Map suitable for Firestore.
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson(); // Get common fields from ForRent
    json.addAll({
      'type': 'apartment', // Add the type identifier
      'noOfBedrooms': noOfBedrooms,
      'noOfBathrooms': noOfBathrooms,
      'capacity': capacity,
    });
    return json;
  }
}
