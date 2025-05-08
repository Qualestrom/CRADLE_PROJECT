import 'package:flutter/material.dart';

class BedspacerListing extends StatefulWidget {
  const BedspacerListing({super.key});

  @override
  _BedspacerListingState createState() => _BedspacerListingState();
}

class _BedspacerListingState extends State<BedspacerListing> {
  // State variables for bedspacer details
  String _bedspacerName = 'ABC Bedspacer';
  String _location = 'Block X Lot X Universe 2 St.';
  String _owner = 'Juan Dela Cruz';
  int _remainingCapacity = 3;
  double _rating = 3.5;
  int _maxCapacity = 20;
  // ignore: unused_field
  final int _bathrooms = 2;
  double _monthlyRate = 1500.00;
  String _contractLength = '6-month contract';
  String _gender = 'Mixed';
  String _curfew = '11:59PM - 4:00AM';

  // State variables for included bills
  bool _isWaterIncluded = true;
  bool _isElectricityIncluded = true;
  bool _isWifiIncluded = true;
  bool _isLpgIncluded = false;

  // Placeholder data for reviews
  final List<Map<String, String>> _reviews = [
    {
      'stars': '★★★★☆',
      'text':
          'Clean and affordable place. Good internet connection. Can get a bit crowded during peak hours.',
      'author': '- Mark Tan',
    },
    {
      'stars': '★★★★★',
      'text':
          'Friendly housemates and accommodating owner. The location is very convenient for commuting.',
      'author': '- Sarah Lim',
    },
    {
      'stars': '★★★☆☆',
      'text':
          'Basic amenities are provided. The curfew is a bit early but understandable for security.',
      'author': '- David Lee',
    },
  ];

  // Function to show the Reviews modal
  void _showReviewsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReviewsModal(reviews: _reviews, bedspacerName: _bedspacerName);
      },
    );
  }

  // Placeholder function for the Edit button
  void _editBedspacerDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality not yet implemented.'),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    double halfStar = rating - fullStars;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, color: Colors.grey[400], size: 24));
      } else if (i == fullStars && halfStar >= 0.5) {
        stars.add(Icon(Icons.star_half, color: Colors.grey[400], size: 24));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.grey[400], size: 24));
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bedspacer Details'),
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
              child: Image.network(
                'https://th.bing.com/th/id/OIP.2n7-DyvF3U2b9bH0o9OxMAHaE8?w=540&h=360&rs=1&pid=ImgDetMain',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Could not load image')),
                ),
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
                              _bedspacerName,
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
                                    _location,
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
                                  _owner,
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
                                _remainingCapacity.toString(),
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
                              style:
                                  TextStyle(fontSize: 10, color: Colors.black54)),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          _buildStarRating(_rating),
                          const SizedBox(width: 8),
                          Text(
                            _rating.toString(),
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
                                side: const BorderSide(color: Color(0xFF6750A4)),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          '$_maxCapacity persons',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Bills Included
                  _buildDetailRow(
                    'Bills Included:',
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Water icon and text
                        if (_isWaterIncluded)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water_drop,
                                  color: const Color(0xFF6750A4), size: 22),
                              const SizedBox(height: 4),
                              const Text('Water',
                                  style: TextStyle(fontSize: 12, color: Colors.black)),
                            ],
                          ),
                        if (_isWaterIncluded) const SizedBox(width: 12),

                        // Electricity
                        if (_isElectricityIncluded)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt,
                                  color: const Color(0xFF6750A4), size: 22),
                              const SizedBox(height: 4),
                              const Text('Electric',
                                  style: TextStyle(fontSize: 12, color: Colors.black)),
                            ],
                          ),
                        if (_isElectricityIncluded) const SizedBox(width: 12),

                        // Internet
                        if (_isWifiIncluded)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi,
                                  color: const Color(0xFF6750A4), size: 22),
                              const SizedBox(height: 4),
                              const Text('Internet',
                                  style: TextStyle(fontSize: 12, color: Colors.black)),
                            ],
                          ),
                        if (_isWifiIncluded) const SizedBox(width: 12),

                        // LPG
                        if (_isLpgIncluded)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department,
                                  color: const Color(0xFF6750A4), size: 22),
                              const SizedBox(height: 4),
                              const Text('LPG',
                                  style: TextStyle(fontSize: 12, color: Colors.black)),
                            ],
                          ),

                        if (!_isWaterIncluded &&
                            !_isElectricityIncluded &&
                            !_isWifiIncluded &&
                            !_isLpgIncluded)
                          const Text('None',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
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
                          _curfew,
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
                        const Icon(Icons.wc, color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 8),
                        Text(
                          _gender,
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
                          '$_bathrooms bathrooms',
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
                            _monthlyRate.toStringAsFixed(2),
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
                        _contractLength,
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

// Reviews Modal Widget
class ReviewsModal extends StatelessWidget {
  final List<Map<String, String>> reviews;
  final String bedspacerName;

  const ReviewsModal(
      {super.key, required this.reviews, required this.bedspacerName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reviews for $bedspacerName',
          style: const TextStyle(color: Color(0xFF6750A4))),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: reviews.map((review) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['stars']!,
                    style: const TextStyle(color: Colors.amber, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review['text']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      review['author']!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  if (review != reviews.last) Divider(color: Colors.grey[300]),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light().copyWith(
      primaryColor: const Color(0xFF6750A4),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6750A4),
        secondary: Color(0xFFEADDFF),
      ),
    ),
    home: const BedspacerListing(),
  ));
}
