/// Enum representing the sex of a person.
/// Re-defined here for clarity, or you could import from renter.dart if preferred.
enum Sex { male, female, other, preferNotToSay } // Added preferNotToSay

/// Represents a property owner.
class Owner {
  /// The unique ID of the owner (often linked to Firebase Auth UID).
  final String uid;

  /// The full name of the owner.
  final String name;

  /// The age of the owner.
  final int age;

  /// The sex of the owner.
  final Sex sex;

  /// The contact phone number of the owner.
  final String phoneNumber;

  /// The link to the owner's Facebook profile (optional).
  final String? facebookLink;

  /// The URL or storage path for the owner's proof of valid ID.
  final String? validIdUrl; // Stores URL/path from Firebase Storage

  /// The URL or storage path for the owner's property certificate.
  final String? propertyCertificateUrl; // Stores URL/path from Firebase Storage

  /// Flag indicating if the owner's valid ID has been verified by an admin.
  final bool isIdVerified;

  /// Flag indicating if the owner's property certificate has been verified by an admin.
  final bool isCertificateVerified;

  /// Creates an instance of [Owner].
  Owner({
    required this.uid,
    required this.name,
    required this.age,
    required this.sex,
    required this.phoneNumber,
    this.facebookLink,
    this.validIdUrl,
    this.propertyCertificateUrl,
    this.isIdVerified = false, // Default to false
    this.isCertificateVerified = false, // Default to false
  });

  /// Factory constructor to create an Owner from Firestore data (Map).
  factory Owner.fromJson(String uid, Map<String, dynamic> data) {
    return Owner(
      uid: uid, // Use the document ID as the uid
      name: data['name'] as String? ?? '',
      age: data['age'] as int? ?? 0,
      sex: _parseSex(data['sex']), // Helper function to parse enum
      phoneNumber: data['phoneNumber'] as String? ?? '',
      facebookLink: data['facebookLink'] as String?, // Optional
      validIdUrl: data['validIdUrl'] as String?, // Optional
      propertyCertificateUrl:
          data['propertyCertificateUrl'] as String?, // Optional
      isIdVerified:
          data['isIdVerified'] as bool? ?? false, // Default to false if missing
      isCertificateVerified: data['isCertificateVerified'] as bool? ??
          false, // Default to false if missing
    );
  }

  /// Converts this Owner object into a Map suitable for Firestore.
  Map<String, dynamic> toJson() {
    return {
      // Don't usually store uid inside the document itself if doc ID is the uid
      'name': name,
      'age': age,
      'sex': sex.name, // Store enum name as string (e.g., 'female')
      'phoneNumber': phoneNumber,
      if (facebookLink != null) 'facebookLink': facebookLink,
      if (validIdUrl != null) 'validIdUrl': validIdUrl,
      if (propertyCertificateUrl != null)
        'propertyCertificateUrl': propertyCertificateUrl,
      'isIdVerified': isIdVerified,
      'isCertificateVerified': isCertificateVerified,
      // Consider adding a timestamp for creation/update
      // 'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Helper function to parse sex from Firestore data.
  static Sex _parseSex(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'male':
          return Sex.male;
        case 'female':
          return Sex.female;
        case 'other':
          return Sex.other;
        case 'prefernottosay': // Handle the added enum value
        case 'prefer_not_to_say':
          return Sex.preferNotToSay;
      }
    }
    // Return a default instead of throwing an error for robustness
    print(
        'Warning: Invalid or missing value for Sex: $value. Defaulting to preferNotToSay.'); // Or use logger
    return Sex.preferNotToSay;
  }
}
