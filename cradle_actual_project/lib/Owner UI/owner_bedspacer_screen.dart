import 'package:flutter/material.dart';

// main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bedspacer Details',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BedspacerDetailsScreen(), 
    );
  }
}


class BedspacerDetailsScreen extends StatefulWidget {
  const BedspacerDetailsScreen({super.key});

  @override
  State<BedspacerDetailsScreen> createState() => _BedspacerDetailsScreenState();
}

class _BedspacerDetailsScreenState extends State<BedspacerDetailsScreen> {

  String _bedspacerName = 'ABC Bedspace';
  String _location = 'Building Y Room Z, City Area';
  String _owner = 'Maria Santos';
  int _availableBedspaces = 3;
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
      'text': 'Clean and affordable. Good for students.',
      'author': '- Student A',
    },
    {
      'stars': '★★★★★',
      'text': 'Friendly housemates and convenient location.',
      'author': '- Young Professional B',
    },
    {
      'stars': '★★★☆☆',
      'text': 'A bit crowded, but manageable for the price.',
      'author': '- Traveler C',
    },
  ];

  // Function to show the Reviews modal
  void _onReviewsPressed() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // This modal displays the static reviews data
        return ReviewsModal(reviews: _reviews);
      },
    );
  }

  // display a message Edit button 
  void _onEditPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit details here...'), 
        duration: Duration(seconds: 2), 
      ),
    );
  }


 
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
      // AppBar with a back button
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
            // Bedspacer Image (Placeholder)
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
                  // Bedspacer Name and Available Bedspaces counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded( 
                        child: Text(
                          _bedspacerName,
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
                              _availableBedspaces.toString(), 
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Available\nBedspaces', 
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
                  const Divider(), // Visual separator
                  const SizedBox(height: 16),

                  // Details Section (Bedspacer)
                  const Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                 
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
                 
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Available Bedspaces'), 
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.bed, size: 20, color: Colors.grey[700]), 
                      const SizedBox(width: 8),
                      Expanded(child: Text('$_availableBedspaces bedspaces', style: const TextStyle(fontSize: 14))), 
                    ],
                  ),
                  const SizedBox(height: 8),
                  
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
                  // Shared Bathrooms 
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

                  // Price and Contract 
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
                    review['text']!, // Display review text
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