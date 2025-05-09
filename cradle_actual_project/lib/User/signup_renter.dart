import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';

import '../Renter UI/renter_home_screen.dart'; // Import RenterHomeScreen

class SignupRenterScreen extends StatefulWidget {
  const SignupRenterScreen({super.key});

  @override
  _SignupRenterScreenState createState() => _SignupRenterScreenState();
}

class _SignupRenterScreenState extends State<SignupRenterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedSex;
  final _phoneController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); // For confirm password

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    // Add listener to password controller to re-validate confirm password field
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    // Remove listener and dispose all controllers
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _permanentAddressController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validation Functions
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

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    return null;
  }

  String? _validateGuardianName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Guardian Name is required';
    }
    return null;
  }

  String? _validateGuardianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Guardian\'s phone number is required';
    }
    if (!RegExp(r'^[+0-9]{10,13}$').hasMatch(value)) {
      return 'Invalid phone number';
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
    // Password validation (at least 8 characters, alphanumeric)
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    // Check for at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _onPasswordChanged() {
    // If the confirm password field has text, trigger a rebuild.
    // This will cause the Confirm Password TextFormField to re-validate
    // due to AutovalidateMode.onUserInteraction.
    if (_confirmPasswordController.text.isNotEmpty) {
      setState(() {
        // Form fields will be re-evaluated
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
    });
  }

  void _submitForm() async {
    // Make _submitForm async
    if (_formKey.currentState!.validate()) {
      // Form is valid, process the data
      String name = _nameController.text;
      String age = _ageController.text;
      String? sex = _selectedSex;
      String phone = _phoneController.text;
      String address = _permanentAddressController.text;
      String guardianName = _guardianNameController.text;
      String guardianPhone = _guardianPhoneController.text;
      String email = _emailController.text;
      String password = _passwordController.text;

      // Do something with the data (e.g., send to a server, save to a database)
      print(
          'Name: $name, Age: $age, Sex: $sex, Phone: $phone, Address: $address');
      print('Guardian Name: $guardianName, Guardian Phone: $guardianPhone');
      print('Email: $email, Password: $password');

      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creating account...')),
        );

        UserCredential userCredential = // Add await
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (userCredential.user != null) {
          // Save additional user data to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': name,
            'age': int.tryParse(age) ?? 0, // Ensure age is an int
            'sex': sex,
            'phone': phone,
            'permanentAddress': address,
            'guardianName': guardianName,
            'guardianPhone': guardianPhone,
            'email': email, // Storing email might be useful
            'accountType': 'renter',
          });
          print('Renter account created for ${userCredential.user!.uid}');
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Renter account created successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
            // Navigate to Renter Home Screen
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const RenterHomeScreen()),
                (Route<dynamic> route) => false);
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Signup failed. Please try again.';
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'The account already exists for that email.';
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return; // Exit the function to prevent further actions on failure
      }

      // Navigate to another screen (e.g., login)
    } else {
      // Form is invalid
      // Form is invalid, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple[700],
        title: const Text('New Account'),
        // titleSpacing: 4.0, // You can keep or adjust this based on overall preference for title spacing
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(
              left: 18.0), // Adjust this value to move the button more or less
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 24.0),
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
                labelText: 'Name', // Floating label
                hintText: 'Enter your full name',
                controller: _nameController,
                validator: _validateName,
                labelColor: Colors.deepPurple, // Made label deepPurple
              ),
              const SizedBox(height: 12),
              _buildTextField(
                labelText: 'Age', // Floating label
                hintText: 'Enter your age',
                controller: _ageController,
                keyboardType: TextInputType.number,
                validator: _validateAge,
                labelColor: Colors.deepPurple, // Made label deepPurple
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  labelText: 'Sex', // Floating label
                  labelStyle: const TextStyle(
                      color: Colors.deepPurple), // Made label deepPurple
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
              _buildTextField(
                labelText: 'Phone Number', // Floating label
                hintText: 'Enter your phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                labelColor: Colors.deepPurple, // Made label deepPurple
              ),
              const SizedBox(height: 12),
              _buildTextField(
                labelText: 'Permanent Address', // Floating label
                hintText: 'Enter your permanent address',
                controller: _permanentAddressController,
                validator: _validateAddress,
                labelColor: Colors.deepPurple, // Made label deepPurple
              ),
              const SizedBox(height: 24),
              Text(
                'GUARDIAN INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                labelText: 'Guardian\'s Name', // Floating label
                hintText: 'Enter guardian\'s full name',
                controller: _guardianNameController,
                validator: _validateGuardianName,
                labelColor: Colors.deepPurple, // Made label deepPurple
              ),
              const SizedBox(height: 12),
              _buildTextField(
                labelText: 'Guardian\'s Phone Number', // Floating label
                hintText: 'Enter guardian\'s phone number',
                controller: _guardianPhoneController,
                keyboardType: TextInputType.phone,
                validator: _validateGuardianPhone,
                labelColor: Colors.deepPurple, // Made label deepPurple
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
                labelText: 'Email', // Floating label
                hintText: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                labelColor: Colors.deepPurple, // Made label deepPurple
              ),
              const SizedBox(height: 12),
              _buildTextField(
                labelText: 'Password', // Floating label
                hintText: 'Enter your password',
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                validator: _validatePassword,
                onToggleObscurity: _togglePasswordVisibility,
                labelColor: Colors.deepPurple, // Made label deepPurple
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                controller: _confirmPasswordController,
                obscureText: _isConfirmPasswordObscured,
                validator: _validateConfirmPassword,
                onToggleObscurity: _toggleConfirmPasswordVisibility,
                labelColor: Colors.deepPurple,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    String? hintText,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    required String? Function(String?) validator,
    Color? labelColor, // Added labelColor parameter
    AutovalidateMode? autovalidateMode, // Added autovalidateMode
    VoidCallback? onToggleObscurity, // Added for password visibility toggle
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: labelText, // Floating label
            labelStyle: TextStyle(
                color: labelColor ??
                    Colors.grey[600]), // Use provided color or default
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            suffixIcon: onToggleObscurity != null
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: onToggleObscurity,
                  )
                : (controller.text
                        .isNotEmpty // Show clear button only if text is not empty and no toggle is present
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => controller.clear(),
                      )
                    : null),
          ),
          validator: validator,
          autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
        ),
      ],
    );
  }
}
