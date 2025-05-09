import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'dart:async';

// Import your models and helpers (adjust paths as needed)
import '../Back-End/for_rent.dart';
import '../Back-End/filters.dart';
import '../Back-End/firestore_mapper.dart';
import '../Back-End/apartment.dart';
import '../Back-End/bedspace.dart';
import 'renter_bedspacer_screen.dart';
import 'renter_apartment_details_screen.dart';
import '../utils/string_extensions.dart';
import '../User/settle_now.dart'; // Import the WelcomeScreen
import "../Menus/bookmarks_screen.dart";

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
      home: const RenterHomeScreen(),
    );
  }
}

class RenterHomeScreen extends StatefulWidget {
  const RenterHomeScreen({super.key});

  @override
  State<RenterHomeScreen> createState() => _RenterHomeScreenState();
}

class _RenterHomeScreenState extends State<RenterHomeScreen> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger logger = Logger();

  // State for filters
  Filters _activeFilters = Filters();
  late Filters _tempFilters; // For the filter sheet

  // State for price range
  // final RangeValues _priceRange = const RangeValues(0, 10000); // Default range

  // Key for the Scaffold to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State for user info from SharedPreferences
  String? _accountType;
  String? _fullName;

  // --- Connectivity State ---
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOfflineDialogShowing = false;
  // --- Bookmark State ---
  Set<String> _bookmarkedListingIds = {};
  StreamSubscription? _bookmarksSubscription;
  StreamSubscription<User?>? _authSubscription; // For auth state changes
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
    // Listen to auth state changes
    _authSubscription = _auth.authStateChanges().listen((user) {
      _loadUserInfo(); // Reload user info on auth state change
      // Listen to bookmarks if user is logged in, otherwise clear
      if (mounted) {
        if (user != null) {
          _listenToBookmarks();
        } else {
          _bookmarksSubscription?.cancel();
          setState(() {
            _bookmarkedListingIds.clear();
          });
        }
        setState(() {}); // Update drawer on auth change
      }
    });
    // Initial bookmark listen if user is already logged in
    if (_auth.currentUser != null) {
      _listenToBookmarks();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel(); // Cancel listener
    _bookmarksSubscription?.cancel();
    _authSubscription?.cancel(); // Cancel auth state listener
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

  // --- Bookmark Methods ---
  void _listenToBookmarks() {
    _bookmarksSubscription?.cancel(); // Cancel previous subscription
    final user = _auth.currentUser;
    if (user != null && mounted) {
      _bookmarksSubscription = _db
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _bookmarkedListingIds = snapshot.docs.map((doc) => doc.id).toSet();
          });
        }
      }, onError: (error) {
        logger.e("Error listening to bookmarks", error: error);
      });
    } else if (mounted) {
      setState(() {
        _bookmarkedListingIds.clear();
      });
    }
  }

  Future<void> _toggleBookmark(
      ForRent listing, bool isCurrentlyBookmarked) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to bookmark listings.')),
      );
      return;
    }

    final bookmarkRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(listing.uid);

    try {
      if (isCurrentlyBookmarked) {
        await bookmarkRef.delete();
        _showBookmarkDialog(listing.name, false);
      } else {
        await bookmarkRef.set({
          'listingName':
              listing.name, // Store some basic info for the bookmarks screen
          'listingType': listing is Apartment
              ? 'apartment'
              : (listing is Bedspace ? 'bedspace' : 'unknown'),
          'timestamp': FieldValue.serverTimestamp(),
          'imageDownloadUrl': listing.imageDownloadUrl ??
              '', // Store image URL for quick access
          'price': listing.price,
        });
        _showBookmarkDialog(listing.name, true);
      }
      // The listener _listenToBookmarks will handle the state update for _bookmarkedListingIds
    } catch (e) {
      logger.e("Error toggling bookmark for ${listing.uid}", error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bookmarks: ${e.toString()}')),
      );
    }
  }

  void _showBookmarkDialog(String listingName, bool added) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(added ? 'Added to Bookmarks' : 'Removed from Bookmarks'),
          content: Text(
            added
                ? '"${listingName.capitalizeFirstLetter()}" has been added to your bookmarks.'
                : '"${listingName.capitalizeFirstLetter()}" has been removed from your bookmarks.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
  // --- End Bookmark Methods ---

  Future<void> _loadUserInfo() async {
    if (!mounted) return;
    logger.i("Attempting to load user info...");

    final prefs = await SharedPreferences.getInstance();
    // Try to load from SharedPreferences first
    String? prefFullName = prefs.getString(
        "fullName"); // Use "fullName" key for SharedPreferences cache
    String? prefAccountType = prefs.getString("accountType");

    logger.i(
        "From SharedPreferences: fullName='$prefFullName', accountType='$prefAccountType'");

    User? currentUser = _auth.currentUser;
    logger.i("Current Firebase user: ${currentUser?.uid ?? 'null'}");

    // If user is logged in but info is missing from SharedPreferences, fetch from Firestore
    if (currentUser != null) {
      if (prefFullName == null || prefAccountType == null) {
        logger.i(
            "Full name or account type missing from SharedPreferences, attempting to fetch from Firestore for UID: ${currentUser.uid}");
        try {
          DocumentSnapshot userDoc =
              await _db.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists) {
            logger.i("Firestore document found for UID: ${currentUser.uid}");
            final data = userDoc.data() as Map<String, dynamic>?;

            if (data != null) {
              // Fetch 'name' from Firestore (signup_renter saves it as 'name')
              if (prefFullName == null && data.containsKey('name')) {
                prefFullName = data['name'] as String?;
                logger.i("Name from Firestore: '$prefFullName'");
                if (prefFullName != null) {
                  // Save to SharedPreferences using "fullName" key for caching
                  await prefs.setString("fullName", prefFullName);
                  logger.i(
                      "Saved '$prefFullName' to SharedPreferences for key 'fullName'");
                }
              }
              // Fetch 'accountType' from Firestore
              if (prefAccountType == null && data.containsKey('accountType')) {
                prefAccountType = data['accountType'] as String?;
                logger.i("AccountType from Firestore: '$prefAccountType'");
                if (prefAccountType != null) {
                  await prefs.setString("accountType", prefAccountType);
                  logger.i(
                      "Saved '$prefAccountType' to SharedPreferences for key 'accountType'");
                }
              }
            } else {
              logger.w(
                  "Firestore document data is null for UID: ${currentUser.uid}");
            }
          } else {
            logger.w("No Firestore document found for UID: ${currentUser.uid}");
          }
        } catch (e, s) {
          logger.e(
              "Error fetching user info from Firestore for UID: ${currentUser.uid}",
              error: e,
              stackTrace: s);
        }
      }
    }

    if (mounted) {
      logger.i(
          "Setting state with fullName='$prefFullName', accountType='$prefAccountType'");
      setState(() {
        _fullName = prefFullName; // Update the state variable
        _accountType = prefAccountType; // Update the state variable
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
                      const Text("Contract",
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                      const Text("Gender",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildGenderRadioTile(filterSetState, 'Male Only',
                          GenderPreference.maleOnly.name),
                      _buildGenderRadioTile(filterSetState, 'Female Only',
                          GenderPreference.femaleOnly.name),
                      _buildGenderRadioTile(filterSetState, 'Any Gender',
                          GenderPreference.any.name),
                      _buildGenderRadioTile(
                          filterSetState, 'Not Specified', null),
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
                                  value: null, child: Text('Any Street'))),
                        onChanged: (String? newValue) => filterSetState(
                            () => _tempFilters.street = newValue),
                      ),
                      const SizedBox(height: 15),
                      const Text("Price Range",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      RangeSlider(
                        values: _tempFilters.priceRange ??
                            const RangeValues(0, 10000),
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
              onTap: () async {
                Navigator.pop(context);
                // Ensure user is logged in before navigating
                if (_auth.currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please log in to view bookmarks.')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BookmarksScreen()),
                );
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
                    // Navigate to WelcomeScreen and remove all previous routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
                      (Route<dynamic> route) => false,
                    );
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
              child: Text('No listings found matching your Firestore query.'));
        }

        // Use FutureBuilder to handle the async processing of listings (fetching image URLs)
        return FutureBuilder<List<ForRent>>(
            future:
                processFirestoreListings(snapshot.data!), // This is now async
            builder: (context, asyncListingsSnapshot) {
              if (asyncListingsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                // You might want a more subtle loading indicator if images are loading one by one
                // or if this takes time. For now, a general one.
                return const Center(
                    child: CircularProgressIndicator(
                        key: ValueKey("listings_loading")));
              }

              if (asyncListingsSnapshot.hasError) {
                logger.e('Error processing listings (image URLs)',
                    error: asyncListingsSnapshot.error);
                return Center(
                    child: Text(
                        'Error loading listing details: ${asyncListingsSnapshot.error}'));
              }

              if (!asyncListingsSnapshot.hasData ||
                  asyncListingsSnapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No listings found after processing.'));
              }

              List<ForRent> listings = asyncListingsSnapshot.data!;

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
                    child: Text(
                        'No listings found matching all filter criteria.'));
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
            });
      },
    );
  }

  // --- Report Listing Methods ---
  void _showReportDialog(ForRent listing) {
    if (!mounted) {
      logger.w(
          "Attempted to show report dialog on a disposed widget for listing: ${listing.name}");
      return;
    }

    final reportReasonController = TextEditingController();
    final formKey = GlobalKey<FormState>(); // For validating the reason

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use dialogContext for operations within the dialog
        return AlertDialog(
          title: const Text('Report Listing'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    "You are reporting the listing: \"${listing.name.capitalizeFirstLetter()}\". Please state your reason below.",
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 15),
                TextFormField(
                  controller: reportReasonController,
                  decoration: const InputDecoration(
                    hintText: 'Reason for reporting...',
                    border: OutlineInputBorder(),
                    labelText: 'Report Reason',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a reason for your report.';
                    }
                    if (value.trim().length < 10) {
                      return 'Please provide a more detailed reason (at least 10 characters).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                reportReasonController
                    .dispose(); // Dispose controller when dialog is dismissed
              },
            ),
            ElevatedButton(
              child: const Text('Submit Report'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _submitReport(listing, reportReasonController.text.trim());
                  Navigator.of(dialogContext).pop(); // Close the dialog first
                  reportReasonController.dispose(); // Then dispose controller
                }
              },
            ),
          ],
        );
      },
    );
    // Note: reportReasonController is created within this method's scope.
    // It will be disposed when the dialog is dismissed or when this method completes if the dialog isn't shown.
    // However, explicitly disposing it in the dialog's dismiss actions is safer.
  }

  Future<void> _submitReport(ForRent listing, String reason) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to submit a report.')),
        );
      }
      return;
    }
    if (!_isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No internet connection. Please try again later.')),
        );
      }
      return;
    }

    try {
      await _db.collection('reports').add({
        'listingId': listing.uid, // UID of the reported listing
        'listingName': listing.name, // Name of the listing for easier reference
        // 'listingOwnerId': listing.ownerId, // If you have ownerId on ForRent model
        'reporterUid': currentUser.uid,
        'reporterEmail': currentUser.email, // Optional: for easier contact
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending_review', // Initial status of the report
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Report submitted successfully. Thank you!')),
        );
      }
      logger.i(
          "Report submitted for listing ${listing.uid} by user ${currentUser.uid}");
    } catch (e, s) {
      logger.e('Error submitting report', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
        );
      }
    }
  }
  // --- End Report Listing Methods ---

  // --- Refresh Logic ---
  Future<void> _handleRefresh() async {
    // 1. Check connectivity again (optional, but good practice)
    await _checkInitialConnectivity();

    // 2. If connected, trigger a rebuild.
    // This will cause _buildListingStream to be called again.
    // The StreamBuilder will get the latest snapshot from Firestore.
    // The FutureBuilder within _buildListingStream will re-execute
    // processFirestoreListings, effectively refreshing image URLs and other processed data.
    if (_isConnected && mounted) {
      setState(() {});
    }
    // 3. You can return a Future.delayed if you want to ensure the indicator
    //    is visible for a minimum duration, but setState usually handles it.
    return;
  }

  @override
  Widget build(BuildContext context) {
    // Using AnnotatedRegion for better control over system UI overlay
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // Status bar color for Android. For a seamless look with your AppBar,
        // you might want it transparent or matching your AppBar's background.
        statusBarColor: Colors.transparent, // Or match your AppBar background
        // Status bar icon brightness (Android). Brightness.dark means dark icons.
        statusBarIconBrightness: Brightness.dark,
        // Status bar brightness (iOS). Brightness.dark means dark content (icons/text).
        statusBarBrightness: Brightness
            .light, // For iOS, Brightness.light means light background, dark content
      ),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.only(
                top: 48.0,
                bottom: 10.0,
                left: 16.0,
                right: 16.0), // Increased top padding
            child: Container(
              decoration: BoxDecoration(
                color: const Color(
                    0xFFFBEFFD), // FIXED: Using the color scheme from design
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
                        color: Colors.black87),
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
            ? RefreshIndicator(
                onRefresh: _handleRefresh, child: _buildListingStream())
            : _buildOfflineMessage(), // Switch body based on connectivity
      ),
    );
  }

  // Custom listing widget for ForRent object
  Widget buildListing(ForRent listing) {
    final bool isBookmarked = _bookmarkedListingIds.contains(listing.uid);
    return Card(
      color:
          const Color(0xFFFBEFFD), // FIXED: Using the color scheme from design
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
                builder: (context) => ApartmentListing(listingId: listing.uid),
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
                    backgroundColor: const Color(
                        0xFF6750A4), // FIXED: Using the color scheme from design
                    child: Text(
                        listing.name.isNotEmpty
                            ? listing.name[0].toUpperCase()
                            : '',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listing.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            (listing is Apartment
                                    ? 'Apartment'
                                    : (listing is Bedspace
                                        ? 'Bedspace'
                                        : 'Listing'))
                                .capitalizeFirstLetter(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (String result) {
                      if (result == 'report') {
                        _showReportDialog(listing);
                      }
                      // Add more actions here if needed in the future
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Text('Report'),
                      ),
                    ],
                  ),
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                              scale: animation, child: child);
                        },
                        child: IconButton(
                          key: ValueKey<bool>(
                              isBookmarked), // Essential for AnimatedSwitcher
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked
                                ? Theme.of(context).primaryColor
                                : const Color(0xFF878585),
                          ),
                          onPressed: () {
                            _toggleBookmark(listing, isBookmarked);
                          },
                        ),
                      ),
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
                          return const Icon(Icons.star,
                              color: Color(0xFF878585), size: 16);
                        }
                        if (index < listing.rating.ceil() &&
                            listing.rating % 1 >= 0.5) {
                          return const Icon(Icons.star_half,
                              color: Color(0xFF878585), size: 16);
                        }
                        return const Icon(Icons.star_border,
                            color: Color(0xFF878585), size: 16);
                      }),
                      const SizedBox(width: 4),
                      Text(listing.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.otherDetails.isNotEmpty
                        ? listing.otherDetails
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
