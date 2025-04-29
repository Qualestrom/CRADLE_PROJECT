// home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity
import 'dart:async'; // Import for async

// Import your models and helpers
import 'for_rent.dart'; // Adjust path as needed
import 'apartment.dart'; // Adjust path as needed
import 'bedspace.dart'; // Adjust path as needed
import 'filters.dart'; // Adjust path as needed
import 'firestore_mapper.dart'; // Adjust path as needed
import 'listing_detail_fragment.dart'; // Adjust path as needed (your from_java.dart screen)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Corrected: Use FirebaseFirestore.instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // State for filters
  Filters _activeFilters = Filters();
  late Filters _tempFilters; // For the filter sheet

  // State for user info from SharedPreferences
  String? _accountType;
  String? _fullName;

  // Key for the Scaffold to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- Connectivity State ---
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOfflineDialogShowing = false;
  bool _isConnected = true; // Assume connected initially

  @override
  void initState() {
    super.initState();
    // Corrected: Use copyWith() for initialization
    _tempFilters = _activeFilters.copyWith();
    _loadUserInfo(); // Load user info

    // --- Connectivity Check ---
    _checkInitialConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
    // --- End Connectivity Check ---

    _auth.authStateChanges().listen((user) {
      _loadUserInfo(); // Reload user info on auth state change
      if (mounted) {
        setState(() {}); // Update drawer on auth change
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel(); // Cancel listener
    super.dispose();
  }

  // --- Connectivity Methods ---
  // (Keep your existing connectivity methods: _checkConnectivity,
  // _checkInitialConnectivity, _handleConnectivityChange, _showOfflineDialog)
  // Function to check connectivity and show/hide dialog
  Future<void> _checkConnectivity(ConnectivityResult result) async {
    final currentlyConnected = result != ConnectivityResult.none;
    if (mounted) {
      setState(() {
        _isConnected = currentlyConnected;
      });
    }

    if (!currentlyConnected) {
      // Only show dialog if it's not already showing and widget is mounted
      if (!_isOfflineDialogShowing && mounted) {
        setState(() {
          _isOfflineDialogShowing = true;
        });
        // Don't await here, let the dialog manage its lifecycle
        _showOfflineDialog();
      }
    } else {
      // If connected and the dialog is showing, dismiss it
      if (_isOfflineDialogShowing && mounted) {
        // Use rootNavigator: true to ensure it pops the dialog
        // even if called from within the dialog's context (like retry)
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isOfflineDialogShowing = false;
        });
      }
    }
  }

  // Check connectivity when the screen first loads
  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    await _checkConnectivity(result);
  }

  // Handle connectivity changes detected by the stream listener
  void _handleConnectivityChange(ConnectivityResult result) {
    _checkConnectivity(result);
  }

  // Function to display the offline warning dialog
  Future<void> _showOfflineDialog() async {
    // Ensure context is valid before showing dialog
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('No Internet Connection'),
            ],
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'This app requires an internet connection to fetch the latest listings.'),
                SizedBox(height: 8),
                Text('Please check your network settings.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry'),
              onPressed: () async {
                // Manually trigger a re-check when retry is pressed
                final result = await Connectivity().checkConnectivity();
                // _checkConnectivity will handle dismissing the dialog if connected
                _checkConnectivity(result);

                // If still offline after retry, show a quick message
                if (result == ConnectivityResult.none && mounted) {
                  // Check mounted again before showing SnackBar
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    // Use dialogContext
                    const SnackBar(
                      content: Text('Still offline. Please check connection.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This block executes when the dialog is popped.
      // Reset the flag ensuring it can be shown again if needed.
      // Check mounted state again as the widget might be disposed
      // between showing the dialog and it being dismissed.
      if (mounted) {
        setState(() {
          _isOfflineDialogShowing = false;
        });
      }
    });
  }
  // --- End Connectivity Methods ---

  Future<void> _loadUserInfo() async {
    // Check mounted before accessing context or prefs
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    // Check mounted again after async gap
    if (mounted) {
      setState(() {
        _accountType = prefs.getString("accountType");
        _fullName = prefs.getString("fullName");
      });
    }
  }

  Query _buildFilteredQuery() {
    Query query = _db.collection('listings');

    // --- Type Filter ---
    // Option 1: Filter based on existence of type-specific fields (as before)
    // if (_activeFilters.type != null) {
    //   if (_activeFilters.type == "APARTMENT") {
    //     query = query.where('noOfBedrooms', isGreaterThanOrEqualTo: 0);
    //   } else if (_activeFilters.type == "BEDSPACE") {
    //     query = query.where('roommateCount', isGreaterThanOrEqualTo: 0);
    //   }
    // }
    // Option 2: Filter based on a dedicated 'type' field in Firestore (Recommended)
    if (_activeFilters.type != null) {
      // Assumes you have a field named 'listingType' (or similar) in Firestore
      // storing "APARTMENT" or "BEDSPACE"
      query = query.where('listingType', isEqualTo: _activeFilters.type);
    }

    // --- Contract Filter ---
    // Corrected: Use 'contract' property (nullable bool)
    if (_activeFilters.contract != null) {
      // **IMPORTANT**: Assumes your 'contract' field in Firestore is a BOOLEAN (true/false).
      // If it's stored differently (e.g., integer 0/1, string 'yes'/'no'),
      // adjust this 'isEqualTo' accordingly.
      query = query.where('contract', isEqualTo: _activeFilters.contract);
    }

    // --- Curfew Filter ---
    // Corrected: Use 'curfew' property (nullable bool)
    if (_activeFilters.curfew != null) {
      // **IMPORTANT**: Assumes your 'curfew' field in Firestore is a BOOLEAN (true/false).
      // If it's stored differently (e.g., string 'yes'/'no', non-empty/empty string),
      // adjust this 'isEqualTo' accordingly.
      query = query.where('curfew', isEqualTo: _activeFilters.curfew);
    }

    // --- Ordering ---
    // Ensure you have a Firestore index for this query combination.
    // The index usually includes the fields you filter on first,
    // followed by the field you order by.
    query = query.orderBy('dateCreated', descending: true);
    return query;
  }

  void _showFilterSheet() {
    // Corrected: Use copyWith() to create a temporary copy for the sheet
    _tempFilters = _activeFilters.copyWith();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to take more height if needed
      shape: const RoundedRectangleBorder(
        // Add rounded corners
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        // Use StatefulBuilder to manage the state *within* the bottom sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                // Adjust padding for keyboard overlap if text fields were present
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Wrap(
                // Use Wrap for content that might exceed vertical space
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters',
                          style: Theme.of(context).textTheme.headlineSmall),
                      IconButton(
                        // Add a close button
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),

                  // --- Type Filter ---
                  Text('Listing Type',
                      style: Theme.of(context).textTheme.titleMedium),
                  // Use RadioListTile for single selection (better UX than checkboxes here)
                  RadioListTile<String?>(
                    title: const Text('Apartment'),
                    value: "APARTMENT",
                    groupValue: _tempFilters.type,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.type = value),
                    controlAffinity:
                        ListTileControlAffinity.leading, // Radio on left
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String?>(
                    title: const Text('Bedspace'),
                    value: "BEDSPACE",
                    groupValue: _tempFilters.type,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.type = value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  // Optional: Add an "Any" option
                  RadioListTile<String?>(
                    title: const Text('Any Type'),
                    value: null, // Represents no type filter
                    groupValue: _tempFilters.type,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.type = value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 20, thickness: 1),

                  // --- Contract Filter ---
                  Text('Contract',
                      style: Theme.of(context).textTheme.titleMedium),
                  // Corrected: Use 'contract' property and handle nullable bool
                  RadioListTile<bool?>(
                    title: const Text('With Contract'),
                    value: true,
                    groupValue: _tempFilters.contract,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.contract = value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool?>(
                    title: const Text('No Contract'),
                    value: false,
                    groupValue: _tempFilters.contract,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.contract = value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool?>(
                    title: const Text('Any Contract'),
                    value: null, // Represents no contract filter
                    groupValue: _tempFilters.contract,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.contract = value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 20, thickness: 1),

                  // --- Curfew Filter ---
                  Text('Curfew',
                      style: Theme.of(context).textTheme.titleMedium),
                  // Corrected: Use 'curfew' property and handle nullable bool
                  RadioListTile<bool?>(
                    title: const Text('With Curfew'),
                    value: true,
                    groupValue: _tempFilters.curfew,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.curfew = value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool?>(
                    title: const Text('No Curfew'),
                    value: false,
                    groupValue: _tempFilters.curfew,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.curfew = value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool?>(
                    title: const Text('Any Curfew'),
                    value: null, // Represents no curfew filter
                    groupValue: _tempFilters.curfew,
                    onChanged: (value) =>
                        setSheetState(() => _tempFilters.curfew = value),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 20, thickness: 1),

                  // --- Action Buttons ---
                  Padding(
                    // Add padding for buttons
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // Space out buttons
                      children: [
                        // Clear Button
                        OutlinedButton(
                          // Use OutlinedButton for secondary action
                          onPressed: () {
                            // Clear filters in the sheet first for visual feedback
                            setSheetState(() {
                              _tempFilters = Filters(); // Reset temp filters
                            });
                            // Then clear the active filters and close
                            setState(() {
                              _activeFilters =
                                  Filters(); // Reset active filters
                            });
                            Navigator.pop(context); // Close the sheet
                          },
                          child: const Text('Clear All'),
                        ),
                        // Apply Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            // Make apply button stand out
                            minimumSize:
                                const Size(120, 40), // Give it some size
                          ),
                          onPressed: () {
                            // Apply the temporary filters to the active filters
                            setState(() {
                              // Corrected: Use copyWith() to apply changes
                              _activeFilters = _tempFilters.copyWith();
                            });
                            Navigator.pop(context); // Close the sheet
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ],
                    ),
                  ),
                  // Add some bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Settle Now'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              // Corrected: Use the isFiltering getter
              color: _activeFilters.isFiltering
                  ? Theme.of(context)
                      .colorScheme
                      .secondary // Use theme color for active filter
                  : null, // Default color
            ),
            tooltip: 'Filters',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      // Conditionally build the body based on connectivity
      body: _isConnected
          ? _buildListingStream() // Show listings if connected
          : _buildOfflineMessage(), // Show offline message if not connected
    );
  }

  // Widget to show when offline
  Widget _buildOfflineMessage() {
    // (Keep your existing _buildOfflineMessage logic)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 20),
            Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Connect to the internet to see listings.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Check'),
              onPressed: _checkInitialConnectivity, // Manually trigger check
            )
          ],
        ),
      ),
    );
  }

  // Widget that builds the StreamBuilder for listings
  Widget _buildListingStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Firestore Error: ${snapshot.error}');
          // Log error more robustly in production (e.g., Crashlytics)
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading listings. Please try again later.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          ));
        }

        // Show loading indicator specifically while waiting for initial data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle no data case after connection is active
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No listings found matching your criteria.'));
        }

        // Process data only if available
        final List<ForRent> listings = processFirestoreListings(snapshot.data!);

        // Use ListView.separated for better visual spacing
        return ListView.separated(
          itemCount: listings.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 4), // Space between cards
          itemBuilder: (context, index) {
            final listing = listings[index];
            return ListingItemCard(
              listing: listing,
              storage: _storage,
              onTap: () {
                // Only navigate if connected
                if (_isConnected) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ListingDetailScreen(listingId: listing.docId),
                    ),
                  );
                } else {
                  // Show a more informative message if offline
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Connect to the internet to view details.'),
                      behavior: SnackBarBehavior.floating, // Make it float
                    ),
                  );
                }
              },
            );
          },
          padding: const EdgeInsets.symmetric(
              vertical: 8.0, horizontal: 4.0), // Add padding around the list
        );
      },
    );
  }

  Widget _buildDrawer() {
    final User? currentUser = _auth.currentUser;
    final bool isLoggedIn = currentUser != null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_fullName ??
                (isLoggedIn ? "User" : "Guest")), // Default to Guest
            accountEmail:
                Text(currentUser?.email ?? "Not signed in"), // Clearer message
            // TODO: Consider adding current user profile picture if available
            // currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(
                Icons.home_outlined), // Use outlined icons for consistency
            title: const Text('Home'),
            selected: true, // Indicate this is the current screen
            onTap: () => Navigator.pop(context), // Just close drawer
          ),
          // Conditional Drawer Items
          if (isLoggedIn && _accountType == "SELLER")
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('My Properties'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement navigation to My Properties screen
                print("Navigate to My Properties");
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('My Properties (Not Implemented)')));
              },
            ),
          if (isLoggedIn && _accountType == "BUYER")
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('My Favorites'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement navigation to Favorites screen
                print("Navigate to Favorites");
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('My Favorites (Not Implemented)')));
              },
            ),
          const Divider(), // Visually separate sections
          // Auth Actions
          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Log In / Sign Up'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement navigation to Login/Signup screen
                print("Navigate to Login/Signup");
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Login/Signup (Not Implemented)')));
              },
            ),
          if (isLoggedIn)
            ListTile(
              leading: Icon(Icons.logout,
                  color: Colors.red[700]), // Make logout distinct
              title: Text('Log Out', style: TextStyle(color: Colors.red[700])),
              onTap: () async {
                Navigator.pop(context); // Close drawer first
                try {
                  await _auth.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  // Use Future.wait for potentially faster parallel removal
                  await Future.wait([
                    prefs.remove("accountType"),
                    prefs.remove("fullName"),
                    // Add any other user-specific keys here
                  ]);
                  print("User logged out successfully.");
                  // Provide user feedback
                  if (mounted) {
                    // Check mounted before showing SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Successfully logged out.')));
                  }
                  // Note: The authStateChanges listener in initState will trigger
                  // a setState and UI update automatically.
                } catch (e) {
                  print("Error logging out: $e");
                  if (mounted) {
                    // Check mounted before showing SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error logging out: $e')));
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

// --- ListingItemCard Widget ---
// (Added minor improvements like better placeholders, error handling, theme colors)
class ListingItemCard extends StatelessWidget {
  final ForRent listing;
  final FirebaseStorage storage;
  final VoidCallback onTap;

  const ListingItemCard({
    super.key,
    required this.listing,
    required this.storage,
    required this.onTap,
  });

  // Consider making this more robust or part of the listing model itself
  Future<String?> _getImageUrl() async {
    if (listing.imageFilename.isEmpty) return null;
    try {
      // You might want to cache these URLs if they don't change often
      return await storage.ref().child(listing.imageFilename).getDownloadURL();
    } on FirebaseException catch (e) {
      // Handle specific errors like object-not-found gracefully
      if (e.code == 'object-not-found') {
        print("Image not found for ${listing.imageFilename}");
      } else {
        print("Error getting image URL for ${listing.imageFilename}: $e");
      }
      return null; // Return null on error
    } catch (e) {
      print("Generic error getting image URL for ${listing.imageFilename}: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine display type more robustly if needed (e.g., from a type field)
    final String typeDisplay = listing is Apartment ? 'Apartment' : 'Bedspace';
    // Consider using NumberFormat for currency formatting (intl package)
    final String priceText = '₱${listing.price.toStringAsFixed(0)}/month';
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: 4, vertical: 0), // Adjusted margin for ListView.separated
      clipBehavior:
          Clip.antiAlias, // Ensures InkWell ripple stays within card bounds
      elevation: 1.0, // Subtle elevation
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0)), // Rounded corners
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image ---
              SizedBox(
                // Constrain the size of the image container
                width: 100,
                height: 100,
                child: FutureBuilder<String?>(
                  future: _getImageUrl(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Consistent loading placeholder
                      return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)));
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      // Display a placeholder icon on error or no image
                      return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                              child: Icon(
                                  Icons
                                      .house_siding_rounded, // More relevant icon
                                  color: Colors.grey[600],
                                  size: 40)));
                    }
                    // --- Display Image ---
                    return ClipRRect(
                      // Clip the image itself to rounded corners
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(snapshot.data!,
                          width: 100, height: 100, fit: BoxFit.cover,
                          // Improved loading builder
                          loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          // Maintain size and shape while loading
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null, // Indeterminate if size unknown
                            ),
                          ),
                        );
                      },
                          // Improved error builder
                          errorBuilder: (context, error, stack) {
                        print(
                            "Image load error: $error"); // Log error for debugging
                        return Container(
                            // Maintain size and shape on error
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Center(
                                child: Icon(
                                    Icons
                                        .broken_image_outlined, // Different icon for load error
                                    color: Colors.grey[600],
                                    size: 40)));
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // --- Details ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.name.isNotEmpty
                          ? listing.name
                          : 'Untitled Listing', // Handle empty name
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.address.isNotEmpty
                          ? listing.address
                          : 'No address provided', // Handle empty address
                      style: textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Price and Type Chip aligned at the bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment
                          .end, // Align items vertically at the bottom
                      children: [
                        Text(
                          priceText,
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme
                                .primary, // Use primary theme color for price
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(typeDisplay),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 0), // Adjust padding
                          labelStyle: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer),
                          visualDensity:
                              VisualDensity.compact, // Make chip smaller
                          backgroundColor:
                              colorScheme.secondaryContainer, // Use theme color
                          side: BorderSide.none, // Remove border
                        ),
                      ],
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
