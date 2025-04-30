import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart'; // For the call button

import 'package:logger/logger.dart'; // Import logger

// Import your data models
import 'for_rent.dart';
import 'apartment.dart';
import 'bedspace.dart';

// Initialize logger for this file
final logger = Logger();

class ListingDetailScreen extends StatefulWidget {
  final String listingId; // ID passed from the previous screen

  const ListingDetailScreen(
      {super.key, required this.listingId}); // Use super parameter for key

  @override
  // ignore: invalid_use_of_private_type_in_public_api
  ListingDetailScreenState createState() => ListingDetailScreenState();
}

class ListingDetailScreenState extends State<ListingDetailScreen> {
  // Future to hold the combined result of Firestore data and Storage URL
  late Future<ListingDetails> _listingDetailsFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching data when the widget is initialized
    _listingDetailsFuture = _fetchListingDetails();
  }

  // Helper function to fetch both Firestore document and Storage URL
  Future<ListingDetails> _fetchListingDetails() async {
    try {
      // 1. Fetch Firestore document
      final docSnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        throw Exception('Listing not found.');
      }

      final data = docSnapshot.data()!;
      ForRent listing;

      // 2. Determine type and create the correct model object
      if (data.containsKey('noOfBedrooms')) {
        listing = Apartment.fromJson(docSnapshot.id, data);
      } else {
        listing = Bedspace.fromJson(docSnapshot.id, data);
      }

      // 3. Fetch image URL from Firebase Storage
      String imageUrl = ''; // Default empty or placeholder URL
      if (listing.imageFilename.isNotEmpty) {
        try {
          imageUrl = await FirebaseStorage.instance
              .ref()
              .child(listing.imageFilename)
              .getDownloadURL();
        } catch (e, s) {
          // Handle image loading error (e.g., file not found)
          logger.e("Error fetching image URL for ${listing.imageFilename}",
              error: e, stackTrace: s); // Use logger.e
          // You might want to set a placeholder image URL here
        }
      }

      // 4. Return combined details
      return ListingDetails(listing: listing, imageUrl: imageUrl);
    } catch (e, s) {
      // Rethrow the error to be caught by FutureBuilder
      logger.e("Error fetching listing details for ${widget.listingId}",
          error: e, stackTrace: s); // Use logger.e
      rethrow;
    }
  }

  // Helper function to launch the dialer
  Future<void> _launchDialer(String phoneNumber) async {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch dialer for $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
        // Back button is automatically added by Flutter's Navigator
      ),
      body: FutureBuilder<ListingDetails>(
        future: _listingDetailsFuture,
        builder: (context, snapshot) {
          // --- Handle Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Handle Error State ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading listing: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // --- Handle Success State ---
          if (snapshot.hasData) {
            final details = snapshot.data!;
            final listing = details.listing;
            final imageUrl = details.imageUrl;

            // Determine type for conditional UI
            final bool isApartment = listing is Apartment;
            final Apartment? apartment = isApartment ? listing : null;
            final Bedspace? bedspace =
                !isApartment ? listing as Bedspace : null;

            // Format data for display
            final String billsIncludedText = listing.billsIncluded.isEmpty
                ? 'None'
                : listing.billsIncluded.join(', ');
            final String priceText =
                '₱${listing.price.toStringAsFixed(2)} / month';
            final String contractText = '${listing.contract} year/s';
            final String curfewText = listing.curfew ?? 'None';

            return SingleChildScrollView(
              // Allows content to scroll if it overflows
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Image ---
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        // Optional: for rounded corners
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          imageUrl,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // Add loading/error builders for the image itself
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 250,
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 250,
                            color: Colors.grey[300],
                            child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey)),
                          ),
                        ),
                      )
                    else
                      Container(
                        // Placeholder if no image URL
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey)),
                      ),
                    const SizedBox(height: 16),

                    // --- Name ---
                    Text(
                      listing.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // --- Address ---
                    Text(listing.address,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    const Divider(),

                    // --- Price ---
                    _buildDetailRow(
                        context, Icons.attach_money, 'Price:', priceText),
                    const SizedBox(height: 8),

                    // --- Contract ---
                    _buildDetailRow(context, Icons.calendar_today, 'Contract:',
                        contractText),
                    const SizedBox(height: 8),

                    // --- Contact Person & Call Button ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'CONTACT: ${listing.contactPerson}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
                          onPressed: listing.contactNumber.isNotEmpty
                              ? () => _launchDialer(listing.contactNumber)
                              : null, // Disable if no number
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    // --- Bills Included ---
                    _buildDetailRow(context, Icons.receipt_long,
                        'Bills Included:', billsIncludedText),
                    const SizedBox(height: 8),

                    // --- Curfew ---
                    _buildDetailRow(
                        context, Icons.nightlight_round, 'Curfew:', curfewText),
                    const SizedBox(height: 16),

                    // --- Apartment Specific Details ---
                    Visibility(
                      visible: isApartment && apartment != null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 16),
                          Text('Apartment Details',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                              context,
                              Icons.people_alt,
                              'Capacity:',
                              '${apartment?.capacity ?? 0} person/s'),
                          const SizedBox(height: 8),
                          _buildDetailRow(context, Icons.bed, 'Bedrooms:',
                              '${apartment?.noOfBedrooms ?? 0}'),
                          const SizedBox(height: 8),
                          _buildDetailRow(context, Icons.bathtub, 'Bathrooms:',
                              '${apartment?.noOfBathrooms ?? 0}'),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // --- Bedspace Specific Details ---
                    Visibility(
                      visible: !isApartment && bedspace != null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 16),
                          Text('Bedspace Details',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _buildDetailRow(context, Icons.group, 'Roommates:',
                              '${bedspace?.roommateCount ?? 0}'),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                              context,
                              Icons.bathtub_outlined,
                              'Bathroom Share:',
                              '${bedspace?.bathroomShareCount ?? 0} person/s'),
                          const SizedBox(height: 8),
                          _buildDetailRow(context, Icons.wc, 'Gender:',
                              _formatGenderPreference(bedspace?.gender)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // --- Other Details ---
                    const Divider(),
                    const SizedBox(height: 16),
                    Text('Other Details',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(listing.otherDetails.isNotEmpty
                        ? listing.otherDetails
                        : 'None'),
                    const SizedBox(height: 24), // Extra space at bottom
                  ],
                ),
              ),
            );
          }

          // Should not happen if logic is correct, but fallback
          return const Center(child: Text('No listing data available.'));
        },
      ),
    );
  }

  // Helper widget to build consistent detail rows
  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label ',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }

  // Helper to format GenderPreference enum for display
  String _formatGenderPreference(GenderPreference? gender) {
    switch (gender) {
      case GenderPreference.maleOnly:
        return 'Male Only';
      case GenderPreference.femaleOnly:
        return 'Female Only';
      case GenderPreference.any:
      default:
        return 'Any';
    }
  }
}

// Helper class to hold the combined results from Firestore and Storage
class ListingDetails {
  final ForRent listing;
  final String imageUrl;

  ListingDetails({required this.listing, required this.imageUrl});
}
