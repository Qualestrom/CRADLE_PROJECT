// Base class for rental properties.

class ForRent {
  final String uid;
  final String? ownerId;
  final String imageFilename;
  String? imageDownloadUrl; // Renamed field to store the download URL
  final String name;
  final String contactPerson;
  final String contactNumber;
  final double price;
  final List<String> billsIncluded;
  final String address;
  final String? curfew;
  final int contract;
  final double latitude;
  final double longitude;
  final String otherDetails;
  final double rating; // Added rating field
  // final String docId; // Removed: Document ID is typically handled outside the model.

  ForRent({
    required this.uid,
    this.ownerId,
    required this.imageFilename,
    this.imageDownloadUrl, // Renamed constructor parameter
    required this.name,
    required this.contactPerson,
    required this.contactNumber,
    required this.price,
    required this.billsIncluded,
    required this.address,
    this.curfew,
    required this.contract,
    required this.latitude,
    required this.longitude,
    required this.otherDetails,
    this.rating = 0.0, // Default rating to 0.0
    // required this.docId, // Removed
  });

  /// Converts this ForRent object into a Map suitable for Firestore.
  /// Subclasses should override this, call super.toJson(), and add their specific fields.
  Map<String, dynamic> toJson() {
    return {
      'uid': ownerId,
      'imageFilename':
          // Note: imageUrl is NOT typically stored back in Firestore
          imageFilename, // Ensure this field name matches Firestore
      'name': name,
      'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      'price': price,
      'billsIncluded': billsIncluded,
      'address': address,
      'curfew': curfew, // Can be null
      'contract': contract,
      'latitude': latitude,
      'longitude': longitude,
      'otherDetails': otherDetails,
      'rating': rating, // Add rating to JSON
      // 'docId' is not stored within the document data itself.
      // 'type' field will be added by subclasses in their toJson overrides.
    };
  }

  // Note: A base fromJson factory is generally not used directly.
  // Use the specific .fromJson factories in subclasses (Apartment, Bedspace)
  // after checking the 'type' field from Firestore data.
}
