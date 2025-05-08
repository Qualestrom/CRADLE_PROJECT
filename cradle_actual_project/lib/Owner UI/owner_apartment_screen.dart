import 'package:flutter/material.dart';

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
    home: const ApartmentListing(),
  ));
}


class ApartmentListing extends StatefulWidget {
  const ApartmentListing({super.key});

  @override
  _ApartmentListingState createState() => _ApartmentListingState();
}

class _ApartmentListingState extends State<ApartmentListing> {
  // State variables for apartment details
  String _apartmentName = 'ABC Apartment';
  String _location = 'Block X Lot X Universe 2 St.';
  String _owner = 'Juan Dela Cruz';
  int _remainingCapacity = 5;
  double _rating = 4.5;
  int _maxCapacity = 5;
  int _bedrooms = 2;
  int _bathrooms = 2;
  double _monthlyRate = 2000.00;
  String _contractLength = '1-year contract';

  // State variables for included bills
  bool _isWaterIncluded = true;
  bool _isElectricityIncluded = true;
  bool _isWifiIncluded = true;
  bool _isLpgIncluded = true;

  // Placeholder data for reviews
  final List<Map<String, String>> _reviews = [
    {
      'stars': '★★★★★',
      'text':
          'Great location, clean and spacious rooms. The amenities are all working properly.',
      'author': '- Maria Santos',
    },
    {
      'stars': '★★★★☆',
      'text':
          'Nice apartment, good value for money. The location is convenient but can be noisy at night.',
      'author': '- John Garcia',
    },
    {
      'stars': '★★★★★',
      'text': 'Very accommodating landlord. The place is well-maintained and secure.',
      'author': '- Lisa Reyes',
    },
  ];

  // Function to show the Reviews modal
  void _showReviewsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReviewsModal(reviews: _reviews, apartmentName: _apartmentName);
      },
    );
  }

  // Placeholder function for the Edit button
  void _onEditPressed() {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit apartment details here...'),
        duration: Duration(seconds: 2),
      ),
    );
  }


  // Helper function to build star widgets based on rating
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Apartment Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apartment image
            Container(
              width: double.infinity,
              height: 200,
              child: Image.network(
                'https://th.bing.com/th/id/R.b2236b714cb9cbd93b43232361faf9ec?rik=dBDMY41CcAh9Tw&riu=http%3a%2f%2f1.bp.blogspot.com%2f-3RlvnNEnq7A%2fUex8jPr7CeI%2fAAAAAAAAALA%2fqRA7a6VQ35E%2fs1600%2fAPARTMENT_WHITE_PERSPECTIVE%2bfor%2bFB.jpg&ehk=lQpkY%2fsndCrVdccrKHJlr0RPyVl7EU4AWWuYyPMV%2bmk%3d&risl=&pid=ImgRaw&r=0',
                fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Could not load image')),
                ),
              ),
            ),


            Container(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 12),
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
                              _apartmentName,
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
                               style: TextStyle(fontSize: 10, color: Colors.black54)),
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
                          _buildStarRating(_rating),
                          const SizedBox(width: 8),
                          // Rating number
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
                      Column( // Wrap buttons in a Column
                        crossAxisAlignment: CrossAxisAlignment.end, // Align buttons to the right
                        children: [
                          SizedBox( // Wrap in SizedBox for fixed width
                            width: 100, // Set fixed width
                            child: OutlinedButton(
                              onPressed: () => _showReviewsModal(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF6750A4)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text(
                                'Reviews',
                                style: TextStyle(color: Color(0xFF6750A4)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8), // Add spacing between buttons
                          SizedBox( // Wrap in SizedBox for fixed width
                            width: 100, // Set the same fixed width
                            child: OutlinedButton(
                              // Added Edit button
                              onPressed: _onEditPressed, // Placeholder edit function
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF6750A4)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        const Icon(Icons.people, color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 10),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Water
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(Icons.water_drop,
                                 color: _isWaterIncluded ? const Color(0xFF6750A4) : Colors.grey[600],
                                 size: 25),
                             const SizedBox(height: 4),
                             Text('Water',
                                 style: TextStyle(fontSize: 12,
                                 color: _isWaterIncluded ? Colors.black : Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Electricity
                        Column(
                           mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(Icons.bolt,
                                 color: _isElectricityIncluded ? const Color(0xFF6750A4) : Colors.grey[600],
                                 size: 25),
                             const SizedBox(height: 4),
                             Text('Electric',
                                 style: TextStyle(fontSize: 12,
                                 color: _isElectricityIncluded ? Colors.black : Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Internet
                        Column(
                           mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(Icons.wifi,
                                 color: _isWifiIncluded ? const Color(0xFF6750A4) : Colors.grey[600],
                                 size: 25),
                             const SizedBox(height: 4),
                             Text('Internet',
                                 style: TextStyle(fontSize: 12,
                                 color: _isWifiIncluded ? Colors.black : Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // LPG
                        Column(
                           mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(Icons.local_fire_department,
                                 color: _isLpgIncluded ? const Color(0xFF6750A4) : Colors.grey[600],
                                 size: 25),
                             const SizedBox(height: 4),
                             Text('LPG',
                                 style: TextStyle(fontSize: 12,
                                 color: _isLpgIncluded ? Colors.black : Colors.grey[600])),
                          ],
                        ),

                          if (!_isWaterIncluded && !_isElectricityIncluded && !_isWifiIncluded && !_isLpgIncluded)
                            Text('None', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  // Curfew
                  _buildDetailRow(
                    'Curfew:',
                    Row(
                      children: [
                        const Icon(Icons.lock_clock, color: Color(0xFF6750A4), size: 25),
                        const SizedBox(width: 8),
                        const Text(
                          '11:59PM - 4:00AM',
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
                        const Icon(Icons.bed, color: Color(0xFF6750A4), size: 25), // Purple icon
                        const SizedBox(width: 8),
                        Text(
                          '$_bedrooms bedrooms',
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
                        const Icon(Icons.bathroom_outlined, color: Color(0xFF6750A4), size: 25),
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


class ReviewsModal extends StatelessWidget {
  final List<Map<String, String>> reviews;
  final String apartmentName;

  const ReviewsModal({super.key, required this.reviews, required this.apartmentName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reviews for $apartmentName',
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
                  if (review != reviews.last)
                    Divider(color: Colors.grey[300]),
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
