import 'package:flutter/material.dart';
// Import Firestore if you plan to fetch data here
// import 'package:cloud_firestore/cloud_firestore.dart';

/* Remove this main function when integrating into the main app
void main() {
  runApp(BedspacerApp());
}

class BedspacerApp extends StatelessWidget {
  const BedspacerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bedspacer Listing',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: BedspacerListing(),
    );
  }
} */

class BedspacerListing extends StatefulWidget {
  final String listingId; // <-- 1. Declare the field to hold the ID

  const BedspacerListing({
    super.key,
    required this.listingId, // <-- 2. Add the required parameter to the constructor
  });

  @override
  _BedspacerListingState createState() => _BedspacerListingState();
}

// --- IMPORTANT ---
// You will now need to use `widget.listingId` inside _BedspacerListingState
// to fetch the correct data from Firestore.
// The current implementation below uses static placeholder data.

class _BedspacerListingState extends State<BedspacerListing> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Bedspacer Listing'),
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
                      'https://th.bing.com/th/id/OIP.2n7-DyvF3U2b9bH0o9OxMAHaE8?w=540&h=360&rs=1&pid=ImgDetMain',
                      height: MediaQuery.of(context).size.height *
                          0.25, // Dynamically adjusted height
                      fit: BoxFit.cover,
                      width: double.infinity,
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
                                'ABC Bedspacer',
                                style: TextStyle(
                                  fontSize: 22, // Adjusted font size for mobile
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B5B95),
                                ),
                              ),
                              SizedBox(height: 5),
                              Text('Block X Lot X Universe 2 St.',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14, // Adjusted font size
                                  )),
                              SizedBox(height: 5),
                              Text('Juan Dela Cruz',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14, // Adjusted font size
                                  )),
                            ],
                          ),
                          Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                radius: 20,
                                child: Text(
                                  '5',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Color(0xFF6B5B95),
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              Text('Remaining\nBed Slots',
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
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Color(0xFF6B5B95),
                              ),
                              Icon(
                                Icons.star,
                                color: Color(0xFF6B5B95),
                              ),
                              Icon(
                                Icons.star,
                                color: Color(0xFF6B5B95),
                              ),
                              Icon(
                                Icons.star_border,
                                color: Color(0xFF6B5B95),
                              ),
                              Icon(
                                Icons.star_border,
                                color: Color(0xFF6B5B95),
                              ),
                              SizedBox(width: 5),
                              Text('3.5',
                                  style: TextStyle(color: Color(0xFF6B5B95))),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Max. Capacity:', '👥 20 persons'),
                          _detailRow('Bills Included:', '💧 ⚡ 📶 ♨️'),
                          _detailRow('Curfew:', '🕙 11:59PM - 4:00AM'),
                          _detailRow('Gender:', '⚥ Mixed'),
                          _detailRow('Bathrooms:', '🚿 2 bathrooms'),
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
                                '₱2000.00',
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
                          Text('1-year contract',
                              style: TextStyle(color: Colors.grey[700])),
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
            width: 120,
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
          title: Text('Reviews for ABC Bedspacer',
              style: TextStyle(color: Color(0xFF6B5B95))),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _review(
                    '★★★★★',
                    'Nice location, reasonable price. Close to public transportation and markets.',
                    '- Maria Santos'),
                _review(
                    '★★★☆☆',
                    'Decent bedspace. Bathrooms are clean but can get crowded during peak hours.',
                    '- John Garcia'),
                _review(
                    '★★★☆☆',
                    'Good for students on a budget. The curfew is strictly implemented.',
                    '- Lisa Reyes'),
                _review(
                    '★★☆☆☆',
                    'WiFi is unstable during the evening. Location is good but the place is noisy.',
                    '- Mark Tan'),
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
}
