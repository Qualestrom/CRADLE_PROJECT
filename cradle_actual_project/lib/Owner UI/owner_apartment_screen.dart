import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apartment Details',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ApartmentDetailsScreen(),
    );
  }
}

class ApartmentDetailsScreen extends StatefulWidget {
  const ApartmentDetailsScreen({super.key});

  @override
  State<ApartmentDetailsScreen> createState() => _ApartmentDetailsScreenState();
}

class _ApartmentDetailsScreenState extends State<ApartmentDetailsScreen> {
  // State variables for apartment details
  String _apartmentName = 'ABC Apartment';
  String _location = 'Building Y Room Z, City Area';
  String _owner = 'Maria Santos';
  int _availableUnits = 3;
  final double _rating = 4.2;
  int _roomCapacity = 6;
  int _sharedBathrooms = 2;
  double _monthlyRate = 1500.00;
  final String _contractLength = '6-month contract';

  // State variables for included bills
  bool _isWaterIncluded = true;
  bool _isElectricityIncluded = true;
  bool _isWifiIncluded = true;
  bool _isLpgIncluded = true;

  // Placeholder data for reviews
  final List<Map<String, String>> _reviews = [
    {
      'stars': '★★★★☆',
      'text': 'Clean and affordable. Good location.',
      'author': '- Resident A',
    },
    {
      'stars': '★★★★★',
      'text': 'Friendly community and convenient location.',
      'author': '- Resident B',
    },
    {
      'stars': '★★★☆☆',
      'text': 'A bit noisy at times, but manageable for the price.',
      'author': '- Resident C',
    },
  ];

  // Function to show the Reviews modal
  void _onReviewsPressed() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReviewsModal(reviews: _reviews);
      },
    );
  }

  // Function to display a message when the Edit button is clicked
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
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
      } else if (i == fullStars && halfStar >= 0.5) {
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
      }
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apartment Image
            Image.network(
              'https://th.bing.com/th/id/R.b2236b714cb9cbd93b43232361faf9ec?rik=dBDMY41CcAh9Tw&riu=http%3a%2f%2f1.bp.blogspot.com%2f-3RlvnNEnq7A%2fUex8jPr7CeI%2fAAAAAAAAALA%2fqRA7a6VQ35E%2fs1600%2fAPARTMENT_WHITE_PERSPECTIVE%2bfor%2bFB.jpg&ehk=lQpkY%2fsndCrVdccrKHJlr0RPyVl7EU4AWWuYyPMV%2bmk%3d&risl=&pid=ImgRaw&r=0',
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Apartment Name and Available Units
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _apartmentName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _availableUnits.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Available\nUnits',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location details
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _location,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Owner details
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                       Expanded(
                        child: Text(
                          _owner,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                           overflow: TextOverflow.ellipsis,
                        ),
                       ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  const SizedBox(height: 16),

                  // Ratings Section with buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RATINGS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          _buildStarRating(_rating),
                          const SizedBox(width: 4),
                          Text(
                            _rating.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Reviews Button
                      OutlinedButton(
                        onPressed: _onReviewsPressed,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Reviews'),
                      ),
                      const SizedBox(width: 8),
                      // Edit Button
                      OutlinedButton(
                        onPressed: _onEditPressed,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  const SizedBox(height: 16),

                  // Details Section
                  const Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Room Capacity detail
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Room Capacity'),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people_alt, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$_roomCapacity persons', style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Available Units detail
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Available Units'),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.apartment, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$_availableUnits units', style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bills Included details
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Bills Included:'),
                      ),
                      const SizedBox(width: 16),
                       Expanded(
                        child: Row(
                          children: [
                            if (_isWaterIncluded) ...[
                              const Icon(Icons.water_drop, size: 20, color: Colors.blue),
                              const SizedBox(width: 4),
                              const Text('Water', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                            ],
                            if (_isElectricityIncluded) ...[
                              const Icon(Icons.electric_bolt, size: 20, color: Colors.orange),
                              const SizedBox(width: 4),
                              const Text('Electric', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                            ],
                            if (_isWifiIncluded) ...[
                              const Icon(Icons.wifi, size: 20, color: Colors.blue),
                              const SizedBox(width: 4),
                              const Text('Internet', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                            ],
                            if (_isLpgIncluded) ...[
                              const Icon(Icons.local_fire_department, size: 20, color: Colors.red),
                              const SizedBox(width: 4),
                              const Text('LPG', style: TextStyle(fontSize: 14)),
                            ],
                             if (!_isWaterIncluded && !_isElectricityIncluded && !_isWifiIncluded && !_isLpgIncluded)
                               const Text('None', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Access Hours detail
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Access Hours:'),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.lock_clock, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('24/7 access', style: TextStyle(fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Shared Bathrooms detail
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Shared Bathrooms:'),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.bathtub, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$_sharedBathrooms bathrooms', style: const TextStyle(fontSize: 14))),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  const SizedBox(height: 16),

                  // Price and Contract details
                  Text(
                    '₱${_monthlyRate.toStringAsFixed(2)} / month',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _contractLength,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewsModal extends StatelessWidget {
  final List<Map<String, String>> reviews;

  const ReviewsModal({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reviews'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: reviews.map<Widget>((review) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                  const Divider(),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

void main() {
  runApp(const MyApp());
}
