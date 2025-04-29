import 'package:cloud_firestore/cloud_firestore.dart';

// --- GenderPreference enum and parseGenderPreference function removed from here ---

class ForRent {
  final String uid;
  final String imageFilename;
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
  final String docId;

  ForRent({
    required this.uid,
    required this.imageFilename,
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
    required this.docId,
  });

  // Note: A base fromJson isn't strictly needed if only subclasses
  // are instantiated directly from Firestore data.
  // Subclasses will handle calling the super constructor.
}

ForRent mapFirestoreDocumentToForRent(DocumentSnapshot doc) {
  return ForRent(
    uid: doc['uid'] ?? '', // Ensure uid is not null
    contactPerson:
        doc['contactPerson'] ?? '', // Ensure contactPerson is not null
    contactNumber:
        doc['contactNumber'] ?? '', // Ensure contactNumber is not null
    name: doc['name'] ?? '', // Ensure name is not null
    billsIncluded: List<String>.from(doc['billsIncluded'] ?? []),
    latitude:
        (doc['latitude'] ?? 0.0).toDouble(), // Ensure latitude is not null
    longitude:
        (doc['longitude'] ?? 0.0).toDouble(), // Ensure longitude is not null
    address: doc['address'] ?? '', // Ensure address is not null
    price: (doc['price'] ?? 0.0).toDouble(), // Ensure price is not null
    imageFilename:
        doc['imageFilename'] ?? '', // Ensure imageFilename is not null
    curfew: doc['curfew'] ?? '', // Ensure curfew is not null
    contract: (doc['contract'] ?? 0).toInt(), // Ensure contract is not null
    otherDetails: doc['otherDetails'] ?? '', // Ensure otherDetails is not null
    docId: doc.id, // Assign Firestore document ID to docId
  );
}
