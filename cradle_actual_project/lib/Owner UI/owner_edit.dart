import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edit Property',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: const EditPropertyScreen(propertyData: {}),
    );
  }
}

class EditPropertyScreen extends StatefulWidget {
  final Map<String, String> propertyData;

  const EditPropertyScreen({Key? key, required this.propertyData}) : super(key: key);

  @override
  _EditPropertyScreenState createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  String _selectedType = 'Apartment';
  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactNumberController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  Set<String> _selectedBills = {};
  TimeOfDay _curfewTime = const TimeOfDay(hour: 23, minute: 59);
  bool _hasContract = true;
  String _contractDuration = '1 Year/s';
  final TextEditingController _otherDetailsController = TextEditingController();

  // Controllers for Apartment Details
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsApartmentController; // Renamed to avoid conflict
  late TextEditingController _capacityController;

  // Controllers for Bedspace Details
  late TextEditingController _bedslotsController;
  late TextEditingController _bathroomsBedspaceController; // Renamed to avoid conflict
  String _selectedGender = 'Male'; // Default for Bedspace

  final List<Map<String, dynamic>> _billOptions = [
    {'label': 'Electricity', 'icon': Icons.flash_on, 'value': 'Electricity'},
    {'label': 'Water', 'icon': Icons.water_drop, 'value': 'Water'},
    {'label': 'Internet', 'icon': Icons.wifi, 'value': 'Internet'},
    {'label': 'LPG', 'icon': Icons.local_fire_department, 'value': 'LPG'},
  ];

  final List<String> _genderOptions = ['Male', 'Female', 'Mixed'];

  @override
  void initState() {
    super.initState();
    // Initialize common controllers
    _nameController = TextEditingController(text: widget.propertyData['title'] ?? 'ABC Apartment');
    _contactPersonController = TextEditingController(text: widget.propertyData['contactPerson'] ?? 'Juan Dela Cruz');
    _contactNumberController = TextEditingController(text: widget.propertyData['contactNumber'] ?? '09XXXXXXXXX');
    _addressController = TextEditingController(text: widget.propertyData['address'] ?? 'Block X Lot X ABC Street');
    _priceController = TextEditingController(text: widget.propertyData['price'] ?? '9,999.99');
    _selectedBills = {'Water'}; // Default or load from data
    _otherDetailsController.text = widget.propertyData['otherDetails'] ?? 'Add other details here...';

    // Initialize Apartment specific controllers
    _bedroomsController = TextEditingController(text: widget.propertyData['bedrooms'] ?? '2');
    _bathroomsApartmentController = TextEditingController(text: widget.propertyData['bathroomsApartment'] ?? '2');
    _capacityController = TextEditingController(text: widget.propertyData['capacity'] ?? '5');

    // Initialize Bedspace specific controllers and state
    _bedslotsController = TextEditingController(text: widget.propertyData['bedslots'] ?? '4');
    _bathroomsBedspaceController = TextEditingController(text: widget.propertyData['bathroomsBedspace'] ?? '1');
    _selectedGender = widget.propertyData['gender'] ?? 'Male';

    // Determine initial type based on data if available, default to Apartment
    _selectedType = widget.propertyData['type'] ?? 'Apartment';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _otherDetailsController.dispose();

    // Dispose Apartment specific controllers
    _bedroomsController.dispose();
    _bathroomsApartmentController.dispose();
    _capacityController.dispose();

    // Dispose Bedspace specific controllers
    _bedslotsController.dispose();
    _bathroomsBedspaceController.dispose();

    super.dispose();
  }

  void _saveChanges() {
    Map<String, String> updatedData = {
      'type': _selectedType,
      'title': _nameController.text,
      'contactPerson': _contactPersonController.text,
      'contactNumber': _contactNumberController.text,
      'address': _addressController.text,
      'price': _priceController.text,
      'billsIncluded': _selectedBills.join(', '),
      'curfew': '${_curfewTime.format(context)}',
      'contract': _hasContract ? _contractDuration : 'No contract',
      'otherDetails': _otherDetailsController.text,
    };

    // Add type-specific data
    if (_selectedType == 'Apartment') {
      updatedData.addAll({
        'bedrooms': _bedroomsController.text,
        'bathroomsApartment': _bathroomsApartmentController.text,
        'capacity': _capacityController.text,
      });
    } else if (_selectedType == 'Bedspace') {
      updatedData.addAll({
        'bedslots': _bedslotsController.text,
        'bathroomsBedspace': _bathroomsBedspaceController.text,
        'gender': _selectedGender,
      });
    }

    Navigator.pop(context, updatedData);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _curfewTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF9C27B0), // Purple for active elements (hand, selection, buttons)
              onPrimary: Colors.white, // Text/icons on the primary color
              surface: Colors.white, // Background of the clock face
              onSurface: Colors.black87, // Text/icons on the clock face (numbers, AM/PM) - using dark grey
               secondary: Color(0xFF9C27B0), // Secondary color might affect selection border/indicator
               onSecondary: Colors.white, // Text/icons on secondary color
            ),
             textButtonTheme: TextButtonThemeData( // To style the OK/CANCEL buttons
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9C27B0), // Button text color
                ),
             ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _curfewTime) {
      setState(() {
        _curfewTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        children: [
          _buildCustomAppBar(),
          const SizedBox(height: 20),

          _buildSectionLabel('Type'),
          _buildPropertyTypeSelector(),
          const SizedBox(height: 16),

          _buildTextField(_nameController, labelText: 'Name'),
          const SizedBox(height: 16),

          _buildTextField(_contactPersonController, labelText: 'Contact Person'),
          const SizedBox(height: 16),

          _buildTextField(_contactNumberController, labelText: 'Contact Number', inputType: TextInputType.phone),
          const SizedBox(height: 16),

          _buildTextField(_addressController, labelText: 'Address'),
          const SizedBox(height: 16),

          _buildTextField(_priceController, labelText: 'Price', inputType: TextInputType.number, hasPrefixText: true),
          const SizedBox(height: 16),

          _buildToggleSection(
            title: 'Bills Included',
            value: _selectedBills.isEmpty ? 'None' : 'Selected (${_selectedBills.length})',
            onTap: () => _showBillsBottomSheet(),
            isChecked: _selectedBills.isNotEmpty,
          ),
          const SizedBox(height: 16),

          _buildToggleSection(
            title: 'Curfew',
            value: _curfewTime.format(context),
            onTap: () => _selectTime(context),
            isChecked: true,
          ),
          const SizedBox(height: 16),

          _buildToggleSection(
            title: 'Contract',
            value: _hasContract ? _contractDuration : 'No contract',
            onTap: () => _showContractBottomSheet(),
            isChecked: _hasContract,
          ),
          const SizedBox(height: 16), // Space before details section

          // Conditionally render Apartment or Bedspace details
          if (_selectedType == 'Apartment')
            _buildApartmentDetails()
          else if (_selectedType == 'Bedspace')
            _buildBedspaceDetails(),

          // SizedBox is now included within the conditional detail sections
          // const SizedBox(height: 16), // This is now added at the end of _buildApartmentDetails/ _buildBedspaceDetails

          _buildSectionLabel('Other Details'),
          _buildTextField(_otherDetailsController, maxLines: 3, labelText: null), // labelText is null here
          const SizedBox(height: 24),

          _buildAddImagesButton(),
        ],
      ),
    );
  }

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
                "Edit Property",
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.purple),
            onPressed: _saveChanges,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Provides space before the next element
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
              onTap: () => setState(() => _selectedType = 'Apartment'),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedType == 'Apartment' ? const Color(0xFFDFD5EC) : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(25)),
                  border: _selectedType == 'Apartment' ? Border.all(color: Colors.black, width: 1.0) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedType == 'Apartment')
                      const Icon(Icons.check, color: Colors.black, size: 18),
                    if (_selectedType == 'Apartment')
                      const SizedBox(width: 4),
                    Text(
                      'Apartment',
                      style: TextStyle(
                        fontWeight: _selectedType == 'Apartment' ? FontWeight.bold : FontWeight.normal,
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
              onTap: () => setState(() => _selectedType = 'Bedspace'),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedType == 'Bedspace' ? const Color(0xFFDFD5EC) : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(25)),
                  border: _selectedType == 'Bedspace' ? Border.all(color: Colors.black, width: 1.0) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedType == 'Bedspace')
                      const Icon(Icons.check, color: Colors.black, size: 18),
                    if (_selectedType == 'Bedspace')
                      const SizedBox(width: 4),
                    Text(
                      'Bedspace',
                      style: TextStyle(
                        fontWeight: _selectedType == 'Bedspace' ? FontWeight.bold : FontWeight.normal,
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

  // Helper to build a label followed by an input field (TextField or Dropdown)
  Widget _buildLabeledInputField({
    required String label,
    required Widget inputField,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF49454F), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4), // Space between label and input field
          inputField,
        ],
      ),
    );
  }

  Widget _buildApartmentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text( // Title for this specific section
          'Apartment Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12), // Space between title and row of fields
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabeledInputField(
              label: 'Bedrooms',
              inputField: TextField(
                 controller: _bedroomsController,
                 keyboardType: TextInputType.number,
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.black, fontSize: 18),
                 decoration: InputDecoration(
                   isDense: true,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
               ),
            ),
            const SizedBox(width: 10),
             _buildLabeledInputField(
               label: 'Bathrooms',
               inputField: TextField(
                 controller: _bathroomsApartmentController,
                 keyboardType: TextInputType.number,
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.black, fontSize: 18),
                 decoration: InputDecoration(
                   isDense: true,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
               ),
            ),
            const SizedBox(width: 10),
             _buildLabeledInputField(
               label: 'Capacity',
               inputField: TextField(
                 controller: _capacityController,
                 keyboardType: TextInputType.number,
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.black, fontSize: 18),
                 decoration: InputDecoration(
                   isDense: true,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
               ),
            ),
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
        const Text( // Title for this specific section
          'Bedspace Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12), // Space between title and row of fields
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align items at the top
          children: [
             _buildLabeledInputField(
               label: 'Bedslots',
               inputField: TextField(
                 controller: _bedslotsController,
                 keyboardType: TextInputType.number,
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.black, fontSize: 18),
                 decoration: InputDecoration(
                   isDense: true,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
               ),
            ),
            const SizedBox(width: 10),
             _buildLabeledInputField(
               label: 'Bathrooms',
               inputField: TextField(
                 controller: _bathroomsBedspaceController,
                 keyboardType: TextInputType.number,
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.black, fontSize: 18),
                 decoration: InputDecoration(
                   isDense: true,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
               ),
            ),
            const SizedBox(width: 10),
            _buildLabeledInputField( // Use the helper for Gender too
              label: 'Gender',
              inputField: DropdownButtonFormField<String>(
                value: _selectedGender,
                items: _genderOptions.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  }
                },
                decoration: InputDecoration(
                   isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
              ),
            ),
          ],
        ),
         const SizedBox(height: 16), // Space after this section
      ],
    );
  }


  Widget _buildTextField(
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
    bool hasPrefixText = false,
    int maxLines = 1,
    String? labelText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color(0xFF49454F), fontSize: 12, fontWeight: FontWeight.bold),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixText: hasPrefixText ? '₱ ' : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        suffixIcon: labelText != null // Only show suffix icon if there's a label (like for other fields, not for 'Other Details')
            ? IconButton(
                icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                onPressed: () => controller.clear(),
              )
            : null,
      ),
    );
  }

  Widget _buildToggleSection({
    required String title,
    required String value,
    required VoidCallback onTap,
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
                decoration: const BoxDecoration(
                  color: Color(0xFF757575),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isChecked)
                      const Icon(Icons.check, color: Colors.white, size: 18),
                    if (isChecked)
                      const SizedBox(width: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
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
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(25)),
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

  Widget _buildAddImagesButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF9E9E9E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Add Images',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBillsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select at least one (1):',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _billOptions.map((option) {
                      bool isSelected = _selectedBills.contains(option['value']);
                      return InkWell(
                        onTap: () {
                          setStateModal(() {
                            if (isSelected) {
                              _selectedBills.remove(option['value']);
                            } else {
                              _selectedBills.add(option['value']);
                            }
                          });
                          this.setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? option['value'] == 'Water'
                                    ? Colors.blue
                                    : option['value'] == 'Electricity'
                                        ? Colors.amber
                                        : option['value'] == 'Internet'
                                            ? Colors.indigo
                                            : Colors.purple
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                option['icon'],
                                color: isSelected ? Colors.white : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contract Details:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<bool>(
                    title: const Text('With contract'),
                    value: true,
                    groupValue: _hasContract,
                    onChanged: (value) {
                      setStateModal(() {
                        _hasContract = value!;
                      });
                      this.setState(() {});
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Without contract'),
                    value: false,
                    groupValue: _hasContract,
                    onChanged: (value) {
                      setStateModal(() {
                        _hasContract = value!;
                      });
                      this.setState(() {});
                    },
                  ),
                  if (_hasContract) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _contractDuration.split(' ')[0],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                String unit = _contractDuration.split(' ').length > 1 ? _contractDuration.split(' ')[1] : 'Year/s';
                                setStateModal(() { // update local value for bottom sheet if needed
                                  _contractDuration = '$value $unit';
                                });
                                this.setState(() { // update main screen state
                                  _contractDuration = '$value $unit';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _contractDuration.split(' ').length > 1 ? _contractDuration.split(' ')[1] : 'Year/s',
                            items: ['Month/s', 'Year/s'].map((String unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                String durationValue = _contractDuration.split(' ')[0];
                                setStateModal(() { // update local value for bottom sheet if needed
                                   _contractDuration = '$durationValue $newValue';
                                });
                                this.setState(() { // update main screen state
                                  _contractDuration = '$durationValue $newValue';
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}