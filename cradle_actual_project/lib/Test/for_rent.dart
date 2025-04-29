// c:\Users\Christopher\Desktop\test\CRADLE_PROJECT\cradle_actual_project\lib\Test\forRent.dart

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
  });

  // Note: A base fromJson isn't strictly needed if only subclasses
  // are instantiated directly from Firestore data.
  // Subclasses will handle calling the super constructor.
}
