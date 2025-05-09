import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Back-End/apartment.dart';
import '../Back-End/firestore_mapper.dart'; // Import FirestoreMapper
import '../Menus/reviews_screen.dart'; // Import the new ReviewsScreen

const double _kBottomBarHeight = 120.0; // Height of the bottom price bar
const double _kTopBarHeight = 8.0; // Or your desired new height

class ApartmentListing extends StatefulWidget {
  final String listingId; // Added to receive the apartment ID

  const ApartmentListing({
    super.key,
    required this.listingId, // Make it required
  });

  @override
  _ApartmentListingState createState() => _ApartmentListingState();
}

class _ApartmentListingState extends State<ApartmentListing> {
  final Logger _logger = Logger();

  // --- Helper variables for UI display ---
  // These will be populated from Firestore data once fetched
  bool _isWaterIncluded = false;
  bool _isElectricityIncluded = false;
  bool _isWifiIncluded = false;
  bool _isLpgIncluded = false;

  @override
  void initState() {
    super.initState();
    // No initial fetch needed, StreamBuilder will handle it.
  }

  void _showReviewsModal(BuildContext context, String listingName) {
    // This will be called from within the StreamBuilder/FutureBuilder context
    // where apartmentData is available.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsScreen(
            listingId: widget.listingId, listingName: listingName),
      ),
    );
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
    // For a single document stream, setState is often enough to trigger
    // the StreamBuilder to re-evaluate and the FutureBuilder to re-run.
    if (mounted) {
      setState(() {});
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

  Widget _buildBottomPriceBar(Apartment apartmentData) {
    return Container(
      height: _kBottomBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    '₱',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    apartmentData.price.toStringAsFixed(2),
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
                apartmentData.contract > 0
                    ? '${apartmentData.contract}-year contract'
                    : 'No contract',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          _buildCallButton(apartmentData.contactNumber),
        ],
      ),
    );
  }

  Widget _buildCallButton(String contactNumber) {
    return GestureDetector(
      onTap: () async {
        final Uri phoneLaunchUri = Uri(
          scheme: 'tel',
          path: contactNumber,
        );
        try {
          if (await canLaunchUrl(phoneLaunchUri)) {
            await launchUrl(phoneLaunchUri);
          } else {
            _logger.w('Could not launch $phoneLaunchUri');
            if (mounted) {
              // Check if widget is still in the tree
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not initiate phone call.')),
              );
            }
          }
        } catch (e) {
          _logger.e('Error launching phone call', error: e);
          if (mounted) {
            // Check if widget is still in the tree
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error initiating phone call: $e')),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
              centerTitle: true,
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          _logger.e(
              "Error fetching apartment stream for ID: ${widget.listingId}",
              error: snapshot.error,
              stackTrace: snapshot.stackTrace);
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              centerTitle: true,
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
            ),
            body: Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
            )),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Not Found'),
              centerTitle: true,
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
            ),
            body: const Center(
                child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Apartment listing not found.',
                  textAlign: TextAlign.center),
            )),
          );
        }

        // Document exists, now use FutureBuilder to map it (for image URL)
        return FutureBuilder<Apartment>(
          future: FirestoreMapper.mapDocumentToForRent(snapshot.data!)
              .then((forRent) => forRent as Apartment), // Cast to Apartment
          builder: (context, apartmentSnapshot) {
            if (apartmentSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Processing...'),
                  centerTitle: true,
                  backgroundColor: const Color(0xFF6750A4),
                  foregroundColor: Colors.white,
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            if (apartmentSnapshot.hasError) {
              _logger.e(
                  "Error mapping apartment document for ID: ${widget.listingId}",
                  error: apartmentSnapshot.error);
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(
                    child: Text(
                        'Error loading details: ${apartmentSnapshot.error}')),
              );
            }
            if (!apartmentSnapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                    child: Text('Could not load apartment details.')),
              );
            }

            final Apartment apartmentData = apartmentSnapshot.data!;

            // Update utility inclusion flags based on the latest data
            _isWaterIncluded = apartmentData.billsIncluded.contains('Water');
            _isElectricityIncluded =
                apartmentData.billsIncluded.contains('Electricity');
            _isWifiIncluded = apartmentData.billsIncluded.contains('WiFi') ||
                apartmentData.billsIncluded.contains('Internet');
            _isLpgIncluded = apartmentData.billsIncluded.contains('LPG') ||
                apartmentData.billsIncluded.contains('Gas');

            return Scaffold(
                backgroundColor: Colors.white, // AppBar removed
                body: RefreshIndicator(
                  // Wrap Stack with RefreshIndicator
                  onRefresh: _handleRefresh,
                  child: Stack(
                    // Ensures the Stack fills the available space
                    fit: StackFit.expand,
                    // Use Stack for overlaying back button
                    children: [
                      // New White Container for Notification Back
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: MediaQuery.of(context).padding.top +
                              _kTopBarHeight, // Covers status bar + toolbar area
                          color: Colors.white,
                          // You could add a bottom border if desired:
                          // decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(
                            bottom:
                                _kBottomBarHeight), // Padding for the bottom bar
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Add top padding to push content below the new white bar
                          // THIS SizedBox pushes all content within the SingleChildScrollView down
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).padding.top +
                                    _kTopBarHeight),
                            Container(
                              width: double.infinity,
                              height: 300,
                              child: apartmentData.imageDownloadUrl != null &&
                                      apartmentData.imageDownloadUrl!.isNotEmpty
                                  ? Image.network(
                                      apartmentData.imageDownloadUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 300, // Match parent height
                                        color: Colors.grey[300],
                                        child: const Center(
                                            child:
                                                Text('Could not load image')),
                                      ),
                                    )
                                  : Image.network(
                                      'https://via.placeholder.com/400x250?text=No+Image',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 300, // Match parent height
                                        color: Colors.grey[300],
                                        child: const Center(
                                            child: Text(
                                                'Placeholder not available')),
                                      ),
                                    ),
                            ), // End of Image Container
                            // The rest of the content should be children of this Column
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 24),
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              apartmentData.name.isNotEmpty
                                                  ? apartmentData.name
                                                  : "Apartment Details",
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF6750A4),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on,
                                                    size: 16,
                                                    color: const Color(
                                                        0xFF49454F)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    apartmentData.address,
                                                    style: TextStyle(
                                                      color: const Color(
                                                          0xFF49454F),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                        0xFF49454F)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  apartmentData.contactPerson,
                                                  style: TextStyle(
                                                    color:
                                                        const Color(0xFF49454F),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
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
                                                (apartmentData.capacity)
                                                    .toString(),
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
                                                  color: Color(0xFF49454F))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey[300]),

                            // Ratings section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          _buildStarRating(
                                              apartmentData.rating),
                                          const SizedBox(width: 8),
                                          Text(
                                            apartmentData.rating.toStringAsFixed(
                                                1), // Use toStringAsFixed for consistency
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ReviewsScreen(
                                                        listingId:
                                                            widget.listingId,
                                                        listingName:
                                                            apartmentData.name),
                                              ));
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Color(0xFF6750A4)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                        ),
                                        child: const Text(
                                          'Reviews',
                                          style: TextStyle(
                                              color: Color(0xFF6750A4)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Details section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
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

                                  _buildDetailRow(
                                    'Max Capacity:',
                                    Row(
                                      children: [
                                        const Icon(Icons.people,
                                            color: Color(0xFF6750A4), size: 25),
                                        const SizedBox(width: 10),
                                        Text(
                                          '${apartmentData.capacity} persons',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Bills Included
                                  _buildDetailRow(
                                    'Bills Included:',
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Water
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.water_drop,
                                                color: _isWaterIncluded
                                                    ? const Color(0xFF6750A4)
                                                    : Colors.grey[600],
                                                size: 25),
                                            const SizedBox(height: 4),
                                            Text('Water',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: _isWaterIncluded
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
                                                color: _isElectricityIncluded
                                                    ? const Color(0xFF6750A4)
                                                    : Colors.grey[600],
                                                size: 25),
                                            const SizedBox(height: 4),
                                            Text('Electric',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        _isElectricityIncluded
                                                            ? Colors.black
                                                            : Colors
                                                                .grey[600])),
                                          ],
                                        ),
                                        const SizedBox(width: 12),

                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.wifi,
                                                color: _isWifiIncluded
                                                    ? const Color(0xFF6750A4)
                                                    : Colors.grey[600],
                                                size: 25),
                                            const SizedBox(height: 4),
                                            Text('Internet',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: _isWifiIncluded
                                                        ? Colors.black
                                                        : Colors.grey[600])),
                                          ],
                                        ),
                                        const SizedBox(width: 12),

                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.local_fire_department,
                                                color: _isLpgIncluded
                                                    ? const Color(0xFF6750A4)
                                                    : Colors.grey[600],
                                                size: 25),
                                            const SizedBox(height: 4),
                                            Text('LPG',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: _isLpgIncluded
                                                        ? Colors.black
                                                        : Colors.grey[600])),
                                          ],
                                        ),
                                        if (apartmentData.billsIncluded.isEmpty)
                                          Text('None',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600])),
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
                                          apartmentData.curfew != null &&
                                                  apartmentData
                                                      .curfew!.isNotEmpty
                                              ? apartmentData.curfew!
                                              : 'No curfew',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Bedrooms
                                  _buildDetailRow(
                                    'Bedrooms:',
                                    Row(
                                      children: [
                                        const Icon(Icons.bed,
                                            color: Color(0xFF6750A4), size: 25),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${apartmentData.noOfBedrooms} bedrooms',
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
                                          '${apartmentData.noOfBathrooms} bathrooms',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // The SizedBoxes for bottom padding inside the scrollable area are removed
                            // as the SingleChildScrollView now has bottom padding.
                          ], // This now correctly closes the children of the main Column
                        ), // End of SingleChildScrollView
                      ),
                      // Positioned Back Button
                      Positioned(
                        top: MediaQuery.of(context).padding.top +
                            32, // Status bar padding + extra
                        left: 16,
                        child: Material(
                          color: Colors
                              .transparent, // Ensures InkWell splash is visible on transparent bg
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                                24), // For circular splash
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(
                                    0.3), // Semi-transparent background
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                      // Positioned Bottom Price Bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomPriceBar(apartmentData),
                      ),
                    ],
                  ), // End of Stack (child of RefreshIndicator)
                )); // End of Scaffold
          }, // End of FutureBuilder builder
        ); // End of FutureBuilder
      }, // End of StreamBuilder builder
    );
  }
}
