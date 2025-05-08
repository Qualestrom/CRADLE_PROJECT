import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Back-End/bedspace.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Menus/reviews_screen.dart'; // Import the new ReviewsScreen

class BedspacerListing extends StatefulWidget {
  final String listingId;

  const BedspacerListing({
    super.key,
    required this.listingId,
  });

  @override
  _BedspacerListingState createState() => _BedspacerListingState();
}

class _BedspacerListingState extends State<BedspacerListing> {
  // --- State Variables for Data Fetching ---
  Bedspace? _bedspaceData;
  bool _isLoading = true;
  String? _error;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _fetchBedspaceDetails();
  }

  /// Fetches bedspace details from Firestore based on the listingId.
  Future<void> _fetchBedspaceDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('listings') // Use your actual collection name
          .doc(widget.listingId)
          .get();

      if (mounted) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data is Map<String, dynamic>) {
            // Use Bedspace.fromJson
            _bedspaceData = Bedspace.fromJson(docSnapshot.id, data);
          } else {
            _error = "Bedspace data is missing or corrupt.";
            _logger.w(
                "Document ${widget.listingId} exists but data is null or not a Map.");
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = "Bedspace listing not found.";
            _isLoading = false;
          });
        }
      }
    } catch (e, s) {
      _logger.e("Error fetching bedspace details for ID: ${widget.listingId}",
          error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _error = "Failed to load bedspace details. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  // Build star rating widget
  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    double halfStar = rating - fullStars;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, color: const Color(0xFF6750A4), size: 24));
      } else if (i == fullStars && halfStar >= 0.5) {
        stars.add(
            Icon(Icons.star_half, color: const Color(0xFF6750A4), size: 24));
      } else {
        stars.add(
            Icon(Icons.star_border, color: const Color(0xFF6750A4), size: 24));
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  // Build detail row widget
  Widget _buildDetailRow(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
      ),
    );
  }

  // Navigate to Reviews Screen
  void _showReviewsModal(BuildContext context) {
    if (_bedspaceData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsScreen(
            listingId: widget.listingId, listingName: _bedspaceData!.name),
      ),
    );
  }

  // Helper function to determine which bills are included
  Map<String, bool> _getBillsIncludedMap() {
    Map<String, bool> billsMap = {
      'Water': false,
      'Electric': false,
      'Internet': false,
      'LPG': false
    };

    if (_bedspaceData != null && _bedspaceData!.billsIncluded.isNotEmpty) {
      for (String bill in _bedspaceData!.billsIncluded) {
        if (bill.toLowerCase().contains('water')) billsMap['Water'] = true;
        if (bill.toLowerCase().contains('electric'))
          billsMap['Electric'] = true;
        if (bill.toLowerCase().contains('wifi') ||
            bill.toLowerCase().contains('internet'))
          billsMap['Internet'] = true;
        if (bill.toLowerCase().contains('lpg') ||
            bill.toLowerCase().contains('gas')) billsMap['LPG'] = true;
      }
    }

    return billsMap;
  }

  @override
  Widget build(BuildContext context) {
    // --- Handle Loading and Error States ---
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(
            title: const Text("Loading..."),
            backgroundColor: const Color(0xFF6750A4),
            foregroundColor: Colors.white,
          ),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _bedspaceData == null) {
      return Scaffold(
          appBar: AppBar(
            title: const Text("Error"),
            backgroundColor: const Color(0xFF6750A4),
            foregroundColor: Colors.white,
          ),
          body: Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error ?? 'Bedspace data could not be loaded.',
                textAlign: TextAlign.center),
          )));
    }

    // Get the bills included map
    final billsMap = _getBillsIncludedMap();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_bedspaceData!.name),
        centerTitle: true,
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container
            Container(
              width: double.infinity,
              height: 200,
              child: Image.network(
                _bedspaceData!.imageDownloadUrl != null &&
                        _bedspaceData!.imageDownloadUrl!.isNotEmpty
                    ? _bedspaceData!.imageDownloadUrl!
                    : 'https://via.placeholder.com/400x250?text=No+Image',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Could not load image')),
                ),
              ),
            ),

            // Header section with name, location, owner, and capacity
            Container(
              padding: const EdgeInsets.only(
                  top: 16, left: 16, right: 16, bottom: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _bedspaceData!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6750A4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _bedspaceData!.address,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  _bedspaceData!.contactPerson,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6750A4),
                                width: 2.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _bedspaceData!.roommateCount.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF6750A4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text('Total\nCapacity',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),

            // Ratings section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RATINGS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildStarRating(_bedspaceData!.rating),
                          const SizedBox(width: 8),
                          Text(
                            _bedspaceData!.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () => _showReviewsModal(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6750A4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Reviews',
                          style: TextStyle(color: Color(0xFF6750A4)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),

            // Details section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Max Capacity
                  _buildDetailRow(
                    'Max. Capacity',
                    Row(
                      children: [
                        const Icon(Icons.people,
                            color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 8),
                        Text(
                          '${_bedspaceData!.roommateCount} persons',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Bills Included
                  _buildDetailRow(
                    'Bills Included:',
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Water icon and text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop,
                                color: billsMap['Water']!
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 22),
                            const SizedBox(height: 4),
                            Text('Water',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: billsMap['Water']!
                                        ? Colors.black
                                        : Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Electricity
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt,
                                color: billsMap['Electric']!
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 22),
                            const SizedBox(height: 4),
                            Text('Electric',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: billsMap['Electric']!
                                        ? Colors.black
                                        : Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Internet
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi,
                                color: billsMap['Internet']!
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 22),
                            const SizedBox(height: 4),
                            Text('Internet',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: billsMap['Internet']!
                                        ? Colors.black
                                        : Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // LPG
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department,
                                color: billsMap['LPG']!
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 22),
                            const SizedBox(height: 4),
                            Text('LPG',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: billsMap['LPG']!
                                        ? Colors.black
                                        : Colors.grey[600])),
                          ],
                        ),

                        if (_bedspaceData!.billsIncluded.isEmpty)
                          Text('None',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),

                  // Curfew
                  _buildDetailRow(
                    'Curfew:',
                    Row(
                      children: [
                        const Icon(Icons.lock_clock,
                            color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 8),
                        Text(
                          _bedspaceData!.curfew != null &&
                                  _bedspaceData!.curfew!.isNotEmpty
                              ? _bedspaceData!.curfew!
                              : 'None',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Gender
                  _buildDetailRow(
                    'Gender:',
                    Row(
                      children: [
                        const Icon(Icons.wc,
                            color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 8),
                        Text(
                          _getGenderText(_bedspaceData!.gender),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Bathrooms
                  _buildDetailRow(
                    'Bathrooms:',
                    Row(
                      children: [
                        const Icon(Icons.bathroom_outlined,
                            color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 8),
                        Text(
                          '${_bedspaceData!.bathroomShareCount} shared bathrooms',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Other details if available
                  if (_bedspaceData!.otherDetails.isNotEmpty)
                    _buildDetailRow(
                      'Other Details:',
                      Text(
                        _bedspaceData!.otherDetails,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),

            // Price section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            '₱',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            _bedspaceData!.price.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '/ month',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _bedspaceData!.contract > 0
                            ? '${_bedspaceData!.contract}-year contract'
                            : 'No contract',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      final Uri phoneLaunchUri = Uri(
                        scheme: 'tel',
                        path: _bedspaceData!.contactNumber,
                      );
                      try {
                        if (await canLaunchUrl(phoneLaunchUri)) {
                          await launchUrl(phoneLaunchUri);
                        } else {
                          _logger.w('Could not launch $phoneLaunchUri');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Could not initiate phone call.')),
                            );
                          }
                        }
                      } catch (e) {
                        _logger.e('Error launching phone call', error: e);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error initiating phone call: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEADDFF),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Color(0xFF6750A4),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Helper to convert gender preference to display text
  String _getGenderText(GenderPreference gender) {
    switch (gender) {
      case GenderPreference.maleOnly:
        return '♂️ Male Only';
      case GenderPreference.femaleOnly:
        return '♀️ Female Only';
      case GenderPreference.any:
        return '⚥ Any Gender';
    }
  }
}
