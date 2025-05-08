import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../Back-End/apartment.dart';
import '../Back-End/firestore_mapper.dart';
import '../Back-End/listing_add_edit_fragment.dart'; // For navigation to edit screen
import '../Menus/reviews_screen.dart'; // Assuming you might want to add reviews later
import '../Back-End/for_rent.dart'; // Assuming you might want to add for_rent later

class ApartmentListing extends StatefulWidget {
  final String listingId;

  const ApartmentListing({super.key, required this.listingId});

  @override
  _ApartmentListingState createState() => _ApartmentListingState();
}

class _ApartmentListingState extends State<ApartmentListing> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  Apartment? _apartmentData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchApartmentDetails();
  }

  Future<void> _fetchApartmentDetails() async {
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
          // Use FirestoreMapper to get the ForRent object, then cast
          ForRent forRentListing =
              await FirestoreMapper.mapDocumentToForRent(docSnapshot);
          if (forRentListing is Apartment) {
            setState(() {
              _apartmentData = forRentListing;
              _isLoading = false;
            });
          } else {
            throw Exception("Listing is not an Apartment type.");
          }
        } else {
          setState(() {
            _error = "Apartment listing not found.";
            _isLoading = false;
          });
        }
      }
    } catch (e, s) {
      _logger.e("Error fetching apartment details for ID: ${widget.listingId}",
          error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _error = "Failed to load apartment details. Please try again.";
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
            listingName: _apartmentData?.name ?? "Apartment");
      },
    );
  }

  void _onEditPressed() {
    if (_apartmentData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ListingAddEditScreen(isNew: false, docId: widget.listingId),
        ),
      ).then((_) => _fetchApartmentDetails()); // Refresh data after edit
    }
  }

  // Helper function to build star widgets based on rating
  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    double halfStar = rating - fullStars;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(
            Icon(Icons.star, color: Colors.amber, size: 24)); // Changed color
      } else if (i == fullStars && halfStar >= 0.5) {
        stars.add(Icon(Icons.star_half,
            color: Colors.amber, size: 24)); // Changed color
      } else {
        stars.add(Icon(Icons.star_border,
            color: Colors.amber, size: 24)); // Changed color
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  // Helper function to build detail rows with a label and content
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
        appBar: AppBar(title: const Text('Loading Apartment...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _apartmentData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error ?? 'Apartment data could not be loaded.',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // Data is loaded, use _apartmentData
    final apartment = _apartmentData!;
    // Update bill inclusion based on fetched data
    bool isWaterIncluded = apartment.billsIncluded.contains('Water');
    bool isElectricityIncluded =
        apartment.billsIncluded.contains('Electricity');
    bool isWifiIncluded = apartment.billsIncluded
        .contains('Internet'); // Assuming "Internet" is stored, not "WiFi"
    bool isLpgIncluded = apartment.billsIncluded
        .contains('Lpg'); // Assuming "Lpg" is stored, not "Gas"

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            apartment.name.isNotEmpty ? apartment.name : 'Apartment Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        // Optionally add an edit button here if preferred over the one in the body
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apartment image
            Container(
              width: double.infinity,
              height: 200,
              child: (apartment.imageDownloadUrl?.isNotEmpty ?? false)
                  ? Image.network(
                      apartment.imageDownloadUrl!,
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
                          child: Icon(Icons.apartment,
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
                              apartment.name,
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
                                    apartment.address,
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
                                  apartment
                                      .contactPerson, // Use apartment's contactPerson
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
                                apartment.capacity
                                    .toString(), // Use actual capacity
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
                                  .center, // _remainingCapacity will be replaced by apartment.capacity
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
                          // Star rating
                          _buildStarRating(apartment.rating),
                          const SizedBox(width: 8),
                          // Rating number
                          Text(
                            apartment.rating.toStringAsFixed(1),
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
                            // Wrap in SizedBox for fixed width
                            width: 100, // Set fixed width
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
                            // Wrap in SizedBox for fixed width
                            width: 100, // Set the same fixed width
                            child: OutlinedButton(
                              // Added Edit button
                              onPressed:
                                  _onEditPressed, // Placeholder edit function
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

                  _buildDetailRow(
                    'Max Capacity:',
                    Row(
                      children: [
                        const Icon(Icons.people,
                            color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 10),
                        Text(
                          '${apartment.capacity} persons', // _maxCapacity will be replaced by apartment.capacity
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
                        // Water
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop,
                                color: isWaterIncluded
                                    ? const Color(0xFF6750A4)
                                    : Colors.grey[600],
                                size: 25),
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
                          apartment.curfew ??
                              'Not specified', // Use actual curfew data
                          style: TextStyle(fontSize: 14),
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
                            color: Color(0xFF6750A4), size: 25), // Purple icon
                        const SizedBox(width: 8),
                        Text(
                          '${apartment.noOfBedrooms} bedrooms', // _bedrooms will be replaced by apartment.noOfBedrooms
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
                          '${apartment.noOfBathrooms} bathrooms', // _bathrooms will be replaced by apartment.noOfBathrooms
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
                            apartment.price.toStringAsFixed(
                                2), // _monthlyRate will be replaced by apartment.price
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
                        apartment.contract > 0
                            ? '${apartment.contract}-year contract'
                            : 'No contract',
                        // _contractLength will be replaced by apartment.contract
                        style: TextStyle(
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
