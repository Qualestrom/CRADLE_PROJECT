// // home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity
// import 'package:logger/logger.dart'; // Import logger
// import 'dart:async'; // Import for async

// // Import your models and helpers
// import 'for_rent.dart'; // Adjust path as needed
// import 'apartment.dart'; // Adjust path as needed
// import 'filters.dart'; // Adjust path as needed
// import 'firestore_mapper.dart'; // Adjust path as needed
// import 'listing_detail_fragment.dart'; // Adjust path as needed (your from_java.dart screen)

// // Initialize logger for this file
// final logger = Logger();

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   // State for filters
//   Filters _activeFilters = Filters();
//   late Filters _tempFilters; // For the filter sheet

//   // State for user info from SharedPreferences
//   String? _accountType;
//   String? _fullName;

//   // Key for the Scaffold to control the drawer
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   // --- Connectivity State ---
//   // Corrected: Subscription type matches the stream's event type (List)
//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//   bool _isOfflineDialogShowing = false;
//   bool _isConnected = true; // Assume connected initially

//   @override
//   void initState() {
//     super.initState();
//     _tempFilters = _activeFilters.copyWith();
//     _loadUserInfo(); // Load user info

//     // --- Connectivity Check ---
//     _checkInitialConnectivity();
//     // Corrected: Listen to the stream without incorrect casts
//     _connectivitySubscription =
//         Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
//     // --- End Connectivity Check ---

//     _auth.authStateChanges().listen((user) {
//       _loadUserInfo(); // Reload user info on auth state change
//       if (mounted) {
//         setState(() {}); // Update drawer on auth change
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel(); // Cancel listener
//     super.dispose();
//   }

//   // --- Connectivity Methods ---

//   // Function to check connectivity and show/hide dialog
//   // Accepts a single ConnectivityResult
//   Future<void> _checkConnectivity(ConnectivityResult result) async {
//     final currentlyConnected = result != ConnectivityResult.none;
//     if (mounted) {
//       setState(() {
//         _isConnected = currentlyConnected;
//       });
//     }

//     if (!currentlyConnected) {
//       if (!_isOfflineDialogShowing && mounted) {
//         setState(() {
//           _isOfflineDialogShowing = true;
//         });
//         _showOfflineDialog(); // Don't await
//       }
//     } else {
//       if (_isOfflineDialogShowing && mounted) {
//         Navigator.of(context, rootNavigator: true).pop();
//         // No need to setState for _isOfflineDialogShowing here,
//         // it's handled in the .then() of showDialog
//       }
//     }
//   }

//   // Check connectivity when the screen first loads
//   Future<void> _checkInitialConnectivity() async {
//     // Corrected: checkConnectivity returns a List
//     final results = await Connectivity().checkConnectivity();
//     // Process the first result (usually the most relevant)
//     // Default to 'none' if the list is unexpectedly empty
//     await _checkConnectivity(
//         results.isNotEmpty ? results.first : ConnectivityResult.none);
//   }

//   // Handle connectivity changes detected by the stream listener
//   // Corrected: Accepts List<ConnectivityResult> from the stream
//   void _handleConnectivityChange(List<ConnectivityResult> results) {
//     // Process the first result from the list
//     // Default to 'none' if the list is unexpectedly empty
//     _checkConnectivity(
//         results.isNotEmpty ? results.first : ConnectivityResult.none);
//   }

//   // Function to display the offline warning dialog
//   Future<void> _showOfflineDialog() async {
//     if (!mounted) return;

//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false, // User must tap button
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: const Row(
//             children: [
//               Icon(Icons.wifi_off_rounded, color: Colors.orange),
//               SizedBox(width: 10),
//               Text('No Internet Connection'),
//             ],
//           ),
//           content: const SingleChildScrollView(
//             child: ListBody(
//               children: <Widget>[
//                 Text(
//                     'This app requires an internet connection to fetch the latest listings.'),
//                 SizedBox(height: 8),
//                 Text('Please check your network settings.'),
//               ],
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Retry'),
//               onPressed: () async {
//                 // Manually trigger a re-check when retry is pressed
//                 // Corrected: checkConnectivity returns a List
//                 final results = await Connectivity().checkConnectivity();
//                 final result = results.isNotEmpty
//                     ? results.first
//                     : ConnectivityResult.none;

//                 // _checkConnectivity will handle dismissing the dialog if connected
//                 await _checkConnectivity(result); // Pass the single result

//                 // If still offline after retry, show a quick message
//                 if (result == ConnectivityResult.none && mounted) {
//                   ScaffoldMessenger.of(dialogContext).showSnackBar(
//                     const SnackBar(
//                       content: Text('Still offline. Please check connection.'),
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 }
//                 // No need to manually pop here, _checkConnectivity handles it if online
//               },
//             ),
//           ],
//         );
//       },
//     ).then((_) {
//       // This block executes when the dialog is popped (either by Navigator.pop
//       // or by pressing back button if barrierDismissible was true).
//       // Reset the flag ensuring it can be shown again if needed.
//       if (mounted) {
//         setState(() {
//           _isOfflineDialogShowing = false;
//         });
//       }
//     });
//   }
//   // --- End Connectivity Methods ---

//   Future<void> _loadUserInfo() async {
//     if (!mounted) return;
//     final prefs = await SharedPreferences.getInstance();
//     if (mounted) {
//       setState(() {
//         _accountType = prefs.getString("accountType");
//         _fullName = prefs.getString("fullName");
//       });
//     }
//   }

//   Query _buildFilteredQuery() {
//     Query query = _db.collection('listings');

//     // Option 2: Filter based on a dedicated 'type' field (Recommended)
//     if (_activeFilters.type != null) {
//       query = query.where('type',
//           isEqualTo: _activeFilters.type); // <-- Use 'type' here
//     }

//     // --- Contract Filter ---
//     if (_activeFilters.contract != null) {
//       query = query.where('contract', isEqualTo: _activeFilters.contract);
//     }

//     // --- Curfew Filter ---
//     if (_activeFilters.curfew != null) {
//       query = query.where('curfew', isEqualTo: _activeFilters.curfew);
//     }

//     // --- Ordering ---
//     query = query.orderBy('dateCreated', descending: true);
//     return query;
//   }

//   void _showFilterSheet() {
//     _tempFilters = _activeFilters.copyWith();
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setSheetState) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//                 top: 20,
//                 left: 20,
//                 right: 20,
//               ),
//               child: Wrap(
//                 children: [
//                   // Header
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text('Filters',
//                           style: Theme.of(context).textTheme.headlineSmall),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ],
//                   ),
//                   const Divider(height: 20, thickness: 1),

//                   // --- Type Filter ---
//                   Text('Listing Type',
//                       style: Theme.of(context).textTheme.titleMedium),
//                   RadioListTile<String?>(
//                     title: const Text('Apartment'),
//                     value: "APARTMENT",
//                     groupValue: _tempFilters.type,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.type = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   RadioListTile<String?>(
//                     title: const Text('Bedspace'),
//                     value: "BEDSPACE",
//                     groupValue: _tempFilters.type,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.type = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   RadioListTile<String?>(
//                     title: const Text('Any Type'),
//                     value: null,
//                     groupValue: _tempFilters.type,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.type = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   const Divider(height: 20, thickness: 1),

//                   // --- Contract Filter ---
//                   Text('Contract',
//                       style: Theme.of(context).textTheme.titleMedium),
//                   RadioListTile<bool?>(
//                     title: const Text('With Contract'),
//                     value: true,
//                     groupValue: _tempFilters.contract,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.contract = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   RadioListTile<bool?>(
//                     title: const Text('No Contract'),
//                     value: false,
//                     groupValue: _tempFilters.contract,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.contract = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   RadioListTile<bool?>(
//                     title: const Text('Any Contract'),
//                     value: null,
//                     groupValue: _tempFilters.contract,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.contract = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   const Divider(height: 20, thickness: 1),

//                   // --- Curfew Filter ---
//                   Text('Curfew',
//                       style: Theme.of(context).textTheme.titleMedium),
//                   RadioListTile<bool?>(
//                     title: const Text('With Curfew'),
//                     value: true,
//                     groupValue: _tempFilters.curfew,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.curfew = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   RadioListTile<bool?>(
//                     title: const Text('No Curfew'),
//                     value: false,
//                     groupValue: _tempFilters.curfew,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.curfew = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   RadioListTile<bool?>(
//                     title: const Text('Any Curfew'),
//                     value: null,
//                     groupValue: _tempFilters.curfew,
//                     onChanged: (value) =>
//                         setSheetState(() => _tempFilters.curfew = value),
//                     controlAffinity: ListTileControlAffinity.leading,
//                     contentPadding: EdgeInsets.zero,
//                   ),
//                   const Divider(height: 20, thickness: 1),

//                   // --- Action Buttons ---
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         OutlinedButton(
//                           onPressed: () {
//                             setSheetState(() {
//                               _tempFilters = Filters();
//                             });
//                             setState(() {
//                               _activeFilters = Filters();
//                             });
//                             Navigator.pop(context);
//                           },
//                           child: const Text('Clear All'),
//                         ),
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             minimumSize: const Size(120, 40),
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _activeFilters = _tempFilters.copyWith();
//                             });
//                             Navigator.pop(context);
//                           },
//                           child: const Text('Apply Filters'),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: MediaQuery.of(context).padding.bottom),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: const Text('Settle Now'),
//         actions: [
//           IconButton(
//             icon: Icon(
//               Icons.filter_list,
//               color: _activeFilters.isFiltering
//                   ? Theme.of(context).colorScheme.secondary
//                   : null,
//             ),
//             tooltip: 'Filters',
//             onPressed: _showFilterSheet,
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: _isConnected ? _buildListingStream() : _buildOfflineMessage(),
//     );
//   }

//   Widget _buildOfflineMessage() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey[600]),
//             const SizedBox(height: 20),
//             Text(
//               'No Internet Connection',
//               style: Theme.of(context).textTheme.headlineSmall,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Connect to the internet to see listings.',
//               style: Theme.of(context).textTheme.bodyLarge,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry Check'),
//               onPressed: _checkInitialConnectivity, // Manually trigger check
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildListingStream() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _buildFilteredQuery().snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           logger.e('Firestore Error',
//               error: snapshot.error,
//               stackTrace: snapshot.stackTrace); // Changed print to logger.e
//           return Center(
//               child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               'Error loading listings. Please try again later.\n${snapshot.error}',
//               textAlign: TextAlign.center,
//             ),
//           ));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Center(
//               child: Text('No listings found matching your criteria.'));
//         }

//         final List<ForRent> listings = processFirestoreListings(snapshot.data!);

//         return ListView.separated(
//           itemCount: listings.length,
//           separatorBuilder: (context, index) => const SizedBox(height: 4),
//           itemBuilder: (context, index) {
//             final listing = listings[index];
//             return ListingItemCard(
//               listing: listing,
//               storage: _storage,
//               onTap: () {
//                 if (_isConnected) {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) =>
//                           ListingDetailScreen(listingId: listing.uid),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Connect to the internet to view details.'),
//                       behavior: SnackBarBehavior.floating,
//                     ),
//                   );
//                 }
//               },
//             );
//           },
//           padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
//         );
//       },
//     );
//   }

//   Widget _buildDrawer() {
//     final User? currentUser = _auth.currentUser;
//     final bool isLoggedIn = currentUser != null;

//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           UserAccountsDrawerHeader(
//             accountName: Text(_fullName ?? (isLoggedIn ? "User" : "Guest")),
//             accountEmail: Text(currentUser?.email ?? "Not signed in"),
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.home_outlined),
//             title: const Text('Home'),
//             selected: true,
//             onTap: () => Navigator.pop(context),
//           ),
//           if (isLoggedIn && _accountType == "SELLER")
//             ListTile(
//               leading: const Icon(Icons.list_alt_outlined),
//               title: const Text('My Properties'),
//               onTap: () {
//                 Navigator.pop(context);
//                 logger.i(
//                     "Navigate to My Properties"); // Changed print to logger.i
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('My Properties (Not Implemented)')));
//               },
//             ),
//           if (isLoggedIn && _accountType == "BUYER")
//             ListTile(
//               leading: const Icon(Icons.favorite_outline),
//               title: const Text('My Favorites'),
//               onTap: () {
//                 Navigator.pop(context);
//                 logger.i("Navigate to Favorites"); // Changed print to logger.i
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('My Favorites (Not Implemented)')));
//               },
//             ),
//           const Divider(),
//           if (!isLoggedIn)
//             ListTile(
//               leading: const Icon(Icons.login),
//               title: const Text('Log In / Sign Up'),
//               onTap: () {
//                 Navigator.pop(context);
//                 logger
//                     .i("Navigate to Login/Signup"); // Changed print to logger.i
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text('Login/Signup (Not Implemented)')));
//               },
//             ),
//           if (isLoggedIn)
//             ListTile(
//               leading: Icon(Icons.logout, color: Colors.red[700]),
//               title: Text('Log Out', style: TextStyle(color: Colors.red[700])),
//               onTap: () async {
//                 Navigator.pop(context);
//                 try {
//                   await _auth.signOut();
//                   final prefs = await SharedPreferences.getInstance();
//                   await Future.wait([
//                     prefs.remove("accountType"),
//                     prefs.remove("fullName"),
//                   ]);
//                   logger.i(
//                       "User logged out successfully."); // Changed print to logger.i
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                         content: Text('Successfully logged out.')));
//                   }
//                 } catch (e, s) {
//                   // Include stack trace
//                   logger.e("Error logging out",
//                       error: e, stackTrace: s); // Changed print to logger.e
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Error logging out: $e')));
//                   }
//                 }
//               },
//             ),
//         ],
//       ),
//     );
//   }
// }

// // --- ListingItemCard Widget ---
// class ListingItemCard extends StatelessWidget {
//   final ForRent listing;
//   final FirebaseStorage storage;
//   final VoidCallback onTap;

//   const ListingItemCard({
//     super.key,
//     required this.listing,
//     required this.storage,
//     required this.onTap,
//   });

//   Future<String?> _getImageUrl() async {
//     if (listing.imageFilename.isEmpty) return null;
//     try {
//       return await storage.ref().child(listing.imageFilename).getDownloadURL();
//     } on FirebaseException catch (e) {
//       if (e.code == 'object-not-found') {
//         logger.w(
//             "Image not found for ${listing.imageFilename}"); // Changed print to logger.w
//       } else {
//         logger.e("Error getting image URL for ${listing.imageFilename}",
//             error: e); // Changed print to logger.e
//       }
//       return null;
//     } catch (e, s) {
//       // Include stack trace
//       logger.e("Generic error getting image URL for ${listing.imageFilename}",
//           error: e, stackTrace: s); // Changed print to logger.e
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String typeDisplay = listing is Apartment ? 'Apartment' : 'Bedspace';
//     final String priceText = '₱${listing.price.toStringAsFixed(0)}/month';
//     final textTheme = Theme.of(context).textTheme;
//     final colorScheme = Theme.of(context).colorScheme;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
//       clipBehavior: Clip.antiAlias,
//       elevation: 1.0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // --- Image ---
//               SizedBox(
//                 width: 100,
//                 height: 100,
//                 child: FutureBuilder<String?>(
//                   future: _getImageUrl(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return Container(
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                           child: const Center(
//                               child:
//                                   CircularProgressIndicator(strokeWidth: 2)));
//                     }
//                     if (snapshot.hasError ||
//                         !snapshot.hasData ||
//                         snapshot.data == null) {
//                       return Container(
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                           child: Center(
//                               child: Icon(Icons.house_siding_rounded,
//                                   color: Colors.grey[600], size: 40)));
//                     }
//                     // --- Display Image ---
//                     return ClipRRect(
//                       borderRadius: BorderRadius.circular(8.0),
//                       child: Image.network(snapshot.data!,
//                           width: 100, height: 100, fit: BoxFit.cover,
//                           loadingBuilder: (context, child, progress) {
//                         if (progress == null) return child;
//                         return Container(
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                           child: Center(
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               value: progress.expectedTotalBytes != null
//                                   ? progress.cumulativeBytesLoaded /
//                                       progress.expectedTotalBytes!
//                                   : null,
//                             ),
//                           ),
//                         );
//                       }, errorBuilder: (context, error, stackTrace) {
//                         // Renamed stack to stackTrace
//                         logger.e(
//                             "Image load error for ${listing.imageFilename}",
//                             error: error,
//                             stackTrace:
//                                 stackTrace); // Changed print to logger.e
//                         return Container(
//                             decoration: BoxDecoration(
//                               color: Colors.grey[300],
//                               borderRadius: BorderRadius.circular(8.0),
//                             ),
//                             child: Center(
//                                 child: Icon(Icons.broken_image_outlined,
//                                     color: Colors.grey[600], size: 40)));
//                       }),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(width: 12),
//               // --- Details ---
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       listing.name.isNotEmpty
//                           ? listing.name
//                           : 'Untitled Listing',
//                       style: textTheme.titleMedium
//                           ?.copyWith(fontWeight: FontWeight.bold),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       listing.address.isNotEmpty
//                           ? listing.address
//                           : 'No address provided',
//                       style: textTheme.bodySmall
//                           ?.copyWith(color: Colors.grey[600]),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           priceText,
//                           style: textTheme.titleSmall?.copyWith(
//                             color: colorScheme.primary,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Chip(
//                           label: Text(typeDisplay),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 6, vertical: 0),
//                           labelStyle: textTheme.labelSmall?.copyWith(
//                               color: colorScheme.onSecondaryContainer),
//                           visualDensity: VisualDensity.compact,
//                           backgroundColor: colorScheme.secondaryContainer,
//                           side: BorderSide.none,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
