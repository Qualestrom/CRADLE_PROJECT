import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:cached_network_image/cached_network_image.dart'; // For robust image loading

import 'for_rent.dart'; // Assuming ForRent, Apartment, Bedspace are defined here or imported
import 'apartment.dart';
// import 'bedspace.dart'; // Only needed if Bedspace has specific properties to access

/// A widget that displays a list of ForRent items, similar to the Android ListingAdapter.
class ListingListView extends StatelessWidget {
  final List<ForRent> listings;
  final Function(ForRent item) onItemClick;
  final Function(ForRent item) onItemLongClick;

  const ListingListView({
    super.key,
    required this.listings,
    required this.onItemClick,
    required this.onItemLongClick,
  });

  @override
  Widget build(BuildContext context) {
    // Use ListView.builder for efficient list rendering
    return ListView.builder(
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final item = listings[index];
        // Build the visual representation for each item
        return _buildListItem(context, item);
      },
    );
  }

  /// Builds the widget for a single list item, similar to onBindViewHolder.
  Widget _buildListItem(BuildContext context, ForRent item) {
    // Use InkWell for tap/long-press feedback and handling
    return InkWell(
      onTap: () => onItemClick(item),
      onLongPress: () => onItemLongClick(item),
      child: Card(
        // Using Card for elevation and separation
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              SizedBox(
                width: 100, // Adjust width as needed
                height: 100, // Adjust height as needed
                child: CachedNetworkImage(
                  imageUrl: item.imageDownloadUrl ??
                      '', // Use the actual download URL field
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.grey),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12), // Spacing
              // Details Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item is Apartment
                          ? 'Apartment'
                          : 'Bedspace', // Determine type
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      // Format price using intl package
                      '₱${NumberFormat("#,##0.00", "en_US").format(item.price)} / month',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.contract}-year contract',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.otherDetails,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2, // Limit details lines
                      overflow: TextOverflow.ellipsis,
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
}
