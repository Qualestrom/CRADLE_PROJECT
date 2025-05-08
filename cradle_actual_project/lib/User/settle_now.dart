import 'package:flutter/material.dart';
import 'signup_renter.dart';
import 'signup_owner.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for login logic
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'landing_page.dart'; // Added for navigation after login

// Removed the main() function and CradleApp class as they are now in main.dart

// Helper function to create a slide-left page route
Route _createSlideLeftRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400), // Explicit duration
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Start from the right
      const end = Offset.zero; // End at the center
      const curve = Curves.easeInOutCubic; // Match in-page animation curve

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // --- Animation Controller ---
  late AnimationController _animationController;
  late Animation<double> _curvedAnimation;

  // --- Login Form State (from log_in.dart) ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  Color _emailLabelColor = Colors.grey;
  Color _passwordLabelColor = Colors.grey;
  bool _isPasswordVisible = false;
  // --- End Login Form State ---

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Increased duration
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic, // A smoother curve
    );

    _emailFocusNode.addListener(_updateEmailLabelColor);
    _passwordFocusNode.addListener(_updatePasswordLabelColor);
    _isPasswordVisible = false;
    _loadLastEmail(); // Load email when the widget initializes
  }

  void _updateEmailLabelColor() {
    if (mounted) {
      setState(() {
        _emailLabelColor =
            _emailFocusNode.hasFocus ? Colors.deepPurple : Colors.grey;
      });
    }
  }

  void _updatePasswordLabelColor() {
    if (mounted) {
      setState(() {
        _passwordLabelColor =
            _passwordFocusNode.hasFocus ? Colors.deepPurple : Colors.grey;
      });
    }
  }

  // --- SharedPreferences Logic for Email ---
  Future<void> _loadLastEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastEmail = prefs.getString('last_login_email');
    if (lastEmail != null) {
      _emailController.text = lastEmail;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    // You can add more password validation if needed (e.g., length)
    // if (value.length < 8) {
    //   return 'Password must be at least 8 characters';
    // }
    return null;
  }

  void _toggleLoginUI(bool show) {
    show ? _animationController.forward() : _animationController.reverse();
  }

  // Method to show the "Continue as Renter/Owner" dialog for Sign Up
  void _showContinueAsDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final double horizontalPadding = screenWidth * 0.1;
        final double buttonWidth = screenWidth * 0.8;
        final double buttonHorizontalMargin = screenWidth * 0.1;
        final double containerWidth = screenWidth * 0.9;

        return Container(
          width: containerWidth,
          decoration: const BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Added the handle here
                Center(
                  child: Container(
                    width: 40, // Width of the handle
                    height: 5, // Height of the handle
                    decoration: BoxDecoration(
                      color: Colors.white, // Color of the handle
                      borderRadius:
                          BorderRadius.circular(2.5), // Rounded corners
                    ),
                    margin: const EdgeInsets.only(
                        bottom: 10), // Add some margin below the handle
                  ),
                ),
                Text(
                  'Continue as:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: buttonHorizontalMargin),
                  child: SizedBox(
                    width: buttonWidth * 0.8,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the bottom sheet
                        Navigator.push(context,
                            _createSlideLeftRoute(const SignupRenterScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Renter',
                        style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.deepPurple),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: buttonHorizontalMargin),
                  child: SizedBox(
                    width: buttonWidth * 0.8,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the bottom sheet
                        Navigator.push(context,
                            _createSlideLeftRoute(const SignupOwnerScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Owner',
                        style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.deepPurple),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Login Logic (from log_in.dart) ---
  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        // Optionally: show a loading indicator
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        // Save email on successful login
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_login_email', email);

        if (userCredential.user != null && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String errorMessage = 'Login failed. Please check your credentials.';
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          errorMessage = 'Invalid email or password.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is badly formatted.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred.')));
      } finally {
        // Optionally: hide loading indicator
      }
    }
  }

  // Widget to build the initial Log In / Sign Up buttons
  Widget _buildInitialButtons(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      key: const ValueKey('initialButtons'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Adjust the width of the "Log In" button to be 60% of screen width and centered
        Center(
          // Center the button horizontally
          child: SizedBox(
            width: screenWidth * 0.5, // 50% of the screen width
            height: 50, // Maintain consistent height
            child: ElevatedButton(
              onPressed: () => _toggleLoginUI(true), // Show login form
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple[700],
                padding: const EdgeInsets.symmetric(
                    vertical: 14), // Adjust padding if needed due to fixed size
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(color: Colors.deepPurple[700]!),
                ),
                elevation: 0,
                // Ensure the button text fits, or consider minimumSize if text is dynamic
                // minimumSize: Size(double.infinity, 50), // This would make it fill the SizedBox
              ),
              child: const Text('Log In',
                  style: TextStyle(fontSize: 18, fontFamily: 'Inter')),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Adjust the width of the "Sign Up" button to be 60% of screen width and centered
        Center(
          // Center the button horizontally
          child: SizedBox(
            width: screenWidth * 0.5, // 50% of the screen width
            height: 50, // Maintain consistent height
            child: ElevatedButton(
              onPressed: () => _showContinueAsDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text('Sign Up',
                  style: TextStyle(
                      fontSize: 18, color: Colors.white, fontFamily: 'Inter')),
            ),
          ),
        ),
      ],
    );
  }

  // Widget to build the login form
  Widget _buildLoginForm(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('loginForm'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: _emailLabelColor),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Enter your email',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: _passwordLabelColor),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Enter your password',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: _passwordFocusNode.hasFocus
                      ? Colors.deepPurple
                      : Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 24),
          Center(
            // Center the Login button
            child: SizedBox(
              width: screenWidth * 0.5, // 50% of screen width
              height: 50,
              child: ElevatedButton(
                onPressed: _performLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Log In',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Inter')),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            // Center the Back button
            child: SizedBox(
              width: screenWidth * 0.5, // 50% of screen width
              height: 50, // Give it a consistent height
              child: TextButton(
                onPressed: () {
                  _toggleLoginUI(false); // Hide login form
                  // Clear fields and reset state when going back
                  _formKey.currentState?.reset();
                  _emailController.clear();
                  _passwordController.clear();
                  setState(() {
                    _isPasswordVisible = false;
                  });
                  _emailFocusNode.unfocus();
                  _passwordFocusNode.unfocus();
                },
                child: Text('Back',
                    style: TextStyle(
                        color: Colors.deepPurple[700],
                        fontSize: 16,
                        fontFamily: 'Inter')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build the "Settle Now" and description texts
  // These texts will remain static above the animated buttons/form.
  Widget _buildWelcomeTexts(BuildContext context) {
    return Column(
      key: const ValueKey('welcomeTexts'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Settle Now',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[700],
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start finding a place to settle inside GCH',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(
            height:
                20), // Slightly reduced to lift the buttons/form block a bit
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final halfScreenHeight = screenHeight * 0.5;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent scaffold from resizing
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          SizedBox(
            height: halfScreenHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/SETTLENOW.png',
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: halfScreenHeight * 0.2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: screenHeight * 0.15,
            left: 0,
            right: 0,
            child: Image.asset(
              // Logo remains positioned
              'assets/CRADLE LOGO 1.1.png',
              height: 150,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              // Use LayoutBuilder to get constraints
              builder: (context, constraints) {
                final isKeyboardVisible =
                    MediaQuery.of(context).viewInsets.bottom > 0;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // Ensure Column tries to fill height, accounting for keyboard if it were resizing
                      // but with resizeToAvoidBottomInset: false, maxHeight is full screen.
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      // Allows Column's MainAxisAlignment.end to work
                      child: Padding(
                        // Padding is now inside the scrollable, constrained area
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.end, // Pushes content to bottom
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Add the static welcome texts here, above the animated Stack
                            Visibility(
                              visible: !isKeyboardVisible,
                              maintainState: false,
                              maintainAnimation: false,
                              maintainSize: false,
                              child: _buildWelcomeTexts(context),
                            ),
                            AnimatedSize(
                              // Wrap the Stack with AnimatedSize
                              duration: _animationController.duration ??
                                  const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment
                                  .bottomCenter, // Change to bottomCenter
                              child: Stack(
                                alignment: Alignment
                                    .bottomCenter, // Change to bottomCenter
                                children: <Widget>[
                                  // Initial Buttons: Animate out
                                  AnimatedBuilder(
                                    animation: _curvedAnimation,
                                    child: _buildInitialButtons(context),
                                    builder: (context, childWidget) {
                                      return Offstage(
                                        offstage: _animationController.status ==
                                            AnimationStatus.completed,
                                        child: FadeTransition(
                                          opacity: Tween<double>(
                                                  begin: 1.0, end: 0.0)
                                              .animate(_curvedAnimation),
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset.zero,
                                              end: const Offset(0.0,
                                                  0.15), // Slide down by 15% of height
                                            ).animate(_curvedAnimation),
                                            child: childWidget,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Login Form: Animate in
                                  AnimatedBuilder(
                                    animation: _curvedAnimation,
                                    child: _buildLoginForm(context),
                                    builder: (context, childWidget) {
                                      return Offstage(
                                        offstage: _animationController.status ==
                                            AnimationStatus.dismissed,
                                        child: FadeTransition(
                                          opacity: _curvedAnimation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.0,
                                                  0.15), // Slide up from 15% below
                                              end: Offset.zero,
                                            ).animate(_curvedAnimation),
                                            child: childWidget,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // This SizedBox's height will now animate.
                            // It will be larger when initial buttons are shown (lifting them more)
                            // and smaller when the login form is shown (positioning it lower).
                            AnimatedBuilder(
                              animation: _curvedAnimation,
                              builder: (context, child) {
                                final double height = Tween<double>(
                                  begin: constraints.maxHeight *
                                      0.10, // Larger height for initial buttons
                                  end: constraints.maxHeight *
                                      0.03, // Smaller height for login form (adjust as needed)
                                ).evaluate(_curvedAnimation);
                                return SizedBox(height: height);
                              },
                            ),
                            AnimatedBuilder(
                              animation:
                                  _curvedAnimation, // Animate with the same curve
                              builder: (context, child) {
                                // Use FadeTransition for smoother opacity change
                                return FadeTransition(
                                  opacity: Tween<double>(begin: 1.0, end: 0.7)
                                      .animate(_curvedAnimation),
                                  child: child,
                                );
                              },
                              child: Text(
                                'By signing up or logging in, I accept the Cradle\'s Terms of Services and Privacy Policy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            if (isKeyboardVisible)
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
