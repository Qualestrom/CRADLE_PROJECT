/// Enum representing the sex of a person.
enum Sex { male, female }

/// Represents a buyer, potentially a student renter.
class Renter {
  /// The full name of the buyer.
  final String name;

  /// The age of the buyer.
  final int age;

  /// The contact phone number of the buyer.
  final String phone;

  /// The name of the buyer's guardian.
  final String guardianName;

  /// The contact phone number of the buyer's guardian.
  final String guardianPhone;

  /// The permanent address of the buyer.
  final String permanentAddress;

  /// The sex of the buyer.
  final Sex sex; // Changed type from String to Sex

  /// Creates an instance of [Buyer].
  /// All fields are required.
  Renter({
    required this.name,
    required this.age,
    required this.phone,
    required this.guardianName,
    required this.guardianPhone,
    required this.permanentAddress,
    required this.sex, // Parameter type is now Sex
  });

  // No explicit getters needed!
  // Access directly:
  // var buyer = Buyer(..., sex: Sex.female);
  // print(buyer.name);
  // print(buyer.sex); // Output would be something like Sex.female
}
