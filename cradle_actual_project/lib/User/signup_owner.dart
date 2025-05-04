import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Add the image_picker package

void main() {
  runApp(const MaterialApp(
    home: SignupOwnerScreen(),
  ));
}

class SignupOwnerScreen extends StatefulWidget {
  const SignupOwnerScreen({super.key});

  @override
  _SignupOwnerScreenState createState() => _SignupOwnerScreenState();
}

class _SignupOwnerScreenState extends State<SignupOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedSex;
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  File? _validId;
  File? _proofOfOwnership;
  final picker = ImagePicker(); // Instance of the image picker

  // Focus Nodes (still useful for potential advanced UI interactions)
  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _facebookFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Validation Functions (No changes needed)
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0) {
      return 'Invalid age';
    }
    return null;
  }

  String? _validateSex(String? value) {
    if (value == null || value.isEmpty) {
      return 'Sex is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Basic phone number validation (10-13 digits, allows +)
    if (!RegExp(r'^[+0-9]{10,13}$').hasMatch(value)) {
      return 'Invalid phone number';
    }
    return null;
  }

  String? _validateFacebook(String? value) {
    if (value == null || value.isEmpty) {
      return 'Facebook link is required.';
    }
    if (!Uri.parse(value).isAbsolute) {
      return 'Invalid Facebook URL.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    // Basic password validation (at least 8 characters)
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Function to handle form submission (No changes needed for visual)
  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        _validId != null &&
        _proofOfOwnership != null) {
      // Form is valid, process the data
      String name = _nameController.text;
      String age = _ageController.text;
      String sex = _selectedSex!;
      String phone = _phoneController.text;
      String facebook = _facebookController.text;
      String email = _emailController.text;
      String password = _passwordController.text;

      // Do something with the data (e.g., send to a server, save to a database)
      print(
          'Name: $name, Age: $age, Sex: $sex, Phone: $phone, Facebook: $facebook');
      print('Email: $email, Password: $password');
      print('Valid ID: $_validId, Proof of Ownership: $_proofOfOwnership');

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to another screen
      Navigator.pop(context); // just pop
    } else {
      // Form is invalid, show an error message
      List<String> errors = [];
      if (_formKey.currentState?.validate() == false) {
        errors.add("Please fill all required fields.");
      }
      if (_validId == null) {
        errors.add("Valid ID is required.");
      }
      if (_proofOfOwnership == null) {
        errors.add("Proof of Ownership is required.");
      }

      String message = errors.join(" "); // Combine errors into one message

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to handle file upload (No changes needed for visual)
  Future<void> _uploadFile(String fileType) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // Simulate file selection
    // await Future.delayed(const Duration(milliseconds: 500)); // Simulate delay
    // String? filePath =
    //     'path/to/dummy_file.jpg'; //   Replace with actual file path.

    setState(() {
      if (pickedFile != null) {
        if (fileType == 'validId') {
          _validId = File(pickedFile.path);
        } else {
          _proofOfOwnership = File(pickedFile.path);
        }
      } else {
        print('No file selected.'); // Important for debugging
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocusNode.dispose(); // Dispose focus nodes
    _ageFocusNode.dispose();
    _phoneFocusNode.dispose();
    _facebookFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple[700],
        title: const Text('New Account'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PERSONAL INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Name',
                _nameController,
                focusNode: _nameFocusNode,
                labelText: 'Name', // Floating label
                hintText: 'Enter your full name', // Placeholder
                validator: (value) => _validateName(value),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Age',
                _ageController,
                focusNode: _ageFocusNode,
                keyboardType: TextInputType.number,
                labelText: 'Age', // Floating label
                hintText: 'Enter your age', // Placeholder
                validator: (value) => _validateAge(value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  labelText: 'Sex', // Floating label
                  labelStyle: const TextStyle(color: Colors.deepPurple), // Made label deepPurple
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                value: _selectedSex,
                items: <String>['Male', 'Female', 'Other']
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSex = newValue;
                  });
                },
                validator: _validateSex,
                hint: const Text('Select your sex',
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              _buildUploadButton(
                onPressed: () => _uploadFile('validId'),
                text: _validId == null ? 'Upload Valid ID' : 'Valid ID Uploaded',
              ),
              if (_validId != null) ...[
                const SizedBox(height: 8),
                Image.file(
                  _validId!,
                  height: 100,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'CONTACT INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Phone Number',
                _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                labelText: 'Phone Number', // Floating label
                hintText: 'Enter your phone number', // Placeholder
                validator: (value) => _validatePhone(value),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Facebook Link',
                _facebookController,
                focusNode: _facebookFocusNode,
                labelText: 'Facebook Link', // Floating label
                hintText: 'Enter your Facebook link', // Placeholder
                validator: (value) => _validateFacebook(value),
              ),
              const SizedBox(height: 24),
              Text(
                'LOGIN INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Email',
                _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                labelText: 'Email', // Floating label
                hintText: 'Enter your email', // Placeholder
                validator: (value) => _validateEmail(value),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Password',
                _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: true,
                labelText: 'Password', // Floating label
                hintText: 'Enter your password', // Placeholder
                validator: (value) => _validatePassword(value),
              ),
              const SizedBox(height: 24),
              Text(
                'PROOF OF OWNERSHIP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildUploadButton(
                onPressed: () => _uploadFile('proofOfOwnership'),
                text: _proofOfOwnership == null
                    ? 'Upload Proof of Ownership'
                    : 'Proof Uploaded',
              ),
              if (_proofOfOwnership != null) ...[
                const SizedBox(height: 8),
                Image.file(
                  _proofOfOwnership!,
                  height: 100,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool obscureText = false,
    String? labelText,
    String? hintText,
    required String? Function(String?) validator,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText, // Floating label
            labelStyle: const TextStyle(color: Colors.deepPurple), // Label text color
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            hintText: hintText, // Placeholder text
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
              },
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildUploadButton({
    required VoidCallback? onPressed,
    required String text,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[700], // Background color
        foregroundColor: Colors.white, // Text color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding
        textStyle: const TextStyle(fontSize: 16), // Text size
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ensure button size wraps content
        children: [
          const Icon(Icons.upload_file), // Upload icon
          const SizedBox(width: 8), // Space between icon and text
          Text(text), // Button text
        ],
      ),
    );
  }
}