import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class Review {
  final String id;
  final String listingId; // ID of the listing this review is for
  final String reviewerId; // UID of the user who wrote the review
  final double rating;
  final String comment;
  final String? reviewerName; // Optional: Name of the reviewer
  final String? reviewerEmail; // Optional: Email of the reviewer
  final Timestamp? timestamp; // Optional: When the review was posted

  Review({
    required this.id,
    required this.listingId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    this.reviewerName,
    this.reviewerEmail,
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
    String? fetchedReviewerName = data['reviewerName'] as String?;
    // If reviewerName is not directly stored, try to construct from email if available
    if (fetchedReviewerName == null || fetchedReviewerName.isEmpty) {
      final email = data['reviewerEmail'] as String?;
      if (email != null && email.contains('@')) {
        fetchedReviewerName =
            email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
        // Basic capitalization for display
        fetchedReviewerName = fetchedReviewerName
            .split(' ')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '')
            .join(' ');
      } else {
        fetchedReviewerName = "Anonymous";
      }
    }
    return Review(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '', // Should always be present
      reviewerId:
          data['reviewerId'] as String? ?? '', // Should always be present
      rating: parsedRating.clamp(0.0, 5.0), // Ensure rating is within 0-5
      comment: data['comment'] as String? ?? '', // Default to empty string
      reviewerName: fetchedReviewerName,
      reviewerEmail: data['reviewerEmail'] as String?,
      timestamp: data['timestamp'] as Timestamp?, // Can be null
    );
  }
  // Method to convert a Review object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'reviewerId': reviewerId,
      'rating': rating,
      'comment': comment,
      'reviewerName': reviewerName, // This might be the user's display name
      'reviewerEmail': reviewerEmail, // User's email
      'timestamp': timestamp ??
          FieldValue.serverTimestamp(), // Use server timestamp if not provided
    };
  }
}
