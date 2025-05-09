import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for account type fetching
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../Back-End/review.dart' as app_review;
import '../utils/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For SharedPreferences

class ReviewsScreen extends StatefulWidget {
  final String listingId;
  final String listingName;

  const ReviewsScreen(
      {super.key, required this.listingId, required this.listingName});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  final Logger _logger = Logger('ReviewsScreen');
  double _currentRating = 0; // For the "Add Review" dialog
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingAccountType = true;
  String? _currentUserAccountType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAccountType();
  }

  Future<void> _fetchCurrentUserAccountType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingAccountType = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accountType = prefs.getString('accountType');

      if (accountType == null) {
        // Fallback to Firestore if not in SharedPreferences
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          accountType = (userDoc.data() as Map<String, dynamic>)['accountType']
              as String?;
        }
      }
      if (mounted) {
        setState(() {
          _currentUserAccountType = accountType;
          _isLoadingAccountType = false;
        });
      }
    } catch (e) {
      _logger.severe("Error fetching current user account type", e);
      if (mounted) setState(() => _isLoadingAccountType = false);
    }
  }

  Future<void> _showAddReviewDialog() async {
    _currentRating = 0; // Reset rating for new dialog
    _commentController.clear();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add a review.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to update stars within the dialog
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Your Review'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rate "${widget.listingName}"',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _currentRating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFF4F378B),
                            size: 30,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _currentRating = (index + 1).toDouble();
                            });
                          },
                        );
                      }),
                    ),
                    if (_currentRating == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Please select a star rating.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Your Comment',
                        hintText: 'Share your experience...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your comment.';
                        }
                        if (value.trim().length < 10) {
                          return 'Comment must be at least 10 characters.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        bool ratingValid = _currentRating > 0;
                        if (_formKey.currentState!.validate() && ratingValid) {
                          setDialogState(() => _isSubmitting = true);
                          try {
                            await _reviewService.addReview(
                              listingId: widget.listingId,
                              rating: _currentRating,
                              comment: _commentController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Review submitted successfully!')),
                              );
                            }
                          } catch (e) {
                            _logger.severe('Failed to submit review', e);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to submit review: ${e.toString()}')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => _isSubmitting = false);
                            }
                          }
                        } else if (!ratingValid) {
                          // Manually add error for rating if not handled by validator
                          _formKey.currentState?.setState(() {
                            // This is a bit of a hack to show a rating error,
                            // ideally, rating would be part of the form.
                            // For simplicity, we show a snackbar or just rely on the visual cue.
                          });
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a star rating.')),
                          );
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Text('Submit'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildStarRating(double rating, {double size = 20}) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      stars.add(Icon(
        i < rating ? Icons.star : Icons.star_border,
        color: const Color(0xFF4F378B),
        size: size,
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  @override
  Widget build(BuildContext context) {
    // Using AnnotatedRegion for better control over system UI overlay
    return Scaffold(
      // backgroundColor: Colors.white, // This is already handled by the theme or Scaffold default
      backgroundColor: Colors.white, // Set the background color to white
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.only(
              top: 48.0,
              bottom: 10.0,
              left: 16.0,
              right: 16.0), // Increased top padding
          child: Container(
            decoration: BoxDecoration(
              color: const Color(
                  0xFFFEF7FF), // FIXED: Using the color scheme from design
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text('Property Reviews',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87)),
                  ),
                ),
                const SizedBox(
                    width: 48), // Placeholder for alignment if no actions
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<app_review.Review>>(
        stream: _reviewService.getReviewsForListing(widget.listingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            _logger.severe('Error fetching reviews stream', snapshot.error,
                snapshot.stackTrace);
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No reviews yet. Be the first to add one!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700])),
                      ],
                    )));
          }

          final reviews = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final dateFormatted = review.timestamp != null
                  ? DateFormat.yMMMd()
                      .add_jm()
                      .format(review.timestamp!.toDate())
                  : 'Date unknown';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            child: Text(review.reviewerName?.isNotEmpty == true
                                ? review.reviewerName![0].toUpperCase()
                                : 'A'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.reviewerName ?? 'Anonymous',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  dateFormatted,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          _buildStarRating(review.rating, size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review.comment,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5, // Improved line spacing for readability
                          color: Colors
                              .grey[850], // Slightly darker for better contrast
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isLoadingAccountType
          ? null // Don't show FAB while loading account type
          : (_currentUserAccountType == 'renter'
              ? FloatingActionButton.extended(
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Add Review'),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                )
              : null), // Don't show FAB if not a renter or type is unknown
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
