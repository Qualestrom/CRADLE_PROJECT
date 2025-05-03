import 'package:flutter/material.dart';
// Import Firestore if you plan to fetch data here
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the Bedspace model
import '../Test/bedspace.dart'; // This imports for_rent.dart implicitly
import 'package:logger/logger.dart'; // Import logger
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import '../utils/string_extensions.dart'; // Import the new extension file

class BedspacerListing extends StatefulWidget {
  final String listingId; // <-- 1. Declare the field to hold the ID

  const BedspacerListing({
    super.key,
    required this.listingId, // <-- 2. Add the required parameter to the constructor
  });

  @override
  _BedspacerListingState createState() => _BedspacerListingState();
}

class _BedspacerListingState extends State<BedspacerListing> {
  // --- State Variables for Data Fetching ---
  Bedspace? _bedspaceData; // Store fetched bedspace data
  bool _isLoading = true;
  String? _error;
  final Logger _logger = Logger(); // Initialize logger

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

  @override
  Widget build(BuildContext context) {
    // --- Handle Loading and Error States ---
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text("Loading...")),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _bedspaceData == null) {
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error ?? 'Bedspace data could not be loaded.',
                textAlign: TextAlign.center),
          )));
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        // Use fetched name
        title: Text(_bedspaceData!.name),
        centerTitle: true,
        backgroundColor: Color(0xFF6B5B95),
      ),
      body: SingleChildScrollView(
        // Added SingleChildScrollView for scrollability
        child: Padding(
          padding: EdgeInsets.all(16.0), // Adjusted padding for mobile
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                child: Column(
                  children: [
                    Image.network(
                      // Use fetched image URL, provide a fallback
                      _bedspaceData!.imageDownloadUrl != null &&
                              _bedspaceData!.imageDownloadUrl!.isNotEmpty
                          ? _bedspaceData!.imageDownloadUrl!
                          : 'https://via.placeholder.com/400x250?text=No+Image',
                      height: MediaQuery.of(context).size.height *
                          0.25, // Dynamically adjusted height
                      fit: BoxFit.cover,
                      width: double.infinity,
                      // Add error builder
                      errorBuilder: (context, error, stackTrace) => Container(
                          height: MediaQuery.of(context).size.height * 0.25,
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image,
                              color: Colors.grey[600], size: 50)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // Use fetched name
                                _bedspaceData!.name,
                                style: TextStyle(
                                  fontSize: 22, // Adjusted font size for mobile
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B5B95),
                                ),
                              ),
                              SizedBox(height: 5),
                              // Use fetched address
                              Text(_bedspaceData!.address,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14, // Adjusted font size
                                  )),
                              SizedBox(height: 5),
                              // Use fetched contact person
                              Text(_bedspaceData!.contactPerson,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14, // Adjusted font size
                                  )),
                              // Display Contact Number
                              SizedBox(height: 3),
                              Text(_bedspaceData!.contactNumber,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  )),
                            ],
                          ),
                          // Display roommate count (total capacity/slots for the bedspace)
                          Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                radius: 20,
                                child: Text(
                                  // Use fetched roommateCount (total slots)
                                  _bedspaceData!.roommateCount.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Color(0xFF6B5B95),
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              // Changed label
                              Text('Total\nBed Slots',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey[300]),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Display Rating
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                double rating = _bedspaceData!.rating;
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
                              Text(_bedspaceData!.rating.toStringAsFixed(1),
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
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        // Display Bedspace Details
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Use fetched data
                          _detailRow('Total Slots:',
                              '👥 ${_bedspaceData!.roommateCount} persons'),
                          _detailRow('Shared Bathrooms:',
                              '🚿 ${_bedspaceData!.bathroomShareCount}'),
                          // Use string interpolation for better readability
                          _detailRow('Gender Preference:',
                              '${_getGenderIcon(_bedspaceData!.gender)} ${_bedspaceData!.gender.name.capitalizeFirstLetter()}'),
                          _detailRow(
                              'Bills Included:',
                              _bedspaceData!.billsIncluded.isNotEmpty
                                  ? _bedspaceData!.billsIncluded.join(', ')
                                  : 'Not specified'),
                          _detailRow(
                              'Curfew:',
                              _bedspaceData!.curfew != null &&
                                      _bedspaceData!.curfew!.isNotEmpty
                                  ? '🕙 ${_bedspaceData!.curfew}'
                                  : 'None'),
                          if (_bedspaceData!.otherDetails.isNotEmpty)
                            _detailRow(
                                'Other Details:', _bedspaceData!.otherDetails),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey[300]),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // Use fetched price
                                '₱${_bedspaceData!.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 22, // Adjusted font size for mobile
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B5B95),
                                ),
                              ),
                              Text('/ month',
                                  style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                          // Use fetched contract info
                          Text(
                              (_bedspaceData!.contract) > 0
                                  ? '${_bedspaceData!.contract}-year contract'
                                  : 'No contract',
                              style: TextStyle(color: Colors.grey[700])),
                          // --- Add Call Button ---
                          IconButton(
                            icon: Icon(Icons.phone, color: Color(0xFF6B5B95)),
                            tooltip: 'Call ${_bedspaceData!.contactPerson}',
                            onPressed: () async {
                              final Uri phoneLaunchUri = Uri(
                                scheme: 'tel',
                                path: _bedspaceData!.contactNumber,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            // Adjusted width for potentially longer labels
            width: 140,
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

  void _showModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Use fetched name
          title: Text('Reviews for ${_bedspaceData?.name ?? "Bedspace"}',
              style: TextStyle(color: Color(0xFF6B5B95))),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _review(
                    '★★★★★',
                    'Nice location, reasonable price. Close to public transportation and markets.',
                    '- Placeholder Reviewer 1'),
                _review(
                    '★★★☆☆',
                    'Decent bedspace. Bathrooms are clean but can get crowded during peak hours.',
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

  // Helper to get gender icon
  String _getGenderIcon(GenderPreference gender) {
    switch (gender) {
      case GenderPreference.maleOnly:
        return '♂️';
      case GenderPreference.femaleOnly:
        return '♀️';
      case GenderPreference.any:
        return '⚥';
    }
  }
}
