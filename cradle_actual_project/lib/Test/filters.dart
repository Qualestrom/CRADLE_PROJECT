import 'package:flutter/material.dart'; // Needed for RangeValues

// This file contains the definition of the Filters class, which is used to represent
// /// filtering options for listings in a real estate application. The class includes properties
class Filters {
  /// The type filter criteria ('apartment', 'bedspace'). Null if not specified.
  String? type;

  /// The curfew filter criteria (true=with curfew, false=no curfew). Null if not specified.
  /// Note: Firestore queries on null fields might require specific indexing or workarounds.
  /// Consider storing 'hasCurfew' as a boolean field instead of relying on the curfew string being null.
  bool? curfew;

  /// Gender preference filter (e.g., 'maleOnly', 'femaleOnly', 'any'). Null if not specified.
  String? gender; // Corresponds to GenderPreference enum values

  /// Street name filter. Null if not specified.
  String? street;

  /// Price range filter. Null if not specified.
  RangeValues? priceRange;

  /// The contract filter criteria (true=with contract, false=no contract). Null if not specified.
  bool? contract;

  /// Creates a new instance of [Filters].
  ///
  /// All parameters are optional and default to null.
  Filters({
    this.type,
    this.curfew,
    this.contract,
    this.gender,
    this.priceRange,
    this.street,
  });

  /// Creates a copy of this [Filters] instance but with the given fields
  /// replaced with the new values.
  Filters copyWith({
    // Use ValueGetter<String?>? to allow explicitly setting type to null
    // Although Dart's null-aware operators often make this less necessary
    String? type,
    bool? curfew,
    bool? contract,
    String? gender,
    String? street,
    RangeValues? priceRange,
  }) {
    return Filters(
      // Use the new value if provided, otherwise keep the current value.
      type: type ?? this.type,
      curfew: curfew ?? this.curfew,
      contract: contract ?? this.contract,
      gender: gender ?? this.gender,
      street: street ?? this.street,
      priceRange: priceRange ?? this.priceRange,
    );
  }

  /// Returns `true` if any filter criteria is currently active (not null).
  bool get isFiltering =>
      type != null ||
      curfew != null ||
      contract != null ||
      gender != null ||
      street != null ||
      priceRange != null;

  @override
  String toString() {
    return 'Filters{type: $type, curfew: $curfew, contract: $contract, gender: $gender, street: $street, priceRange: $priceRange}';
  }

  // Optional but recommended for value comparison:
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Filters &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          curfew == other.curfew &&
          contract == other.contract &&
          gender == other.gender &&
          street == other.street &&
          priceRange == other.priceRange;

  @override
  int get hashCode =>
      type.hashCode ^
      curfew.hashCode ^
      contract.hashCode ^
      gender.hashCode ^
      street.hashCode ^
      priceRange.hashCode;
}
