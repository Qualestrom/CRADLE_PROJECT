import 'dart:io'; // Required for File type if using image_picker

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:intl/intl.dart'; // For date/time formatting
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:logger/logger.dart'; // Import logger

import 'apartment.dart'; // Assuming you have these models defined
import 'bedspace.dart'; // Assuming you have these models defined
import 'for_rent.dart'; // Assuming you have these models defined
// --- Data Models (Assuming similar structure to your Java models) ---
// You'll need to define these based on your exact Firestore structure
// Add toJson methods for saving data

// --- Enum for Property Type ---
enum PropertyType { apartment, bedspace }

// Initialize logger for this file
final logger = Logger();

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
  final _formKey = GlobalKey<FormState>(); // For form validation
  late String _docId; // Will hold the document ID (generated if new)

  // Firebase Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // State Variables
  bool _isLoading = false;
  bool _isSaving = false;
  PropertyType _selectedType = PropertyType.apartment; // Default type

  // Image Handling
  XFile? _pickedImage; // From image_picker
  String? _imageUrl; // URL from Firebase Storage (for display)
  String? _imageFilename; // Filename in Firebase Storage

  // Text Editing Controllers
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _otherDetailsController = TextEditingController();
  final _contractYearsController = TextEditingController();
  // Apartment specific
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _capacityController = TextEditingController();
  // Bedspace specific
  final _roommateCountController = TextEditingController();
  final _bathroomShareCountController = TextEditingController();

  // Toggle States
  bool _billsIncluded = false;
  final Set<String> _selectedBills = {}; // e.g., {'water', 'electricity'}
  bool _hasCurfew = false;
  bool _hasContract = false;

  // Time Pickers
  TimeOfDay _curfewFromTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _curfewToTime = const TimeOfDay(hour: 4, minute: 0);
  final DateFormat _timeFormatter = DateFormat('h:mm a'); // From intl package

  @override
  void initState() {
    super.initState();
    _docId = widget.docId ??
        _db.collection('listings').doc().id; // Generate ID if new

    if (!widget.isNew && widget.docId != null) {
      _fetchInitialData();
    } else {
      // Set default states for a new listing if needed
      _updateCurfewButtonText(); // Set initial text
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

  // --- Data Fetching ---
  Future<void> _fetchInitialData() async {
    if (widget.docId == null) return;
    setState(() => _isLoading = true);

    try {
      final docSnapshot =
          await _db.collection('listings').doc(widget.docId!).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final String type =
            data['type'] ?? 'apartment'; // Assuming you store a 'type' field

        ForRent forRent;
        if (type == 'apartment') {
          _selectedType = PropertyType.apartment;
          forRent = Apartment.fromJson(docSnapshot.id, data);
          final apartment = forRent as Apartment;
          _bedroomsController.text = apartment.noOfBedrooms.toString();
          _bathroomsController.text = apartment.noOfBathrooms.toString();
          _capacityController.text = apartment.capacity.toString();
        } else {
          // Assuming bedspace
          _selectedType = PropertyType.bedspace;
          forRent = Bedspace.fromJson(docSnapshot.id, data);
          final bedspace = forRent as Bedspace;
          _roommateCountController.text = bedspace.roommateCount.toString();
          _bathroomShareCountController.text =
              bedspace.bathroomShareCount.toString();
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
          try {
            _imageUrl = await _storage
                .ref()
                .child(_imageFilename!)
                .getDownloadURL(); // Changed print to logger.e
          } catch (e, s) {
            logger.e("Error getting image URL for $_imageFilename",
                error: e, stackTrace: s);
            // Handle image loading error (e.g., show placeholder)
          }
        }

        // Bills Included
        if (forRent.billsIncluded.isNotEmpty) {
          _billsIncluded = true;
          _selectedBills.addAll(forRent.billsIncluded);
        } else {
          _billsIncluded = false;
          _selectedBills.clear();
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
                  "Error parsing curfew string: Invalid format '${forRent.curfew}'"); // Changed print to logger.w
              _hasCurfew = false; // Reset if format is wrong
            }
          } catch (e, s) {
            _hasCurfew = false; // Reset on parsing error
            logger.e(
                "Error parsing curfew time from string '${forRent.curfew}'",
                error: e,
                stackTrace: s); // Changed print to logger.e
          }
        } else {
          _hasCurfew = false;
        }
        _updateCurfewButtonText(); // Update button text after parsing or defaulting

        // Contract
        if (forRent.contract > 0) {
          _hasContract = true;
          _contractYearsController.text = forRent.contract.toString();
        } else {
          _hasContract = false;
        }
      } else {
        // Handle document not found
        logger.w(
            "Document ${widget.docId} not found during edit fetch!"); // Changed print to logger.w
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing not found.')),
          );
          Navigator.pop(context); // Go back if listing doesn't exist
        }
      }
    } catch (e, s) {
      logger.e("Error fetching data for doc ${widget.docId}",
          error: e, stackTrace: s); // Changed print to logger.e
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
        logger.i('No image selected via picker.'); // Changed print to logger.i
      }
    } catch (e, s) {
      logger.e("Error picking image",
          error: e, stackTrace: s); // Changed print to logger.e
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    if (_auth.currentUser == null) return null; // Check user auth

    setState(() => _isSaving = true); // Show loading indicator during upload
    // Declare filename outside the try block to make it accessible in catch
    final String filename = _imageFilename ?? '${const Uuid().v4()}.jpg';

    try {
      final file = File(imageFile.path);
      final ref =
          _storage.ref().child(filename); // Store in root or a subfolder
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _imageFilename = filename; // Store the filename used
      _imageUrl = downloadUrl; // Store the download URL
      logger.i(
          'Image upload successful: $downloadUrl (Filename: $filename)'); // Changed print to logger.i
      return downloadUrl;
    } catch (e, s) {
      logger.e("Error uploading image $filename",
          error: e, stackTrace: s); // Changed print to logger.e
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.toString()}')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        // Don't set _isSaving false here if part of a larger save operation
        // setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showTimePicker(bool isFromTime) async {
    final initialTime = isFromTime ? _curfewFromTime : _curfewToTime;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isFromTime ? "Set curfew start time" : "Set curfew end time",
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
        // Show the 'to' picker after 'from' is confirmed
        _showTimePicker(false);
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
  String _curfewButtonText = '';
  void _updateCurfewButtonText() {
    setState(() {
      _curfewButtonText =
          '${_formatTimeOfDay(_curfewFromTime)} - ${_formatTimeOfDay(_curfewToTime)}';
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
      final uploadSuccess = await _uploadImage(_pickedImage!);
      if (uploadSuccess == null) {
        // Handle upload failure
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image upload failed. Please try again.')),
        );
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
      logger.w(
          "Saving new listing without an image."); // Changed print to logger.w
    }

    // 2. Prepare data object
    final uid = _auth.currentUser!.uid;
    final name = _nameController.text.trim();
    final contactPerson = _contactPersonController.text.trim();
    final contactNumber = _contactNumberController.text.trim();
    final address = _addressController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final otherDetails = _otherDetailsController.text.trim();

    final List<String> bills = _billsIncluded ? _selectedBills.toList() : [];
    final String? curfew = _hasCurfew
        ? '${_formatTimeOfDay(_curfewFromTime)} - ${_formatTimeOfDay(_curfewToTime)}'
        : null;
    final int contract = _hasContract
        ? (int.tryParse(_contractYearsController.text.trim()) ?? 0)
        : 0;

    const double latitude = 13.785176;
    const double longitude = 121.073863;

    ForRent listingData;

    try {
      if (_selectedType == PropertyType.apartment) {
        final bedrooms = int.tryParse(_bedroomsController.text.trim()) ?? 0;
        final bathrooms = int.tryParse(_bathroomsController.text.trim()) ?? 0;
        final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

        listingData = Apartment(
          uid: uid,
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

        listingData = Bedspace(
          uid: uid,
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
          gender: GenderPreference.any, // Default or set based on user input
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
    } catch (e) {
      if (mounted) {
        logger.e("Error saving data for doc $_docId",
            error: e); // Changed print to logger.e
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Property' : 'Edit Property'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveData,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                // Use ListView for scrollable content
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Property Type Toggle ---
                  _buildSectionTitle('Property Type'),
                  ToggleButtons(
                    isSelected: [
                      _selectedType == PropertyType.apartment,
                      _selectedType == PropertyType.bedspace,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _selectedType = index == 0
                            ? PropertyType.apartment
                            : PropertyType.bedspace;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    constraints: BoxConstraints(
                        minWidth: (MediaQuery.of(context).size.width - 40) / 2,
                        minHeight: 40.0), // Adjust width
                    children: const [
                      Text('Apartment'),
                      Text('Bedspace'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Image Section ---
                  _buildSectionTitle('Property Image'),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: double.infinity, // Make it wider
                          height: 200, // Adjust height as needed
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            // Clip the image to the container's bounds
                            borderRadius: BorderRadius.circular(8.0),
                            child: _pickedImage != null
                                ? Image.file(
                                    File(_pickedImage!.path),
                                    fit: BoxFit.cover, // Cover the area
                                    width: double.infinity,
                                    height: 200,
                                  )
                                : _imageUrl != null
                                    ? Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover, // Cover the area
                                        width: double.infinity,
                                        height: 200,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          return progress == null
                                              ? child
                                              : const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey));
                                        },
                                      )
                                    : const Center(
                                        child: Icon(Icons.house_outlined,
                                            size: 60, color: Colors.grey)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingActionButton.small(
                            onPressed: _pickImage,
                            tooltip: 'Select Image',
                            child: const Icon(Icons.add_a_photo),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Basic Details ---
                  _buildSectionTitle('Basic Details'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Property Name / Title',
                        border: OutlineInputBorder()),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactPersonController,
                    decoration: const InputDecoration(
                        labelText: 'Contact Person',
                        border: OutlineInputBorder()),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a contact person'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactNumberController,
                    decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a contact number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        labelText: 'Full Address',
                        border: OutlineInputBorder()),
                    maxLines: 2,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter an address'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                        labelText: 'Price (per month)',
                        prefixText: '₱ ',
                        border: OutlineInputBorder()),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter a price';
                      if (double.tryParse(value) == null)
                        return 'Please enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Apartment Specific Details ---
                  if (_selectedType == PropertyType.apartment) ...[
                    _buildSectionTitle('Apartment Details'),
                    TextFormField(
                      controller: _bedroomsController,
                      decoration: const InputDecoration(
                          labelText: 'Number of Bedrooms',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _validateIntField(value, 'bedrooms'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bathroomsController,
                      decoration: const InputDecoration(
                          labelText: 'Number of Bathrooms',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _validateIntField(value, 'bathrooms'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                          labelText: 'Capacity (Max Persons)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _validateIntField(value, 'capacity'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Bedspace Specific Details ---
                  if (_selectedType == PropertyType.bedspace) ...[
                    _buildSectionTitle('Bedspace Details'),
                    TextFormField(
                      controller: _roommateCountController,
                      decoration: const InputDecoration(
                          labelText: 'Number of Roommates (in the room)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _validateIntField(value, 'roommates'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bathroomShareCountController,
                      decoration: const InputDecoration(
                          labelText: 'Bathroom is Shared With (Persons)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _validateIntField(value, 'persons sharing bathroom'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Additional Details ---
                  _buildSectionTitle('Additional Details'),

                  // Bills Included Toggle + Chips
                  _buildToggleRow(
                    label: 'Bills Included?',
                    value: _billsIncluded,
                    onChanged: (value) =>
                        setState(() => _billsIncluded = value),
                  ),
                  if (_billsIncluded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          _buildFilterChip('water', 'Water'),
                          _buildFilterChip('electricity', 'Electricity'),
                          _buildFilterChip('internet', 'Internet'),
                          _buildFilterChip('lpg', 'LPG'),
                          // Add more chips as needed
                        ],
                      ),
                    ),

                  // Curfew Toggle + Time Picker Button
                  _buildToggleRow(
                    label: 'Curfew?',
                    value: _hasCurfew,
                    onChanged: (value) => setState(() => _hasCurfew = value),
                  ),
                  if (_hasCurfew)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(
                            _curfewButtonText), // Display selected time range
                        onPressed: () =>
                            _showTimePicker(true), // Start with 'from' picker
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                                double.infinity, 40), // Make button wider
                            alignment: Alignment.centerLeft,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12)),
                      ),
                    ),

                  // Contract Toggle + Years Input
                  _buildToggleRow(
                    label: 'Contract?',
                    value: _hasContract,
                    onChanged: (value) => setState(() => _hasContract = value),
                  ),
                  if (_hasContract)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: TextFormField(
                        controller: _contractYearsController,
                        decoration: const InputDecoration(
                            labelText: 'Contract Duration (Years)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateIntField(
                            value, 'contract years',
                            allowZero: false),
                      ),
                    ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherDetailsController,
                    decoration: const InputDecoration(
                        labelText: 'Other Details / House Rules',
                        hintText: 'e.g., No pets allowed, Visitors policy...',
                        border: OutlineInputBorder()),
                    maxLines: 4,
                    // No validator needed unless specific rules apply
                  ),
                  const SizedBox(height: 24), // Bottom padding
                ],
              ),
            ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper for integer field validation
  String? _validateIntField(String? value, String fieldName,
      {bool allowZero = true}) {
    if (value == null || value.isEmpty) return 'Please enter $fieldName';
    final number = int.tryParse(value);
    if (number == null) return 'Please enter a valid whole number';
    if (!allowZero && number <= 0)
      return '$fieldName must be greater than zero';
    if (number < 0) return '$fieldName cannot be negative'; // General case
    return null;
  }

  Widget _buildToggleRow(
      {required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap, // Reduce tap area slightly
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedBills.contains(key);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedBills.add(key);
          } else {
            _selectedBills.remove(key);
          }
        });
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }
}
