// c:\Users\Christopher\Desktop\test\CRADLE_PROJECT\cradle_actual_project\lib\Test\bedspace.dart
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
    // Use super parameters to forward directly to ForRent constructor
    required super.uid,
    super.ownerId, // <-- Add this to accept and pass to ForRent
    super.imageDownloadUrl, // <-- Add this to accept and pass to ForRent
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
    // Keep 'this.' for fields specific to Bedspace
    required this.roommateCount,
    required this.bathroomShareCount,
    required this.gender, // Parameter type is GenderPreference
  }); // No need for the ': super(...)' initializer list anymore for these parameters

  /// Factory constructor to create a Bedspace from Firestore data (Map).
  /// (Keeping this here as it was added in the previous step, uses the local enum/parser)
  factory Bedspace.fromJson(String id, Map<String, dynamic> data) {
    // Use the helper function defined in this file
    GenderPreference genderValue = parseGenderPreference(data['gender']);

    return Bedspace(
      uid: id, // Use the document ID passed as 'id'
      ownerId:
          data['uid'] as String? ?? '', // <-- Read owner's ID from 'uid' field
      imageDownloadUrl:
          data['imageDownloadUrl'] as String?, // <-- Read from Firestore data
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
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0, // Parse rating
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

  /// Converts this Bedspace object into a Map suitable for Firestore.
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson(); // Get common fields from ForRent
    json.addAll({
      'type': 'bedspace', // Add the type identifier
      'roommateCount': roommateCount,
      'bathroomShareCount': bathroomShareCount,
      'gender': gender.name, // Store enum name as string (e.g., 'femaleOnly')
    });
    return json;
  }
}
