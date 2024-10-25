import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({Key? key}) : super(key: key);

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to send password reset email
  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showBottomSheet("Email sent successfully");
    } catch (e) {
      // Catch Firebase errors
      String errorMessage = "Something went wrong";
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = "User not found";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email";
        }
      }
      _showBottomSheet(errorMessage);
    }
  }

  // Function to show bottom sheet with messages
  void _showBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 215, 206),
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(0, 251, 193, 45),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Text Field
            const SizedBox(
              height: 50,
            ),
            Lottie.network(
              'https://lottie.host/3f24280d-43b0-47e6-b770-1fbc6d6ed85d/ANkQg3gRwo.json', // Replace with your desired Lottie URL
              width: 200, // Set width
              height: 200, // Set height
              fit: BoxFit.fill, // Adjust how it fits in the widget
            ),
            const SizedBox(
              height: 50,
            ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email,
                    color: Color.fromARGB(255, 7, 7, 7)),
                labelText: "Enter your email",
                labelStyle:
                    const TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: const Color.fromARGB(255, 10, 10, 10)),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Color.fromARGB(255, 10, 10, 10)),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              cursorColor: const Color.fromARGB(255, 8, 8, 8),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 20.0),

            // Reset Password Button with 3D look
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 6, 6, 6),
                elevation: 10,
                shadowColor: const Color.fromARGB(255, 97, 245, 23),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text(
                'Reset Password',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
