import 'package:flutter/material.dart';
import 'signup_renter.dart';
import 'signup_owner.dart';
import 'log_in.dart';

// Removed the main() function and CradleApp class as they are now in main.dart

// Renamed the file to welcome_screen.dart might be clearer, but keeping settle_now.dart for now.

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SignupRenterScreen()));
                        print('Continue as Renter');
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SignupOwnerScreen()));
                        print('Continue as Owner');
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final halfScreenHeight = screenHeight * 0.5;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
            child: Column(
              children: [
                Image.asset(
                  'assets/CRADLE LOGO 1.1.png',
                  height: 150,
                ),
                const SizedBox(height: 250),
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
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    width: screenWidth * 0.5,
                    child: ElevatedButton(
                      onPressed: () {
                        print('Login pressed');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(color: Colors.deepPurple[700]!),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 18, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    width: screenWidth * 0.5,
                    child: ElevatedButton(
                      onPressed: () {
                        _showContinueAsDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'By signing up or logging in, I accept the Cradle\'s Terms of Services and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
