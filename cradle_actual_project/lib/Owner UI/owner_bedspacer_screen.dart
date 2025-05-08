import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../Back-End/bedspace.dart'; // For Bedspace class and GenderPreference enum
import '../Back-End/firestore_mapper.dart';
import '../Back-End/listing_add_edit_fragment.dart'; // For navigation to edit screen
import '../Back-End/for_rent.dart'; // For ForRent class
import '../Menus/reviews_screen.dart'; // Import the ReviewsScreen

class BedspacerListing extends StatefulWidget {
  final String listingId;
  const BedspacerListing({super.key, required this.listingId});

  @override
  _BedspacerListingState createState() => _BedspacerListingState();
}

class _BedspacerListingState extends State<BedspacerListing> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  Bedspace? _bedspaceData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBedspaceDetails();
  }

  Future<void> _fetchBedspaceDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      DocumentSnapshot docSnapshot =
          await _db.collection('listings').doc(widget.listingId).get();
      if (mounted) {
        if (docSnapshot.exists) {
          ForRent forRentListing =
              await FirestoreMapper.mapDocumentToForRent(docSnapshot);
          if (forRentListing is Bedspace) {
            setState(() {
              _bedspaceData = forRentListing;
              _isLoading = false;
            });
          } else {
            throw Exception("Listing is not a Bedspace type.");
          }
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

  // Function to show the Reviews modal
  void _showReviewsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReviewsScreen(
            listingId: widget.listingId,
            listingName: _bedspaceData?.name ?? "Bedspace");
      },
    );
  }

  void _editBedspacerDetails() {
    if (_bedspaceData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ListingAddEditScreen(isNew: false, docId: widget.listingId),
        ),
      ).then((_) => _fetchBedspaceDetails()); // Refresh data after edit
    }
  }

  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    double halfStar = rating - fullStars;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: 24));
      } else if (i == fullStars && halfStar >= 0.5) {
        stars.add(Icon(Icons.star_half, color: Colors.amber, size: 24));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.amber, size: 24));
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

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
              color: Colors.grey[600],
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Bedspace...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _bedspaceData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error ?? 'Bedspace data could not be loaded.',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final bedspace = _bedspaceData!;

    // Helper to get display string for GenderPreference
    String getGenderDisplayString(GenderPreference gender) {
      switch (gender) {
        case GenderPreference.any:
          return 'Any Gender';
        case GenderPreference.maleOnly:
          return 'Male Only';
        case GenderPreference.femaleOnly:
          return 'Female Only';
        // Fallback
      }
    }

    // Update bill inclusion based on fetched data
    bool isWaterIncluded = bedspace.billsIncluded.contains('Water');
    bool isElectricityIncluded = bedspace.billsIncluded.contains('Electricity');
    bool isWifiIncluded = bedspace.billsIncluded.contains('Internet');
    bool isLpgIncluded = bedspace.billsIncluded.contains('Lpg');
    String gender = getGenderDisplayString(bedspace.gender);
    String curfew = bedspace.curfew ?? 'Not specified';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            Text(bedspace.name.isNotEmpty ? bedspace.name : 'Bedspace Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 200,
              child: (bedspace.imageDownloadUrl?.isNotEmpty ?? false)
                  ? Image.network(
                      bedspace.imageDownloadUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child:
                            const Center(child: Text('Could not load image')),
                      ),
                    )
                  : Container(
                      // Placeholder if no image URL
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                          child: Icon(Icons.king_bed,
                              size: 50, color: Colors.white)),
                    ),
            ),
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
                              bedspace.name,
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
                                    bedspace.address,
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
                                  // Removed _owner placeholder
                                  bedspace
                                      .contactPerson, // Use bedspace's contactPerson
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
                        // Column to stack remaining capacity text and circle
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
                                bedspace.roommateCount
                                    .toString(), // Use actual roommateCount
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF6750A4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text('Remaining\nCapacity',
                              textAlign: TextAlign
                                  .center, // _remainingCapacity will be replaced by bedspace.roommateCount
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
                          // _rating will be replaced by bedspace.rating
                          _buildStarRating(bedspace.rating),
                          const SizedBox(width: 8),
                          Text(
                            bedspace.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        // Wrap buttons in a Column
                        crossAxisAlignment: CrossAxisAlignment
                            .end, // Align buttons to the right
                        children: [
                          SizedBox(
                            // Added SizedBox for fixed width
                            width: 100, // Set a fixed width
                            child: OutlinedButton(
                              onPressed: () => _showReviewsModal(context),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF6750A4)),
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
                          ),
                          const SizedBox(
                              height: 8), // Add spacing between buttons
                          SizedBox(
                            // Added SizedBox for fixed width
                            width: 100, // Set the same fixed width
                            child: OutlinedButton(
                              // Added Edit button
                              onPressed:
                                  _editBedspacerDetails, // Placeholder edit function
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF6750A4)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(color: Color(0xFF6750A4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),

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
                          // _maxCapacity will be replaced by bedspace.roommateCount
                          '${bedspace.roommateCount} persons',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Bills Included
                  _buildDetailRow(
                    'Bills Included:',
                    Row(
                      // Changed from Wrap to Row for consistency with apartment screen
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Aligns items vertically
                      children: [
                        // Water
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop,
                                color: isWaterIncluded
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 25), // Matched size with apartment screen
                            const SizedBox(height: 4),
                            Text('Water',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isWaterIncluded
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
                                color: isElectricityIncluded
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 25),
                            const SizedBox(height: 4),
                            Text('Electric',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isElectricityIncluded
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
                                color: isWifiIncluded
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 25),
                            const SizedBox(height: 4),
                            Text('Internet',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isWifiIncluded
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
                                color: isLpgIncluded
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 25),
                            const SizedBox(height: 4),
                            Text('LPG',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isLpgIncluded
                                        ? Colors.black
                                        : Colors.grey[600])),
                          ],
                        ),

                        if (!isWaterIncluded &&
                            !isElectricityIncluded &&
                            !isWifiIncluded &&
                            !isLpgIncluded)
                          const Text('None',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF757575))),
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
                          curfew,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Gender - Added to match the image
                  _buildDetailRow(
                    'Gender:',
                    Row(
                      children: [
                        const Icon(Icons.wc,
                            color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 8),
                        Text(
                          gender,
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
                          // _bathrooms will be replaced by bedspace.bathroomShareCount
                          '${bedspace.bathroomShareCount} shared bathrooms',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
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
                            bedspace.price.toStringAsFixed(
                                2), // _monthlyRate will be replaced by bedspace.price
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
                        bedspace.contract > 0
                            ? '${bedspace.contract}-year contract'
                            : 'No contract', // Changed month to year
                        // _contractLength will be replaced by bedspace.contract
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  // Removed the call button container
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
