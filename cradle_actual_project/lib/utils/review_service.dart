import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../Back-End/review.dart' as app_review; // Aliased to avoid conflict

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('ReviewService');

  // Get reviews for a specific listing
  Stream<List<app_review.Review>> getReviewsForListing(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => app_review.Review.fromFirestore(doc))
            .toList();
      } catch (e, s) {
        _logger.severe('Error mapping reviews for listing $listingId', e, s);
        return [];
      }
    });
  }

  // Add a review for a specific listing
  Future<void> addReview({
    required String listingId,
    required double rating,
    required String comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to add a review.');
    }

    final reviewData = app_review.Review(
      id: '', // Firestore will generate this
      listingId: listingId,
      reviewerId: currentUser.uid,
      rating: rating,
      comment: comment,
      reviewerName: currentUser.displayName ??
          currentUser.email?.split('@')[0] ??
          'Anonymous',
      reviewerEmail: currentUser.email,
      timestamp:
          Timestamp.now(), // Or use FieldValue.serverTimestamp() in toMap
    );

    try {
      await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('reviews')
          .add(reviewData.toMap());
      _logger.info(
          'Review added for listing $listingId by user ${currentUser.uid}');
      // After adding a review, update the average rating for the listing
      await updateListingAverageRating(listingId);
    } catch (e, s) {
      _logger.severe('Error adding review for listing $listingId', e, s);
      rethrow;
    }
  }

  // Calculate and update the average rating for a listing
  Future<void> updateListingAverageRating(String listingId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        await _firestore
            .collection('listings')
            .doc(listingId)
            .update({'rating': 0.0, 'reviewCount': 0});
        return;
      }

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
      }
      double averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('listings').doc(listingId).update({
        'rating': averageRating,
        'reviewCount': reviewsSnapshot.docs.length
      });
      _logger.info(
          'Updated average rating for listing $listingId to $averageRating');
    } catch (e, s) {
      _logger.severe(
          'Error updating average rating for listing $listingId', e, s);
      // Don't rethrow here, as it's a background update, but log it.
    }
  }
}
