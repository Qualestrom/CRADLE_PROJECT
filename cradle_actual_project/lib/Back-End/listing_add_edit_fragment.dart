import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../utils/string_extensions.dart'; // Assuming you have this extension for string manipulations

import 'apartment.dart'; // Assuming you have these models defined
import 'bedspace.dart' as bedspace_model; // Alias to avoid conflict
// --- Data Models (Assuming similar structure to your Java models) ---
// You'll need to define these based on your exact Firestore structure
// Add toJson methods for saving data

// --- Enum for Property Type ---
enum PropertyType { apartment, bedspace } // Keep this enum

// Initialize logger
final Logger logger = Logger();

// --- Flutter Widget ---
class ListingAddEditScreen extends StatefulWidget {
  final bool isNew;
  final String? docId; // Document ID if editing, null if new

  const ListingAddEditScreen({
    super.key,
    required this.isNew,
    this.docId,
  });

  @override
  State<ListingAddEditScreen> createState() => _ListingAddEditScreenState();
}

class _ListingAddEditScreenState extends State<ListingAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _docId;

  // Firebase Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // State Variables
  bool _isLoading = false;
  bool _isSaving = false;
  PropertyType _selectedType = PropertyType.apartment; // Use enum

  // Image Handling
  XFile? _pickedImage;
  String? _imageUrl;
  String? _imageFilename;

  // Text Editing Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _contactNumberController;
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;
  late final TextEditingController _otherDetailsController;
  late final TextEditingController _contractYearsController;
  // Apartment specific
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController; // For apartment
  late final TextEditingController _capacityController;
  // Bedspace specific
  late final TextEditingController _roommateCountController;
  late final TextEditingController
      _bathroomShareCountController; // For bedspace
  final DateFormat _timeFormatter = DateFormat('h:mm a'); // From intl package

  @override
  void initState() {
    super.initState();
    _docId = widget.docId ??
        _db.collection('listings').doc().id; // Generate ID if new

    // Initialize controllers
    _nameController = TextEditingController();
    _contactPersonController = TextEditingController();
    _contactNumberController = TextEditingController();
    _addressController = TextEditingController();
    _priceController = TextEditingController();
    _otherDetailsController = TextEditingController();
    _contractYearsController = TextEditingController();
    _bedroomsController = TextEditingController();
    _bathroomsController = TextEditingController();
    _capacityController = TextEditingController();
    _roommateCountController = TextEditingController();
    _bathroomShareCountController = TextEditingController();

    if (!widget.isNew && widget.docId != null) {
      _fetchInitialData();
    } else {
      // Set default states for a new listing if needed
      _updateCurfewButtonText(); // Set initial text
      _updateContractButtonText(); // Set initial text for contract
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _otherDetailsController.dispose();
    _contractYearsController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _capacityController.dispose();
    _roommateCountController.dispose();
    _bathroomShareCountController.dispose();
    super.dispose();
  }

  // Toggle States and related data (from owner_edit.dart)
  final Set<String> _selectedBills = {};
  bool _hasCurfew = false;
  TimeOfDay _curfewFromTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _curfewToTime = const TimeOfDay(hour: 4, minute: 0);
  String _curfewButtonText = 'No curfew';
  bool _hasContract = false;
  String _contractButtonText = 'No contract';
  String _selectedContractUnit = 'Year/s'; // Default unit

  // Bedspace Gender State
  String _selectedGenderString = 'Any Gender'; // Default for UI dropdown

  // --- Data Fetching ---
  Future<void> _fetchInitialData() async {
    if (widget.docId == null) return;
    setState(() => _isLoading = true);

    try {
      final docSnapshot =
          await _db.collection('listings').doc(widget.docId!).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        // Get the 'type' field from Firestore, it might be null or have different casing.
        final String? typeStringFromDb = data['type'] as String?;

        dynamic forRent; // This will hold the Apartment or Bedspace object

        // Determine the type and create the corresponding object
        // Use toLowerCase() for case-insensitive comparison.
        if (typeStringFromDb?.toLowerCase() == 'apartment') {
          _selectedType = PropertyType.apartment;
          forRent = Apartment.fromJson(docSnapshot.id, data);
          final apartment = forRent as Apartment;
          _bedroomsController.text = apartment.noOfBedrooms.toString();
          _bathroomsController.text = apartment.noOfBathrooms.toString();
          _capacityController.text = apartment.capacity.toString();
        } else if (typeStringFromDb?.toLowerCase() == 'bedspace') {
          _selectedType = PropertyType.bedspace;
          forRent = bedspace_model.Bedspace.fromJson(docSnapshot.id, data);
          final bedspace = forRent as bedspace_model.Bedspace;
          _roommateCountController.text = bedspace.roommateCount.toString();
          _bathroomShareCountController.text =
              bedspace.bathroomShareCount.toString();
          _selectedGenderString =
              _genderEnumToString(bedspace.gender); // Initialize gender UI
        } else {
          // Handle cases where 'type' is missing or is an unknown value.
          if (typeStringFromDb == null) {
            // If 'type' field is completely missing, default to apartment (as per previous logic)
            // but log a warning.
            logger.w(
                "Listing type field is missing for document ${widget.docId}. Defaulting to 'apartment'.");
            _selectedType = PropertyType.apartment;
            forRent = Apartment.fromJson(docSnapshot.id, data);
            // Attempt to populate apartment specific fields; they will use defaults from the model if fields are missing in data.
            final apartment = forRent as Apartment;
            _bedroomsController.text = apartment.noOfBedrooms.toString();
            _bathroomsController.text = apartment.noOfBathrooms.toString();
            _capacityController.text = apartment.capacity.toString();
          } else {
            // If 'type' field exists but is an unknown/unhandled value.
            logger.e(
                "Unknown listing type '$typeStringFromDb' for document ${widget.docId}. Cannot reliably edit.");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Error: Unknown listing type "$typeStringFromDb". Cannot load data.')),
              );
              Navigator.pop(
                  context); // Go back as we can't process this listing
            }
            setState(() => _isLoading = false);
            return; // Exit _fetchInitialData early to prevent a crash
          }
        }

        // Populate common fields
        _nameController.text = forRent.name;
        _contactPersonController.text = forRent.contactPerson;
        _contactNumberController.text = forRent.contactNumber;
        _addressController.text = forRent.address;
        _priceController.text =
            forRent.price.toStringAsFixed(0); // Adjust formatting as needed
        _otherDetailsController.text = forRent.otherDetails;

        // Image
        _imageFilename = forRent.imageFilename;
        if (_imageFilename != null && _imageFilename!.isNotEmpty) {
          String pathInStorage = ''; // Initialize pathInStorage
          try {
            const String expectedPrefix = 'listing_images/';

            // Determine the correct path in Firebase Storage.
            // Handles cases where _imageFilename might already contain the prefix (e.g., from older data).
            if (_imageFilename!.startsWith(expectedPrefix)) {
              pathInStorage = _imageFilename!;
            } else {
              pathInStorage =
                  '$expectedPrefix$_imageFilename'; // Removed trailing '!'
            }

            final String downloadUrl = await _storage
                .ref(pathInStorage) // Use the determined path
                .getDownloadURL();
            if (mounted) {
              // Check mounted before setState
              setState(() => _imageUrl = downloadUrl);
            }
          } catch (e, s) {
            // Log the original _imageFilename from Firestore and the path we attempted to fetch
            logger.e(
                "Error getting image URL. Original imageFilename from Firestore: '$_imageFilename'. Attempted path: '$pathInStorage'",
                error: e,
                stackTrace: s);
            if (mounted) {
              // Check mounted before setState
              setState(() {
                _imageFilename =
                    null; // Clear if fetch fails to prevent re-saving stale data
                _imageUrl = null; // Ensure UI shows a placeholder
              });
            }
          }
        }

        // Bills Included
        _selectedBills.clear(); // Clear before populating
        if (forRent.billsIncluded.isNotEmpty) {
          _selectedBills
              .addAll(forRent.billsIncluded.map((b) => b.toLowerCase()));
        }

        // Curfew
        if (forRent.curfew != null && forRent.curfew!.isNotEmpty) {
          _hasCurfew = true;
          try {
            final parts = forRent.curfew!.split(' - ');
            if (parts.length == 2) {
              // Attempt to parse using the expected format
              final fromFormat = DateFormat('h:mm a');
              final toFormat = DateFormat('h:mm a');
              final fromDateTime = fromFormat.parse(parts[0].trim());
              final toDateTime = toFormat.parse(parts[1].trim());
              _curfewFromTime = TimeOfDay.fromDateTime(fromDateTime);
              _curfewToTime = TimeOfDay.fromDateTime(toDateTime);
            } else {
              logger.w(
                  "Error parsing curfew string: Invalid format '${forRent.curfew}' for doc ${widget.docId}");
              _hasCurfew = false; // Reset if format is wrong
            }
          } catch (e, s) {
            _hasCurfew = false; // Reset on parsing error
            logger.e(
                "Error parsing curfew time from string '${forRent.curfew}'",
                error: e,
                stackTrace: s);
          }
        } else {
          _hasCurfew = false;
        }
        _updateCurfewButtonText(); // Update button text after parsing or defaulting

        // Contract
        if (forRent.contract > 0) {
          _hasContract = true;
          _contractYearsController.text = forRent.contract.toString();
          _selectedContractUnit = 'Year/s'; // Assuming years from model
        } else {
          _hasContract = false;
          _contractYearsController.text = '0';
        }
        _updateContractButtonText();
      } else {
        // Handle document not found
        logger.w("Document ${widget.docId} not found during edit fetch!");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing not found.')),
          );
          Navigator.pop(context); // Go back if listing doesn't exist
        }
      }
    } catch (e, s) {
      logger.e("Error fetching data for doc ${widget.docId}",
          error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI Callbacks ---

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
          _imageUrl =
              null; // Clear previous network image URL if a new file is picked
        });
        // Optional: Immediately upload or wait until save
        // await _uploadImage(pickedFile); // Example: upload immediately
      } else {
        logger.i('No image selected via picker.');
      }
    } catch (e, s) {
      logger.e("Error picking image", error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    if (_auth.currentUser == null) return null; // Check user auth

    // setState(() => _isSaving = true); // Handled by _saveData
    // Declare filename outside the try block to make it accessible in catch
    final String filename = _imageFilename ?? '${const Uuid().v4()}.jpg';

    try {
      final file = File(imageFile.path);
      // Store in a specific folder like 'listing_images'
      final ref = _storage.ref().child('listing_images/$filename');
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _imageFilename = filename; // Store the filename used
      _imageUrl = downloadUrl; // Store the download URL
      logger.i('Image upload successful: $downloadUrl (Filename: $filename)');
      return downloadUrl;
    } catch (e, s) {
      logger.e("Error uploading image $filename", error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.toString()}')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        // Don't set _isSaving false here if part of a larger save operation
        // setState(() => _isSaving = false); // Handled by _saveData
      }
    }
  }

  Future<void> _showTimePicker(bool isFromTime) async {
    final initialTime = isFromTime ? _curfewFromTime : _curfewToTime;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isFromTime ? "Set curfew start time" : "Set curfew end time",
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF9C27B0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
              secondary: Color(0xFF9C27B0),
              onSecondary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9C27B0)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isFromTime) {
          _curfewFromTime = selectedTime;
          // Optionally show the 'to' picker immediately after 'from' is selected
          // Future.delayed(Duration.zero, () => _showTimePicker(false));
        } else {
          _curfewToTime = selectedTime;
        }
        _updateCurfewButtonText(); // Update display text
      });
      if (isFromTime) {
        // Show the 'to' picker after 'from' is confirmed using Future.microtask
        Future.microtask(() => _showTimePicker(false));
      }
    }
  }

  // Helper to format TimeOfDay for display
  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return _timeFormatter.format(dt);
  }

  // Helper to update the curfew button text state
  void _updateCurfewButtonText() {
    setState(() {
      _curfewButtonText =
          '${_formatTimeOfDay(_curfewFromTime)} - ${_formatTimeOfDay(_curfewToTime)}';
    });
  }

  // Helper to update the contract button text state
  void _updateContractButtonText() {
    setState(() {
      final duration = _contractYearsController.text.trim();
      _contractButtonText = _hasContract
          ? '${duration.isNotEmpty ? duration : '0'} $_selectedContractUnit'
          : 'No contract';
    });
  }

  // --- Data Saving ---
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't save if form is invalid
    }
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // 1. Upload image if a new one was picked
    if (_pickedImage != null) {
      final uploadedUrl = await _uploadImage(_pickedImage!);
      if (uploadedUrl == null) {
        // Handle upload failure
        setState(() => _isSaving = false);
        return; // Stop saving process
      }
    } else if (_imageUrl == null && _imageFilename == null && widget.isNew) {
      // Handle case where no image is provided for a new listing (if required)
      // You might want to enforce image selection
      // setState(() => _isSaving = false);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Please select an image.')),
      // );
      // return;
      logger.w("Saving new listing without an image.");
    }

    // 2. Prepare data object
    final uid = _auth.currentUser!.uid;
    final name = _nameController.text.trim();
    final contactPerson = _contactPersonController.text.trim();
    final contactNumber = _contactNumberController.text.trim();
    final address = _addressController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final otherDetails = _otherDetailsController.text.trim();

    // Derive bills directly from _selectedBills
    final List<String> bills =
        _selectedBills.map((b) => b.capitalizeFirstLetter()).toList();
    final String curfew = _hasCurfew // Changed from String? to String
        ? '${_formatTimeOfDay(_curfewFromTime)} - ${_formatTimeOfDay(_curfewToTime)}'
        : ""; // Send empty string instead of null
    final int contract = _hasContract // Use _hasContract state
        ? (int.tryParse(_contractYearsController.text.trim()) ?? 0)
        : 0;

    const double latitude = 13.785176;
    const double longitude = 121.073863;

    dynamic listingData; // Use dynamic if the type will be determined later

    try {
      if (_selectedType == PropertyType.apartment) {
        final bedrooms = int.tryParse(_bedroomsController.text.trim()) ?? 0;
        final bathrooms = int.tryParse(_bathroomsController.text.trim()) ?? 0;
        final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

        listingData = Apartment(
          uid: _docId, // Use the listing's document ID
          ownerId: uid, // Use the current user's UID as the ownerId
          imageFilename: _imageFilename ?? '', // Store filename
          name: name,
          contactPerson: contactPerson,
          contactNumber: contactNumber,
          price: price,
          billsIncluded: bills,
          address: address,
          curfew: curfew,
          contract: contract,
          latitude: latitude,
          longitude: longitude,
          otherDetails: otherDetails,
          noOfBedrooms: bedrooms,
          noOfBathrooms: bathrooms,
          capacity: capacity,
        );
      } else {
        // Bedspace
        final roommateCount =
            int.tryParse(_roommateCountController.text.trim()) ?? 0;
        final bathroomShareCount =
            int.tryParse(_bathroomShareCountController.text.trim()) ?? 0;
        final gender = _genderStringToEnum(_selectedGenderString);
        listingData = bedspace_model.Bedspace(
          // Use aliased name
          uid: _docId, // Use the listing's document ID
          ownerId: uid, // Use the current user's UID as the ownerId
          imageFilename: _imageFilename ?? '', // Store filename
          name: name,
          contactPerson: contactPerson,
          contactNumber: contactNumber,
          price: price,
          billsIncluded: bills,
          address: address,
          curfew: curfew,
          contract: contract,
          latitude: latitude,
          longitude: longitude,
          otherDetails: otherDetails,
          roommateCount: roommateCount,
          bathroomShareCount: bathroomShareCount,
          gender: gender,
        );
      }

      // 3. Save to Firestore
      await _db.collection('listings').doc(_docId).set(listingData.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isNew
                  ? 'Listing added successfully!'
                  : 'Listing updated successfully!')),
        );
        // Navigate back - adjust destination route as needed
        Navigator.pop(context);
        // Or: Navigator.popUntil(context, ModalRoute.withName('/myProperties')); // Example
      }
    } catch (e, s) {
      if (mounted) {
        logger.e("Error saving data for doc $_docId", error: e, stackTrace: s);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Update button texts based on current state before building
    // REMOVED: _updateCurfewButtonText(); // This was causing setState in build
    // REMOVED: _updateContractButtonText(); // This was causing setState in build

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                children: [
                  _buildCustomAppBar(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Type'),
                  _buildPropertyTypeSelector(),
                  const SizedBox(height: 16),
                  _buildSectionLabel('Basic Details'),
                  _buildTextField(
                    _nameController,
                    labelText: 'Property Name / Title',
                    hintText: 'e.g., Cozy Apartment, Bedspace near Campus',
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _contactPersonController,
                    labelText: 'Contact Person',
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a contact person'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _contactNumberController,
                    labelText: 'Contact Number',
                    inputType: TextInputType.phone,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a contact number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _addressController,
                    labelText: 'Full Address',
                    maxLines: 2,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter an address'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _priceController,
                    labelText: 'Price (per month)',
                    inputType:
                        const TextInputType.numberWithOptions(decimal: true),
                    hasPrefixText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType == PropertyType.apartment)
                    _buildApartmentDetails(),
                  if (_selectedType == PropertyType.bedspace)
                    _buildBedspaceDetails(),
                  _buildSectionLabel('Additional Details'),
                  _buildToggleSection(
                    title: 'Bills Included',
                    value: _selectedBills.isEmpty
                        ? 'None'
                        : 'Selected (${_selectedBills.length})',
                    onTap: _isSaving ? null : _showBillsBottomSheet,
                    isChecked: _selectedBills.isNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  _buildToggleSection(
                    title: 'Curfew',
                    value: _hasCurfew ? _curfewButtonText : 'No curfew',
                    onTap: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _hasCurfew = !_hasCurfew; // Toggle the state
                              if (_hasCurfew) {
                                // If curfew is now enabled, immediately show the time picker.
                                // _showTimePicker will handle updating the button text if times are changed.
                                _showTimePicker(true);
                              } else {
                                // If curfew is disabled, just update the button text.
                                _updateCurfewButtonText();
                              }
                            });
                          },
                    isChecked: _hasCurfew,
                  ),
                  const SizedBox(height: 16),
                  _buildToggleSection(
                    title: 'Contract',
                    value: _contractButtonText,
                    onTap: _isSaving ? null : _showContractBottomSheet,
                    isChecked: _hasContract,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _otherDetailsController,
                    labelText: 'Other Details / House Rules',
                    hintText: 'e.g., No pets allowed, Visitors policy...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Property Image'),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: _pickedImage != null
                                ? Image.file(File(_pickedImage!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200)
                                : _imageUrl != null
                                    ? Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 200,
                                        loadingBuilder: (context, child,
                                                progress) =>
                                            progress == null
                                                ? child
                                                : const Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Center(
                                                child: Icon(Icons.broken_image,
                                                    size: 50,
                                                    color: Colors.grey)),
                                      )
                                    : const Center(
                                        child: Icon(Icons.house_outlined,
                                            size: 60, color: Colors.grey)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingActionButton.small(
                            onPressed: _isSaving ? null : _pickImage,
                            tooltip: 'Select Image',
                            child: const Icon(Icons.add_a_photo),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // --- Helper Widgets ---
  // (Copied and adapted from owner_edit.dart)

  Widget _buildCustomAppBar() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECE6F0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.isNew ? "Add Property" : "Edit Property",
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.purple),
                  onPressed: _saveData,
                ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPropertyTypeSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isSaving
                  ? null
                  : () =>
                      setState(() => _selectedType = PropertyType.apartment),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedType == PropertyType.apartment
                      ? const Color(0xFFDFD5EC)
                      : Colors.transparent,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(25)),
                  border: _selectedType == PropertyType.apartment
                      ? Border.all(color: Colors.black, width: 1.0)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedType == PropertyType.apartment)
                      const Icon(Icons.check, color: Colors.black, size: 18),
                    if (_selectedType == PropertyType.apartment)
                      const SizedBox(width: 4),
                    Text(
                      'Apartment',
                      style: TextStyle(
                        fontWeight: _selectedType == PropertyType.apartment
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _isSaving
                  ? null
                  : () => setState(() => _selectedType = PropertyType.bedspace),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedType == PropertyType.bedspace
                      ? const Color(0xFFDFD5EC)
                      : Colors.transparent,
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(25)),
                  border: _selectedType == PropertyType.bedspace
                      ? Border.all(color: Colors.black, width: 1.0)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedType == PropertyType.bedspace)
                      const Icon(Icons.check, color: Colors.black, size: 18),
                    if (_selectedType == PropertyType.bedspace)
                      const SizedBox(width: 4),
                    Text(
                      'Bedspace',
                      style: TextStyle(
                        fontWeight: _selectedType == PropertyType.bedspace
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
    bool hasPrefixText = false,
    int maxLines = 1,
    String? labelText,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
        // Changed to TextFormField for validation
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(
              color: Color(0xFF49454F),
              fontSize: 12,
              fontWeight: FontWeight.bold),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: hintText,
          prefixText: hasPrefixText ? '₱ ' : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                  onPressed: () {
                    controller.clear();
                    setState(
                        () {}); // To rebuild and hide suffix if text is cleared
                  },
                )
              : null,
        ),
        validator: validator,
        // Removed onChanged: (_) => setState(() {}). TextFormField rebuilds internally on controller changes.
        onChanged: (_) {
          /* If specific logic is needed on user input, add here, but avoid broad setState if possible */
        });
  }

  Widget _buildToggleSection({
    required String title,
    required String value,
    required VoidCallback? onTap,
    required bool isChecked,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: isChecked
                      ? const Color(0xFF757575)
                      : Colors.grey.shade300, // Adjusted color for unchecked
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isChecked)
                      const Icon(Icons.check, color: Colors.white, size: 18),
                    if (isChecked) const SizedBox(width: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: isChecked ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.horizontal(right: Radius.circular(25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(color: Color(0xFF878585)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, color: Color(0xFF878585), size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateIntField(String? value, String fieldName,
      {bool allowZero = true}) {
    if (value == null || value.isEmpty) return 'Please enter $fieldName';
    final number = int.tryParse(value);
    if (number == null) return 'Please enter a valid whole number';
    if (!allowZero && number <= 0) {
      return '$fieldName must be greater than zero';
    }
    if (number < 0) return '$fieldName cannot be negative'; // General case
    return null;
  }

  // Options for Bills Included Bottom Sheet
  static const List<Map<String, dynamic>> _billOptions = [
    {'label': 'Electricity', 'icon': Icons.flash_on, 'value': 'electricity'},
    {'label': 'Water', 'icon': Icons.water_drop, 'value': 'water'},
    {'label': 'Internet', 'icon': Icons.wifi, 'value': 'internet'},
    {'label': 'LPG', 'icon': Icons.local_fire_department, 'value': 'lpg'},
  ];

  void _showBillsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select included bills:',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _billOptions.map((option) {
                      bool isSelected =
                          _selectedBills.contains(option['value']);
                      return InkWell(
                        onTap: () {
                          setStateModal(() {
                            if (isSelected) {
                              _selectedBills.remove(option['value']);
                            } else {
                              _selectedBills.add(option['value']);
                            }
                          });
                          setState(() {}); // Update parent widget state
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (option['value'] == 'water'
                                    ? Colors.blue
                                    : option['value'] == 'electricity'
                                        ? Colors.amber
                                        : option['value'] == 'internet'
                                            ? Colors.indigo
                                            : Colors.purple)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(option['icon'],
                                  color:
                                      isSelected ? Colors.white : Colors.grey,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(option['label'],
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showContractBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for TextFields
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contract Duration:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  RadioListTile<bool>(
                    title: const Text('With contract'),
                    value: true,
                    groupValue: _hasContract,
                    onChanged: (value) =>
                        setStateModal(() => _hasContract = value!),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Without contract'),
                    value: false,
                    groupValue: _hasContract,
                    onChanged: (value) =>
                        setStateModal(() => _hasContract = value!),
                  ),
                  if (_hasContract) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contractYearsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (Years)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _validateIntField(
                          value, 'contract years',
                          allowZero: false),
                      onChanged: (_) => setStateModal(
                          () {}), // To update bottom sheet UI if needed
                    ),
                  ],
                  const SizedBox(height: 20), // Padding at the bottom
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(_updateContractButtonText);
                      },
                      child: const Text("Done"))
                ],
              ),
            );
          },
        );
      },
    ).then((_) => setState(
        _updateContractButtonText)); // Update button text when sheet closes
  }

  // Helper to map enum to string for dropdown display
  String _genderEnumToString(bedspace_model.GenderPreference gender) {
    switch (gender) {
      case bedspace_model.GenderPreference.any:
        return 'Any Gender';
      case bedspace_model.GenderPreference.maleOnly:
        return 'Male Only';
      case bedspace_model.GenderPreference.femaleOnly:
        return 'Female Only';
    }
  }

  // Helper to map string from dropdown back to enum
  bedspace_model.GenderPreference _genderStringToEnum(String? genderString) {
    if (genderString == 'Male Only') {
      return bedspace_model.GenderPreference.maleOnly;
    }
    if (genderString == 'Female Only') {
      return bedspace_model.GenderPreference.femaleOnly;
    }
    return bedspace_model.GenderPreference.any; // Default
  }

  Widget _buildApartmentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Apartment Specifics'), // Changed label for clarity
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _buildTextField(_bedroomsController,
                    labelText: 'Bedrooms',
                    inputType: TextInputType.number,
                    validator: (v) => _validateIntField(v, 'bedrooms'))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildTextField(_bathroomsController,
                    labelText: 'Bathrooms',
                    inputType: TextInputType.number,
                    validator: (v) => _validateIntField(v, 'bathrooms'))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildTextField(_capacityController,
                    labelText: 'Capacity',
                    inputType: TextInputType.number,
                    validator: (v) => _validateIntField(v, 'capacity'))),
          ],
        ),
        const SizedBox(height: 16), // Space after this section
      ],
    );
  }

  Widget _buildBedspaceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Bedspace Specifics'), // Changed label for clarity
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _buildTextField(_roommateCountController,
                    labelText: 'Bedslots',
                    inputType: TextInputType.number,
                    validator: (v) => _validateIntField(v, 'bedslots'))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildTextField(_bathroomShareCountController,
                    labelText: 'Shared Bathrooms',
                    inputType: TextInputType.number,
                    validator: (v) =>
                        _validateIntField(v, 'shared bathrooms'))),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGenderString,
          items: bedspace_model.GenderPreference.values
              .map((bedspace_model.GenderPreference genderEnum) {
            return DropdownMenuItem<String>(
              value: _genderEnumToString(genderEnum),
              child: Text(_genderEnumToString(genderEnum)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedGenderString = newValue;
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Gender Preference',
            labelStyle: const TextStyle(
                color: Color(0xFF49454F),
                fontSize: 12,
                fontWeight: FontWeight.bold),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          // No validator needed for dropdown unless you need to ensure a selection other than default
        ),
        const SizedBox(height: 16), // Space after this section
      ],
    );
  }

  // Helper extension for capitalizing first letter (if not already in a utility file)
}
