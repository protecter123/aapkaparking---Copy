import 'package:aapkaparking/verify.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true;
//String? _errorMessage; // Error message to display

  // Regular Expression to validate email format
  final RegExp emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorMessage = 'Email cannot be empty';
      } else if (!emailRegExp.hasMatch(value)) {
        _errorMessage = 'Please enter a valid email';
      } else {
        _errorMessage = null; // Clear error if email is valid
      }
    });
  }

  Future<void> signup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset error message
    });

    final email = emailController.text.trim();

    try {
      // Step 1: Check if the email exists in the "LoginUsers" collection
      final docSnapshot = await FirebaseFirestore.instance
          .collection('LoginUsers')
          .doc(email)
          .get();

      if (!docSnapshot.exists) {
        // If the document does not exist, show a bottom sheet and stop sign up
        _showBottomSheet('Admin hasn\'t given access to this email.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Step 2: Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email, password: passwordController.text.trim());

      // Optionally save the user data in Firestore (if needed)
      // await FirebaseFirestore.instance.collection('YourCollection').doc(userCredential.user?.uid).set(userData);

      // Step 3: Navigate to the sign-in screen or home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Verify()), // Replace with your home screen
      );
    } on FirebaseAuthException catch (e) {
      // Handle sign-up error
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      // Handle other errors
      setState(() {
        _errorMessage = 'An unknown error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 30),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 215, 206),
      appBar: AppBar(
        title: const Text('Sign Up',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(0, 251, 249, 249),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Email Text Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email,
                      color: Color.fromARGB(255, 9, 10, 0)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Color.fromARGB(255, 16, 16, 16)),
                  ),
                  errorText: _errorMessage, // Shows error message if any
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  _validateEmail(value); // Validate email on every change
                },
              ),
              const SizedBox(height: 15),
              // Password Text Field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock,
                      color: Color.fromARGB(255, 4, 4, 4)),

                  // Suffix icon (Eye for toggling obscure text)
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off
                          : Icons.visibility, // Toggle between visibility icons
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText =
                            !_obscureText; // Toggle obscureText state
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                  errorText: _errorMessage,
                ),
                obscureText:
                    _obscureText, // Control the obscure text with the state
              ),
              const SizedBox(height: 20),
              // Sign Up Button
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Colors.black,
                )
              else
                ElevatedButton(
                  onPressed: signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 2, 2, 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              const SizedBox(height: 20),
              // Error Message
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              // Already have an account?
              TextButton(
                onPressed: () {
                  // Navigate to Sign In screen
                  Navigator.pop(context);
                },
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
