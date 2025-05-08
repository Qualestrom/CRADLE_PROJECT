import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../User/settle_now.dart'; // For logging out and going to WelcomeScreen

class OwnerPendingVerificationScreen extends StatelessWidget {
  const OwnerPendingVerificationScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Pending Verification'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.hourglass_top_rounded,
                size: 80,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 24),
              Text(
                'Thank You for Registering!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account is currently under review. We will verify your submitted documents (Valid ID and Proof of Ownership) shortly.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be able to access owner features once your account is approved. This usually takes 1-2 business days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text('Log Out and Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
