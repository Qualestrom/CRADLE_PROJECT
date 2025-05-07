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
import '../Test/apartment.dart'; 
import '../Test/bedspace.dart'; 
import 'renter_bedspacer_screen.dart'; 
import 'renter_apartment_details_screen.dart'; 

// String extension to capitalize first letter
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(); 
  runApp(const MyApp()); 
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
      home: const ApartmentListings(),
    );
  }
}

class ApartmentListings extends StatefulWidget {
  const ApartmentListings({super.key});

  @override
  State<ApartmentListings> createState() => _ApartmentListingsState();
}

class _ApartmentListingsState extends State<ApartmentListings> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger logger = Logger();

  // State for filters
  Filters _activeFilters = Filters();
  late Filters _tempFilters; // For the filter sheet
  
  // Key for the Scaffold to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State for user info from SharedPreferences
  String? _accountType;
  String? _fullName;

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

  // --- Connectivity Methods ---
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

  // Firestore query builder with filters
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

    return query;
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter filterSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Type", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        title: const Text('Any Type'),
                        value: null,
                        groupValue: _tempFilters.type,
                        onChanged: (value) =>
                            filterSetState(() => _tempFilters.type = value),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: 15),
                      const Text("Contract", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        title: const Text('Any Contract'),
                        value: null,
                        groupValue: _tempFilters.contract,
                        onChanged: (value) =>
                            filterSetState(() => _tempFilters.contract = value),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: 15),
                      const Text("Gender", style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildGenderRadioTile(filterSetState, 'Male Only', 
                          GenderPreference.maleOnly.name),
                      _buildGenderRadioTile(filterSetState, 'Female Only',
                          GenderPreference.femaleOnly.name),
                      _buildGenderRadioTile(filterSetState, 'Any Gender',
                          GenderPreference.any.name),
                      _buildGenderRadioTile(filterSetState, 'Not Specified', null),
                      const SizedBox(height: 15),
                      const Text("Street", style: TextStyle(fontWeight: FontWeight.bold)),
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
                                  child: Text('Any Street'))),
                        onChanged: (String? newValue) => filterSetState(
                            () => _tempFilters.street = newValue),
                      ),
                      const SizedBox(height: 15),
                      const Text("Price Range", style: TextStyle(fontWeight: FontWeight.bold)),
                      RangeSlider(
                        values: _tempFilters.priceRange ?? const RangeValues(0, 10000),
                        min: 0,
                        max: 10000,
                        divisions: 100,
                        labels: RangeLabels(
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
                              setState(() {
                                _activeFilters = _tempFilters.copyWith();
                              });
                              Navigator.pop(context);
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

  Widget _buildMenu() {
    final User? currentUser = _auth.currentUser;
    final bool isLoggedIn = currentUser != null;

    return Drawer(
      child: Container(
        color: const Color(0xFFede9f3),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                (_fullName ?? (isLoggedIn ? "User" : "Guest")) +
                    (_accountType != null ? " ($_accountType)" : ""),
              ),
              accountEmail: Text(currentUser?.email ?? "Not signed in"),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
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
                  Navigator.pop(context);
                  try {
                    await _auth.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    await Future.wait([
                      prefs.remove("accountType"),
                      prefs.remove("fullName"),
                    ]);
                    logger.i("User logged out successfully.");
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Successfully logged out.')));
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Login/Signup (Not Implemented)')));
                },
              ),
          ],
        ),
      ),
    );
  }

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

  // Main listing stream widget
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
              child: Text('No listings found matching your criteria.'));
        }

        // Process Firestore data into ForRent objects
        List<ForRent> listings = processFirestoreListings(snapshot.data!);

        // Apply Client-Side Filters
        listings = listings.where((listing) {
          // Price Range Filter - FIXED: Now properly checking against active filters
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

        if (listings.isEmpty) {
          return const Center(
              child: Text('No listings found matching all filter criteria.'));
        }

        // Use ListView.builder with the filtered list
        return ListView.builder(
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final ForRent listing = listings[index]; 
            return buildListing(listing);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFECE6F0), // FIXED: Using the color scheme from design
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                const Text(
                  'Home',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_alt_outlined, 
                    color: _activeFilters.isFiltering
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black87, // Highlight if filters active
                  ),
                  onPressed: _openFilterSheet,
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: _buildMenu(),
      body: _isConnected
          ? _buildListingStream()
          : _buildOfflineMessage(), // Switch body based on connectivity
    );
  }

  // Custom listing widget for ForRent object
  Widget buildListing(ForRent listing) {
    return Card(
      color: const Color(0xFFF7F2FA), // FIXED: Using the color scheme from design
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: InkWell(
        onTap: () {
          // Navigate based on listing type
          if (listing is Bedspace) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BedspacerListing(listingId: listing.uid),
              ),
            );
          } else if (listing is Apartment) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApartmentDetailsScreen(listingId: listing.uid),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple[400], // FIXED: Using the color scheme from design
                    child: Text(
                        listing.name.isNotEmpty ? listing.name[0].toUpperCase() : '',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listing.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          (listing is Apartment
                              ? 'Apartment'
                              : (listing is Bedspace ? 'Bedspace' : 'Listing'))
                          .capitalizeFirstLetter(),
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Colors.grey), // FIXED: Using the correct icon
                ],
              ),
            ),

            // Listing Image
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      (listing.imageDownloadUrl?.isNotEmpty ?? false)
                          ? listing.imageDownloadUrl!
                          : 'https://via.placeholder.com/300'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Details section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₱${listing.price.toStringAsFixed(0)} / Month', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.bookmark_border, color: Color(0xFF878585)), // FIXED: Using the correct icon
                    ],
                  ),
                  // Contract display based on contract value
                  Text(listing.contract > 0 
                      ? '${listing.contract} Year Contract' 
                      : 'No Contract'),
                  Row(
                    children: [
                      // FIXED: Dynamic stars based on listing rating
                      ...List.generate(5, (index) {
                        if (index < listing.rating.floor()) {
                          return const Icon(Icons.star, color: Color(0xFF878585), size: 16);
                        }
                        if (index < listing.rating.ceil() && listing.rating % 1 >= 0.5) {
                          return const Icon(Icons.star_half, color: Color(0xFF878585), size: 16);
                        }
                        return const Icon(Icons.star_border, color: Color(0xFF878585), size: 16);
                      }),
                      const SizedBox(width: 4),
                      Text(listing.rating.toStringAsFixed(1), 
                           style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.description.isNotEmpty 
                        ? listing.description 
                        : 'This is comfy and has all the amenities you need.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

