import 'package:flutter/material.dart';
// Import Firestore and your Apartment model
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Test/apartment.dart'; // Adjust path if needed
import 'package:logger/logger.dart'; // Import logger
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

// Renamed widget to reflect its purpose
class ApartmentDetailsScreen extends StatefulWidget {
  final String listingId; // To receive the Apartment's uid

  const ApartmentDetailsScreen({
    super.key,
    required this.listingId, // Make it required
  });

  @override
  _ApartmentDetailsScreenState createState() => _ApartmentDetailsScreenState();
}

// Renamed state class
class _ApartmentDetailsScreenState extends State<ApartmentDetailsScreen> {
  // --- State Variables for Data Fetching ---
  Apartment? _apartmentData; // Store fetched apartment data
  bool _isLoading = true;
  String? _error;
  final Logger _logger = Logger(); // Initialize logger

  @override
  void initState() {
    super.initState();
    _fetchApartmentDetails();
  }

  /// Fetches apartment details from Firestore based on the listingId.
  Future<void> _fetchApartmentDetails() async {
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
          // Correctly call fromJson with id and data
          // Cast data() to the expected Map type
          final data = docSnapshot.data();
          if (data is Map<String, dynamic>) {
            // Check the type explicitly
            _apartmentData = Apartment.fromJson(docSnapshot.id, data);
          } else {
            // Handle case where data is null even if document exists
            _error = "Apartment data is missing or corrupt.";
            _logger.w("Document ${widget.listingId} exists but data is null.");
          }
          setState(() {
            _isLoading = false;
          });
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

  @override
  Widget build(BuildContext context) {
    // --- Handle Loading State ---
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text("Loading...")),
          body: const Center(child: CircularProgressIndicator()));
    }
    // --- Handle Error State ---
    if (_error != null || _apartmentData == null) {
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error ?? 'Apartment data could not be loaded.',
                textAlign: TextAlign.center),
          )));
    }

    // --- Placeholder UI (Needs to be updated with fetched data) ---
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        // Use fetched data for title
        title: Text(_apartmentData?.name ?? 'Apartment Details'),
        centerTitle: true,
        backgroundColor: Color(0xFF6B5B95),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0), // Adjusted padding for mobile size
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                // --- Start Example Card Content (Update with Apartment fields) ---
                child: Column(
                  children: [
                    Image.network(
                      // Use fetched image URL, provide a fallback
                      _apartmentData!.imageDownloadUrl != null &&
                              _apartmentData!.imageDownloadUrl!.isNotEmpty
                          ? _apartmentData!.imageDownloadUrl!
                          : 'https://via.placeholder.com/400x250?text=No+Image',
                      height: MediaQuery.of(context).size.height *
                          0.25, // Scalable image height
                      fit: BoxFit.cover,
                      width: double.infinity,
                      // Add error builder for robustness
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: MediaQuery.of(context).size.height * 0.25,
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image,
                            color: Colors.grey[600], size: 50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Use fetched data
                              Text(
                                _apartmentData!
                                    .name, // Use ! because we checked for null above
                                style: TextStyle(
                                  fontSize: 22, // Adjusted font size for mobile
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B5B95),
                                ),
                              ),
                              // Use fetched data
                              SizedBox(height: 5),
                              Text(_apartmentData!.address,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14, // Adjusted font size
                                  )),
                              SizedBox(height: 5),
                              // Use fetched contact person
                              Text(_apartmentData!.contactPerson,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12, // Adjusted font size
                                  )),
                              // Display Contact Number
                              SizedBox(height: 3),
                              Text(_apartmentData!.contactNumber,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  )),
                            ],
                          ),
                          // --- Example: Display number of rooms if available ---
                          // Adapt this section based on relevant Apartment info
                          Column(
                            children: [
                              if (_apartmentData!.noOfBedrooms > 0) ...[
                                CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  radius: 20,
                                  child: Text(
                                      _apartmentData!.noOfBedrooms.toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Color(0xFF6B5B95))),
                                ),
                                SizedBox(height: 5),
                                Text('Rooms',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 10)),
                              ]
                              // Add other relevant info like floor area if available
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey[300]),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // --- Display Apartment Rating ---
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                double rating = _apartmentData!.rating;
                                if (index < rating.floor()) {
                                  return const Icon(Icons.star,
                                      color: Color(0xFF6B5B95), size: 20);
                                }
                                if (index < rating.ceil() &&
                                    rating % 1 >= 0.5) {
                                  return const Icon(Icons.star_half,
                                      color: Color(0xFF6B5B95), size: 20);
                                }
                                return const Icon(Icons.star_border,
                                    color: Color(0xFF6B5B95), size: 20);
                              }),
                              SizedBox(width: 5),
                              Text(_apartmentData!.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                      color: Color(0xFF6B5B95), fontSize: 14)),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () => _showModal(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Color(0xFF6B5B95)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Reviews',
                              style: TextStyle(color: Color(0xFF6B5B95)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey[300]),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        // --- Display Apartment Details using _detailRow ---
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_apartmentData!.noOfBedrooms > 0)
                            _detailRow('Rooms:',
                                '🛏️ ${_apartmentData!.noOfBedrooms}'),
                          if (_apartmentData!.noOfBathrooms > 0)
                            _detailRow('Bathrooms:',
                                '🚿 ${_apartmentData!.noOfBathrooms}'), // Assuming numberOfBathrooms exists
                          if (_apartmentData!.capacity > 0)
                            _detailRow('Max. Capacity:',
                                '👥 ${_apartmentData!.capacity} persons'), // Display Capacity
                          _detailRow(
                              'Bills Included:',
                              _apartmentData!.billsIncluded.isNotEmpty
                                  ? _apartmentData!.billsIncluded.join(', ')
                                  : 'Not specified'),
                          _detailRow(
                              'Curfew:',
                              _apartmentData!.curfew != null &&
                                      _apartmentData!.curfew!.isNotEmpty
                                  ? '🕙 ${_apartmentData!.curfew}'
                                  : 'None'),
                          if (_apartmentData!.otherDetails.isNotEmpty)
                            _detailRow(
                                'Other Details:',
                                _apartmentData!
                                    .otherDetails), // Display Other Details
                          // Add other relevant apartment details (e.g., floor area, amenities)
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey[300]),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Use fetched data
                              Text(
                                '₱${_apartmentData!.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 22, // Adjusted font size
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B5B95),
                                ),
                              ),
                              Text('/ month',
                                  style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                          // Use fetched data
                          Text(
                              (_apartmentData!.contract) > 0
                                  ? '${_apartmentData!.contract}-year contract'
                                  : 'No contract',
                              style: TextStyle(color: Colors.grey[700])),
                          // --- Add Call Button ---
                          IconButton(
                            icon: Icon(Icons.phone, color: Color(0xFF6B5B95)),
                            tooltip: 'Call ${_apartmentData!.contactPerson}',
                            onPressed: () async {
                              final Uri phoneLaunchUri = Uri(
                                scheme: 'tel',
                                path: _apartmentData!.contactNumber,
                              );
                              try {
                                if (await canLaunchUrl(phoneLaunchUri)) {
                                  await launchUrl(phoneLaunchUri);
                                } else {
                                  _logger.w('Could not launch $phoneLaunchUri');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Could not initiate phone call.')),
                                  );
                                }
                              } catch (e) {
                                _logger.e('Error launching phone call',
                                    error: e);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error initiating phone call: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // --- End Example Card Content ---
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (Keep or adapt as needed) ---
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Color(0xFF6B5B95), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --- Update Modal to show Apartment Reviews (Placeholder) ---
  // Fetching actual reviews requires a separate Firestore query (likely on a 'reviews' subcollection)
  void _showModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Use fetched apartment name
          title: Text('Reviews for ${_apartmentData?.name ?? "Apartment"}',
              style: TextStyle(color: Color(0xFF6B5B95))),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _review(
                    '★★★★★',
                    'Nice location, reasonable price. Close to public transportation and markets.',
                    '- Placeholder Reviewer 1'),
                _review('★★★☆☆', 'Decent apartment. Clean and well-maintained.',
                    '- Placeholder Reviewer 2'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --- Review widget (structure is fine, content is placeholder) ---
  Widget _review(String rating, String text, String author) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rating, style: TextStyle(color: Color(0xFF6B5B95))),
          Text(text),
          Text(author, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }
}
