import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../Back-End/bedspace.dart'; // For Bedspace class and GenderPreference enum
import '../Back-End/firestore_mapper.dart';
import '../Back-End/listing_add_edit_fragment.dart'; // For navigation to edit screen
import '../Back-End/for_rent.dart'; // For ForRent class
import '../Menus/reviews_screen.dart'; // Import the ReviewsScreen

const double _kBottomBarHeight =
    120.0; // Adjusted height for owner screen's bottom bar

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

  // --- Refresh Logic ---
  Future<void> _handleRefresh() async {
    if (mounted) {
      // Re-fetch data to ensure UI reflects any external changes
      await _fetchBedspaceDetails();
    }
    // You can return a Future.delayed if you want to ensure the indicator
    // is visible for a minimum duration.
    return;
  }

  Widget _buildDetailRow(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 110,
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8), // Adjusted padding
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

  // Helper to get display string for GenderPreference
  String _getGenderDisplayString(GenderPreference gender) {
    switch (gender) {
      case GenderPreference.any:
        return 'Any Gender';
      case GenderPreference.maleOnly:
        return 'Male Only';
      case GenderPreference.femaleOnly:
        return 'Female Only';
      // No default needed as GenderPreference enum should be exhaustive.
    }
  }

  Widget _buildBottomPriceBar(Bedspace bedspaceData) {
    return Container(
      height: _kBottomBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center content
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('₱',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  Text(
                    bedspaceData.price.toStringAsFixed(
                        2), // No decimal for owner view consistency
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/ month',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                bedspaceData.contract > 0
                    ? '${bedspaceData.contract}-year contract' // Assuming contract is in years
                    : 'No contract',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
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

    // Update bill inclusion based on fetched data
    bool isWaterIncluded = bedspace.billsIncluded.contains('Water');
    bool isElectricityIncluded = bedspace.billsIncluded.contains('Electricity');
    bool isWifiIncluded = bedspace.billsIncluded.contains('Internet');
    bool isLpgIncluded = bedspace.billsIncluded.contains('Lpg');
    String gender =
        _getGenderDisplayString(bedspace.gender); // Use the class method
    String curfew = bedspace.curfew ?? 'Not specified';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: _kBottomBarHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 300, // Matched renter screen image height
                    child: (bedspace.imageDownloadUrl?.isNotEmpty ?? false)
                        ? Image.network(
                            bedspace.imageDownloadUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Text('Could not load image')),
                            ),
                          )
                        : Container(
                            height: 300,
                            color: Colors.grey[300],
                            child: const Center(
                                child: Icon(Icons.king_bed,
                                    size: 60, color: Colors.white70)),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24), // Matched renter screen padding
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
                                      fontWeight: FontWeight
                                          .w900, // Matched renter screen font weight
                                      color: Color(0xFF6750A4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 16,
                                          color: const Color(
                                              0xFF49454F)), // Matched renter screen color
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          bedspace.address,
                                          style: TextStyle(
                                            color: const Color(
                                                0xFF49454F), // Matched renter screen color
                                            fontSize: 14,
                                            fontWeight: FontWeight
                                                .w500, // Matched renter screen font weight
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
                                          size: 16,
                                          color: const Color(
                                              0xFF49454F)), // Matched renter screen color
                                      const SizedBox(width: 4),
                                      Text(
                                        bedspace.contactPerson,
                                        style: TextStyle(
                                          color: const Color(
                                              0xFF49454F), // Matched renter screen color
                                          fontSize: 14,
                                          fontWeight: FontWeight
                                              .w500, // Matched renter screen font weight
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
                                      bedspace.roommateCount.toString(),
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
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(
                                            0xFF49454F))), // Matched renter screen color
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12), // Matched renter screen padding
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
                            Row(
                              // Keep Edit and Reviews buttons together
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: OutlinedButton(
                                    onPressed: () => _showReviewsModal(context),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xFF6750A4)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text('Reviews',
                                        style: TextStyle(
                                            color: Color(0xFF6750A4))),
                                  ),
                                ),
                                const SizedBox(
                                    width: 8), // Spacing between buttons
                                SizedBox(
                                  width: 100,
                                  child: OutlinedButton(
                                    onPressed: _editBedspacerDetails,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xFF6750A4)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text('Edit',
                                        style: TextStyle(
                                            color: Color(0xFF6750A4))),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12), // Matched renter screen padding
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
                                  color: Color(0xFF6750A4),
                                  size: 22), // Matched renter icon size
                              const SizedBox(width: 8),
                              Text(
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.water_drop,
                                      color: isWaterIncluded
                                          ? const Color(0xFF6750A4)
                                          : Colors.grey[600],
                                      size: 22), // Matched renter icon size
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
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt,
                                      color: isElectricityIncluded
                                          ? const Color(0xFF6750A4)
                                          : Colors.grey[600],
                                      size: 22), // Matched renter icon size
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
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wifi,
                                      color: isWifiIncluded
                                          ? const Color(0xFF6750A4)
                                          : Colors.grey[600],
                                      size: 22), // Matched renter icon size
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
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department,
                                      color: isLpgIncluded
                                          ? const Color(0xFF6750A4)
                                          : Colors.grey[600],
                                      size: 22), // Matched renter icon size
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
                                        fontSize: 14,
                                        color: Color(0xFF757575))),
                            ],
                          ),
                        ),

                        // Curfew
                        _buildDetailRow(
                          'Curfew:',
                          Row(
                            children: [
                              const Icon(Icons.lock_clock,
                                  color: Color(0xFF6750A4),
                                  size: 22), // Matched renter icon size
                              const SizedBox(width: 8),
                              Text(
                                curfew.isNotEmpty
                                    ? curfew
                                    : 'None', // Matched renter display for none
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
                                  color: Color(0xFF6750A4),
                                  size: 22), // Matched renter icon size
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
                                  color: Color(0xFF6750A4),
                                  size: 22), // Matched renter icon size
                              const SizedBox(width: 8),
                              Text(
                                '${bedspace.bathroomShareCount} shared bathrooms',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        if (bedspace.otherDetails
                            .isNotEmpty) // Show other details if available
                          _buildDetailRow(
                            'Other Details:',
                            Text(
                              bedspace.otherDetails,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Removed SizedBox for bottom padding as SingleChildScrollView has it
                ],
              ),
            ),
            // Positioned Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  8, // Status bar padding + extra
              left: 16,
              child: Material(
                color: Colors
                    .transparent, // Ensures InkWell splash is visible on transparent bg
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(24), // For circular splash
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.3), // Semi-transparent background
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new, // iOS-style back arrow
                      color: Colors.white, // White icon for contrast
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomPriceBar(bedspace),
            ),
          ],
        ),
      ),
    );
  }
}
