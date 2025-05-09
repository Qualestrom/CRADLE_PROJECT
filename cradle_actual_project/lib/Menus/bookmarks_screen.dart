import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'dart:async';

import '../Back-End/for_rent.dart';
import '../Back-End/apartment.dart';
import '../Back-End/bedspace.dart';
import '../Back-End/firestore_mapper.dart'; // Ensure this file contains the FirestoreMapper class or function
import '../Renter UI/renter_apartment_details_screen.dart';
import '../Renter UI/renter_bedspacer_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  List<ForRent> _bookmarkedListings = [];
  bool _isLoading = true;
  String? _userId;
  StreamSubscription? _bookmarksListener;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    if (_userId != null) {
      _listenToBookmarkedListings();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bookmarksListener?.cancel();
    super.dispose();
  }

  void _listenToBookmarkedListings() {
    if (_userId == null || !mounted) return;

    _bookmarksListener = _db
        .collection('users')
        .doc(_userId!)
        .collection('bookmarks')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((bookmarkSnapshot) async {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      List<String> bookmarkedIds =
          bookmarkSnapshot.docs.map((doc) => doc.id).toList();
      List<ForRent> fetchedListings = [];

      for (String listingId in bookmarkedIds) {
        try {
          DocumentSnapshot listingDoc =
              await _db.collection('listings').doc(listingId).get();
          if (listingDoc.exists) {
            ForRent listing = await FirestoreMapper.mapDocumentToForRent(
                listingDoc); // Await the async call
            fetchedListings.add(listing);
          } else {
            _logger.w(
                "Bookmarked listing $listingId not found. It might have been deleted.");
            // Optionally, remove this stale bookmark from the user's bookmark collection
            // await _db.collection('users').doc(_userId!).collection('bookmarks').doc(listingId).delete();
          }
        } catch (e, s) {
          _logger.e("Error fetching details for bookmarked listing $listingId",
              error: e, stackTrace: s);
        }
      }
      if (mounted) {
        setState(() {
          _bookmarkedListings = fetchedListings;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      _logger.e("Error listening to bookmarked listings", error: error);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _removeBookmark(String listingId) async {
    if (_userId == null || !mounted) return;
    try {
      await _db
          .collection('users')
          .doc(_userId!)
          .collection('bookmarks')
          .doc(listingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from bookmarks.')),
      );
      // The listener will update the list automatically.
    } catch (e) {
      _logger.e("Error removing bookmark $listingId", error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing bookmark: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return _buildScaffoldWithCustomAppBar(
        context: context,
        title: 'My Bookmarks',
        body: const Center(child: Text('Please log in to see your bookmarks.')),
      );
    }

    if (_isLoading) {
      return _buildScaffoldWithCustomAppBar(
        context: context,
        title: 'My Bookmarks',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bookmarkedListings.isEmpty) {
      return _buildScaffoldWithCustomAppBar(
        context: context,
        title: 'My Bookmarks',
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('You haven\'t bookmarked any listings yet.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          ),
        ),
      );
    }

    return _buildScaffoldWithCustomAppBar(
      context: context,
      title: 'My Bookmarks',
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _bookmarkedListings.length,
        itemBuilder: (context, index) {
          final listing = _bookmarkedListings[index];
          // Using a simplified card, adapt your RenterHomeScreen's buildListing if needed
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            elevation: 2,
            child: ListTile(
              leading: listing.imageDownloadUrl != null &&
                      listing.imageDownloadUrl!.isNotEmpty
                  ? Image.network(listing.imageDownloadUrl!,
                      width: 70, height: 70, fit: BoxFit.cover)
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(Icons.apartment, color: Colors.white)),
              title: Text(listing.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '₱${listing.price.toStringAsFixed(0)} / Month\n${listing is Apartment ? 'Apartment' : 'Bedspace'}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: Icon(Icons.bookmark_remove_outlined,
                    color: Theme.of(context).colorScheme.error),
                onPressed: () => _removeBookmark(listing.uid),
                tooltip: 'Remove from bookmarks',
              ),
              onTap: () {
                if (listing is Bedspace) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              BedspacerListing(listingId: listing.uid)));
                } else if (listing is Apartment) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ApartmentListing(listingId: listing.uid)));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// Helper to build Scaffold with the custom AppBar
Widget _buildScaffoldWithCustomAppBar({
  required BuildContext context,
  required String title,
  required Widget body,
  List<Widget>? actions,
}) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Padding(
        padding: const EdgeInsets.only(
            top: 48.0, bottom: 10.0, left: 16.0, right: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEF7FF),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                  child: Center(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87)))),
              if (actions != null && actions.isNotEmpty)
                ...actions
              else
                const SizedBox(
                    width: 48), // Placeholder for alignment if no actions
            ],
          ),
        ),
      ),
    ),
    body: body,
  );
}
