//Current problems in this file:
// 1. The price range filter is not working as expected. It should filter the
// listings based on the selected price range, but it seems to be ignoring this filter in the current implementation.
// 2. Color scheme doesn't match the design. The app's color scheme should be consistent with the design provided
// in the Figma file.
// 3. Some icons are not displaying correctly. The icons used in the app should match the design provided in the Figma file.
// 4. Details of the listings are not displayed correctly. The details of the listings should be displayed in a way
// that is consistent with the design provided in the Figma file.

// Front-End Developer: Christine Joyce Blanco

// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'dart:async';

// Import your models and helpers (adjust paths as needed)
import '../Test/for_rent.dart';
import '../Test/filters.dart';
import '../Test/firestore_mapper.dart';
import '../Test/apartment.dart'; // For Apartment class
import '../Test/bedspace.dart'; // For GenderPreference enum

// Import for Firebase initialization options (if using flutterfire_cli)
// import 'firebase_options.dart';

Future<void> main() async {
  // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp()); // Run the app
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Apartment Listings',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: RenterHomeScreen(),
    );
  }
}

class RenterHomeScreen extends StatefulWidget {
  // Renamed class
  const RenterHomeScreen({super.key});

  @override
  State<RenterHomeScreen> createState() =>
      _RenterHomeScreenState(); // Renamed state class
}

class _RenterHomeScreenState extends State<RenterHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger logger = Logger(); // Initialize logger

  // State for filters
  Filters _activeFilters = Filters();
  late Filters _tempFilters; // For the filter sheet

  // State for price range
  RangeValues _priceRange = const RangeValues(0, 10000); // Default range

  // State for user info from SharedPreferences
  String? _accountType;
  String? _fullName;

  // Key for the Scaffold to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- Connectivity State ---
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOfflineDialogShowing = false;
  bool _isConnected = true; // Assume connected initially

  @override
  void initState() {
    super.initState();
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

  // --- Connectivity Methods (Copied from home_screen.dart) ---
  Future<void> _checkConnectivity(ConnectivityResult result) async {
    final currentlyConnected = result != ConnectivityResult.none;
    if (mounted) {
      setState(() {
        _isConnected = currentlyConnected;
      });
    }

    if (!currentlyConnected) {
      if (!_isOfflineDialogShowing && mounted) {
        setState(() {
          _isOfflineDialogShowing = true;
        });
        _showOfflineDialog(); // Don't await
      }
    } else {
      if (_isOfflineDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    await _checkConnectivity(
        results.isNotEmpty ? results.first : ConnectivityResult.none);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _checkConnectivity(
        results.isNotEmpty ? results.first : ConnectivityResult.none);
  }

  Future<void> _showOfflineDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Using the AlertDialog structure from home_screen.dart
        return AlertDialog(
          title: const Row(children: [
            Icon(Icons.wifi_off_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('No Internet Connection')
          ]),
          content: const SingleChildScrollView(
              child: ListBody(children: <Widget>[
            Text(
                'This app requires an internet connection to fetch the latest listings.'),
            SizedBox(height: 8),
            Text('Please check your network settings.')
          ])),
          actions: <Widget>[
            TextButton(
                child: const Text('Retry'),
                onPressed: () async {
                  final results = await Connectivity().checkConnectivity();
                  final result = results.isNotEmpty
                      ? results.first
                      : ConnectivityResult.none;
                  await _checkConnectivity(result);
                  if (result == ConnectivityResult.none && mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Still offline. Please check connection.'),
                            duration: Duration(seconds: 2)));
                  }
                })
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isOfflineDialogShowing = false;
        });
      }
    });
  }
  // --- End Connectivity Methods ---

  Future<void> _loadUserInfo() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _accountType = prefs.getString("accountType");
        _fullName = prefs.getString("fullName");
      });
    }
  }

  Query _buildFilteredQuery() {
    Query query = _db.collection('listings');

    // Type Filter
    if (_activeFilters.type != null) {
      query = query.where('type', isEqualTo: _activeFilters.type);
    }

    // Contract Filter
    if (_activeFilters.contract != null) {
      // Assuming 'contract' field in Firestore stores 0 for no contract, >0 for years
      if (_activeFilters.contract == true) {
        query = query.where('contract', isGreaterThan: 0);
      } else {
        query = query.where('contract', isEqualTo: 0);
      }
    }

    // --- Firestore level filtering for Gender (if applicable and indexed) ---
    // Note: This requires the 'gender' field to be stored in Firestore
    // and might need specific indexes, especially if combined with other filters.
    // If filtering 'gender' only for 'bedspace' type, you might need composite indexes.
    // if (_activeFilters.gender != null && _activeFilters.type == 'bedspace') {
    //   query = query.where('gender', isEqualTo: _activeFilters.gender);
    // }

    // --- Firestore level filtering for Street (if applicable and indexed) ---
    // Note: Firestore equality checks are exact. For 'contains' logic on address,
    // client-side filtering is usually required unless data is structured differently (e.g., separate 'street' field).
    // if (_activeFilters.street != null) {
    //   query = query.where('street', isEqualTo: _activeFilters.street); // Requires exact match on a 'street' field
    // }

    // --- Ordering ---
    // query = query.orderBy('dateCreated', descending: true); // Add if you have this field
    return query;
  }

  void _openDrawer() {
    // Renamed from toggleMenu
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the key
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFede9f3),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.grey),
              onPressed: _openDrawer, // Use the method to open drawer
              tooltip: 'Menu',
            ),
            const Expanded(
              child: Center(
                child: Text("Home", style: TextStyle(color: Colors.black87)),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.tune,
                color: _activeFilters.isFiltering
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey, // Highlight if filters active
              ),
              onPressed: _showFilterDialog,
              tooltip: 'Filters',
            ),
          ],
        ),
      ),
      drawer: buildMenu(),
      body: _isConnected
          ? _buildListingStream()
          : _buildOfflineMessage(), // Switch body based on connectivity
    );
  }

  // --- Offline Message Widget (Copied from home_screen.dart) ---
  Widget _buildOfflineMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 20),
            Text('No Internet Connection',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Connect to the internet to see listings.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Check'),
              onPressed: _checkInitialConnectivity,
            )
          ],
        ),
      ),
    );
  }
  // --- End Offline Message Widget ---

  // --- Listing Stream Widget (Adapted from home_screen.dart) ---
  Widget _buildListingStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logger.e('Firestore Error',
              error: snapshot.error, stackTrace: snapshot.stackTrace);
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'Error loading listings. Please try again later.\n${snapshot.error}',
                      textAlign: TextAlign.center)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No listings found matching your Firestore query.'));
        }

        // Process Firestore data into ForRent objects
        List<ForRent> listings = processFirestoreListings(snapshot.data!);

        // --- Apply Client-Side Filters ---
        listings = listings.where((listing) {
          // Price Range Filter
          if (_activeFilters.priceRange != null &&
              (listing.price < _activeFilters.priceRange!.start ||
                  listing.price > _activeFilters.priceRange!.end)) {
            return false;
          }
          // Street Filter (Case-insensitive contains)
          if (_activeFilters.street != null &&
              !listing.address
                  .toLowerCase()
                  .contains(_activeFilters.street!.toLowerCase())) {
            return false;
          }
          // Gender Filter (Only apply if it's a Bedspace)
          if (_activeFilters.gender != null &&
              listing is Bedspace &&
              listing.gender.name != _activeFilters.gender) {
            return false;
          }
          return true;
        }).toList();
        // --- End Client-Side Filters ---

        if (listings.isEmpty) {
          return const Center(
              child: Text('No listings found matching all filter criteria.'));
        }

        // Use ListView.builder with the filtered list
        return ListView.builder(
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final ForRent listing =
                listings[index]; // Get the actual listing object
            return buildListing(listing); // Pass the ForRent object
          },
        );
      },
    );
  }
  // --- End Listing Stream Widget ---

  Widget buildMenu() {
    final User? currentUser = _auth.currentUser;
    final bool isLoggedIn = currentUser != null;

    return Drawer(
      child: Container(
        color: const Color(0xFFede9f3),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Use UserAccountsDrawerHeader for a standard look
            UserAccountsDrawerHeader(
              accountName: Text(
                (_fullName ?? (isLoggedIn ? "User" : "Guest")) +
                    (_accountType != null ? " ($_accountType)" : ""),
              ),
              accountEmail: Text(currentUser?.email ?? "Not signed in"),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor, // Use theme color
              ),
              // currentAccountPicture: CircleAvatar(
              //   // Add user image if available
              //   // backgroundImage: NetworkImage(currentUser?.photoURL ?? ''),
              // ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile (Not Implemented)')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text("Bookmarks"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Bookmarks (Not Implemented)')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Settings (Not Implemented)')));
              },
            ),
            const Divider(),
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[700]),
                title:
                    Text('Log Out', style: TextStyle(color: Colors.red[700])),
                onTap: () async {
                  Navigator.pop(context); // Close drawer first
                  try {
                    await _auth.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    await Future.wait([
                      prefs.remove("accountType"),
                      prefs.remove("fullName"),
                      // Remove other relevant user data from prefs
                    ]);
                    logger.i("User logged out successfully.");
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Successfully logged out.')));
                    // No need to call setState here, auth listener handles UI update
                  } catch (e, s) {
                    logger.e("Error logging out", error: e, stackTrace: s);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error logging out: $e')));
                  }
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Log In / Sign Up'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to your Login/Signup Screen
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Login/Signup (Not Implemented)')));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      backgroundColor: Colors.white, // Ensure background is white
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter filterSetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                // Wrap the Column with SingleChildScrollView
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20), // Move padding here
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Keep this for Column
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text("Filters",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Type",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      // Use Filters.type ('apartment', 'bedspace', null)
                      RadioListTile<String?>(
                        title: const Text('Apartment'),
                        value: 'apartment',
                        groupValue: _tempFilters.type,
                        onChanged: (value) =>
                            filterSetState(() => _tempFilters.type = value),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      RadioListTile<String?>(
                        title: const Text('Bedspace'),
                        value: 'bedspace',
                        groupValue: _tempFilters.type,
                        onChanged: (value) =>
                            filterSetState(() => _tempFilters.type = value),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      RadioListTile<String?>(
                        // Option for 'Any' type
                        title: const Text('Any Type'),
                        value: null,
                        groupValue: _tempFilters.type,
                        onChanged: (value) =>
                            filterSetState(() => _tempFilters.type = value),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: 15),
                      const Text("Contract",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      // Use Filters.contract (bool?, true=with, false=no, null=any)
                      RadioListTile<bool?>(
                        title: const Text('With Contract'),
                        value: true,
                        groupValue: _tempFilters.contract,
                        onChanged: (value) =>
                            filterSetState(() => _tempFilters.contract = value),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      RadioListTile<bool?>(
                        title: const Text('No Contract'),
                        value: false,
                        groupValue: _tempFilters.contract,
                        onChanged: (value) =>
                            filterSetState(() => _tempFilters.contract = value),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      RadioListTile<bool?>(
                        // Option for 'Any' contract
                        title: const Text('Any Contract'),
                        value: null,
                        groupValue: _tempFilters.contract,
                        onChanged: (value) =>
                            filterSetState(() => _tempFilters.contract = value),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: 15),
                      const Text("Gender",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      // Use Filters.gender (String?, 'maleOnly', 'femaleOnly', 'any', null)
                      _buildGenderRadioTile(filterSetState, 'Male Only',
                          GenderPreference.maleOnly.name),
                      _buildGenderRadioTile(filterSetState, 'Female Only',
                          GenderPreference.femaleOnly.name),
                      _buildGenderRadioTile(filterSetState, 'Any Gender',
                          GenderPreference.any.name),
                      _buildGenderRadioTile(filterSetState, 'Not Specified',
                          null), // Option for 'Any'/null
                      const SizedBox(height: 15),
                      const Text("Street",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Universe St.',
                        ),
                        value: _tempFilters.street,
                        items: ['Universe St.', 'Galaxy Ave', 'Cosmic Rd']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList()
                          ..insert(
                              0,
                              const DropdownMenuItem<String>(
                                  value: null,
                                  child:
                                      Text('Any Street'))), // Add 'Any' option
                        onChanged: (String? newValue) => filterSetState(
                            () => _tempFilters.street = newValue),
                      ),
                      const SizedBox(height: 15),
                      const Text("Price Range",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 10000,
                        divisions: 100,
                        labels: RangeLabels(
                          // Use _tempFilters.priceRange
                          '₱${_tempFilters.priceRange?.start.round() ?? 0}',
                          '₱${_tempFilters.priceRange?.end.round() ?? 10000}',
                        ),
                        onChanged: (RangeValues values) => filterSetState(
                            () => _tempFilters.priceRange = values),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            child: const Text("Clear"),
                            onPressed: () => filterSetState(() {
                              _tempFilters = Filters(); // Reset temp filters
                            }),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            child: const Text("Save"),
                            onPressed: () {
                              // Apply temp filters to active filters and update state
                              setState(() {
                                _activeFilters = _tempFilters.copyWith();
                              });
                              Navigator.pop(context); // Close the bottom sheet
                              // The StreamBuilder will automatically rebuild with new filters
                              logger.i("Applied Filters: $_activeFilters");
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper for Gender Radio Tiles
  Widget _buildGenderRadioTile(
      StateSetter filterSetState, String title, String? value) {
    return RadioListTile<String?>(
      title: Text(title),
      value: value,
      groupValue: _tempFilters.gender,
      onChanged: (val) => filterSetState(() => _tempFilters.gender = val),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // --- buildListing Method (Kept mostly as is for now, using Map) ---
  Widget buildListing(ForRent listing) {
    // Accept ForRent object
    // TODO: Fetch actual image URL if available in ForRent object
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      // Use imageDownloadUrl, check for null and empty
                      image: NetworkImage(
                          (listing.imageDownloadUrl?.isNotEmpty ?? false)
                              ? listing.imageDownloadUrl!
                              : 'https://via.placeholder.com/300'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.8),
                    child: Text(
                      (listing.name.isNotEmpty)
                          ? listing.name.substring(0, 1).toUpperCase()
                          : '?', // Handle null/empty title
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(Icons.more_vert, color: Colors.grey),
                ),
                const Positioned(
                  bottom: 10,
                  right: 10,
                  child: Icon(Icons.bookmark_border, color: Colors.white),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      listing.name.isNotEmpty
                          ? listing.name
                          : 'Untitled Listing', // Use listing name
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  // Display the actual type (e.g., 'Apartment', 'Bedspace')
                  // Check runtime type to determine the listing type string
                  Text(
                      (listing is Apartment
                              ? 'Apartment'
                              : (listing is Bedspace ? 'Bedspace' : 'Listing'))
                          .capitalizeFirstLetter(),
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                      '₱${listing.price.toStringAsFixed(0)} / Month', // Use listing price
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // --- Dynamic Stars based on rating (Example) ---
                      ...(List.generate(5, (index) {
                        // Use listing.rating
                        if (index < listing.rating.floor()) {
                          return const Icon(Icons.star,
                              color: Colors.amber, size: 18);
                        }
                        if (index < listing.rating.ceil() &&
                            listing.rating % 1 >= 0.5) {
                          // Use listing.rating
                          return const Icon(Icons.star_half,
                              color: Colors.amber, size: 18);
                        }
                        return const Icon(Icons.star_border,
                            color: Colors.amber, size: 18);
                      })),
                      const SizedBox(width: 5),
                      Text(
                          listing.rating
                              .toStringAsFixed(1), // Use listing rating
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Cozy apartment with modern amenities, great location near public transportation and shops.",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize:
                            14), // Consider using listing.description if available
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

// Helper extension method (optional, place outside the class or in a utility file)
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
