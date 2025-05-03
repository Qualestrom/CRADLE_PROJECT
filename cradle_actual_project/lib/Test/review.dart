import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class Review {
  final String id;
  final double rating;
  final String comment;
  final String? reviewerName; // Optional: Name of the reviewer
  final Timestamp? timestamp; // Optional: When the review was posted

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    this.reviewerName,
    this.timestamp,
  });

  // Factory constructor to create a Review from a Firestore document
  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Basic validation and default values
    double parsedRating = 0.0;
    if (data['rating'] is num) {
      parsedRating = (data['rating'] as num).toDouble();
    } else {
      _logger.w('Review ${doc.id} has invalid or missing rating field.');
    }

    return Review(
      id: doc.id,
      rating: parsedRating.clamp(0.0, 5.0), // Ensure rating is within 0-5
      comment: data['comment'] as String? ?? '', // Default to empty string
      reviewerName: data['reviewerName'] as String?, // Can be null
      timestamp: data['timestamp'] as Timestamp?, // Can be null
    );
  }
}
