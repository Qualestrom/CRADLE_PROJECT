import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'landing_page.dart'; // Import LandingPage

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Add state variables to track focus
  Color _emailLabelColor = Colors.grey;
  Color _passwordLabelColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    // Listen for focus changes and update the state
    _emailFocusNode.addListener(_updateEmailLabelColor);
    _passwordFocusNode.addListener(_updatePasswordLabelColor);
  }

  void _updateEmailLabelColor() {
    setState(() {
      _emailLabelColor =
          _emailFocusNode.hasFocus ? Colors.deepPurple : Colors.grey;
    });
  }

  void _updatePasswordLabelColor() {
    setState(() {
      _passwordLabelColor =
          _passwordFocusNode.hasFocus ? Colors.deepPurple : Colors.grey;
    });
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_updateEmailLabelColor);
    _passwordFocusNode.removeListener(_updatePasswordLabelColor);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Background Image
              Image.asset(
                'assets/LOGIN.png',
                fit: BoxFit.cover,
              ),
              // Content Overlay
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Content previously in Positioned, now part of the Column flow
                        SizedBox(
                            height: screenHeight *
                                0.10), // Adjust top spacing as needed
                        Image.asset(
                          'assets/CRADLE LOGO 1.1.png',
                          height: screenHeight * 0.21, // Adjusted height
                        ),
                        SizedBox(
                            height: screenHeight * 0.20), // Adjusted spacing
                        Text(
                          'Settle Now',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Start finding a place to settle inside GCH',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                                color:
                                    _emailLabelColor), // Use the state variable
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            hintText: 'Enter your email',
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                          validator: _validateEmail,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                                color:
                                    _passwordLabelColor), // Use the state variable
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            hintText: 'Enter your password',
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                          validator: _validatePassword,
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        SizedBox(
                          height: screenHeight * 0.07,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Make onPressed async
                              if (_formKey.currentState!.validate()) {
                                String email = _emailController.text;
                                String password = _passwordController.text;
                                print(
                                    'Login pressed with Email: $email, Password: $password');
                                try {
                                  UserCredential userCredential =
                                      await FirebaseAuth // Add await
                                          .instance
                                          .signInWithEmailAndPassword(
                                              email: email, password: password);
                                  if (userCredential.user != null && mounted) {
                                    // Successful login, navigate to LandingPage
                                    // LandingPage will handle routing to the correct home screen.
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LandingPage()),
                                      (Route<dynamic> route) => false,
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  String errorMessage =
                                      'Login failed. Please check your credentials.';
                                  if (e.code == 'user-not-found') {
                                    errorMessage =
                                        'No user found with that email.';
                                  } else if (e.code == 'wrong-password') {
                                    errorMessage = 'Incorrect password.';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errorMessage)));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
