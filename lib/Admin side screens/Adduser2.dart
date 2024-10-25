import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class Adduser2 extends StatefulWidget {
  const Adduser2({super.key});

  @override
  State<Adduser2> createState() => _AdduserState();
}

class _AdduserState extends State<Adduser2> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  
  bool _buttonEnabled = false;
  bool _isPasswordVisible = false;
  // Function to save user data
  void saveUser() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final String email = emailController.text.trim();
   // Get the password
    final String currentAdminEmail =
        FirebaseAuth.instance.currentUser?.email ?? '';
    final String userName = nameController.text.trim();

    // Validation for email, password, and name
    if (email.isEmpty  || userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide name, email, and password.'),
          duration: Duration(milliseconds: 300),
        ),
      );
      return;
    }

   

    final Map<String, dynamic> userData = {
      'uid': email,
      'userName': userName,
      'CreatedAt': DateTime.now(),
      'isDeleted': false,
    };

    // Check if admin is logged in
    if (currentAdminEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No admin logged in')),
      );
      return;
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            backgroundColor: Color.fromARGB(255, 206, 200, 200),
            color: Colors.black,
          ), // Show loader
        );
      },
    );

    try {
      // Step 1: Sign up with email and password

      // Step 2: Save user data in "LoginUsers" collection
      await FirebaseFirestore.instance
          .collection('LoginUsers')
          .doc(email)
          .set(userData);

      // Step 3: Save user data in current admin's "Users" collection
      await FirebaseFirestore.instance
          .collection('AllUsers')
          .doc(currentAdminEmail)
          .collection('Users')
          .doc(email)
          .set(userData);

      // Step 4: Show success dialog
      Navigator.of(context).pop(); // Close the loading dialog
      _showSuccessDialog();

      // Clear the input fields
      emailController.clear();
      
      nameController.clear();

      setState(() {
        _buttonEnabled = false;
      });
    } catch (error) {
      // Step 5: Handle error during sign-up or Firestore operations
      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add user: $error')),
      );
    }
  }

  // Function to show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/complete.json',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'New User Added Successfully!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 225, 215, 206),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Orange and yellow splash with blur effect at the top left corner

                  Positioned(
                    top: 30,
                    left: 20,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade300,
                            Colors.yellow.shade200
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 30.0,
                          sigmaY: 30.0,
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    left: 70,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 243, 255, 77),
                            Color.fromARGB(255, 251, 230, 190)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 30.0,
                          sigmaY: 30.0,
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Name
                        const SizedBox(
                          height: 130,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  'Add User',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize:
                                        constraints.maxWidth > 600 ? 50 : 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  'Name',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize:
                                        constraints.maxWidth > 600 ? 50 : 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        // TextFields
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  child: Text(
                                'User name',
                                style: GoogleFonts.notoSansHanunoo(
                                    color: const Color.fromARGB(255, 5, 5, 5)),
                              )),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: nameController,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 20),
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  hintText: 'Enter user name',
                                  hintStyle: GoogleFonts.notoSansHanunoo(
                                      color: Colors.grey, fontSize: 14),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(
                                      r'[a-zA-Z0-9 ]')), // Allows only letters, numbers, and spaces
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _buttonEnabled = value.isNotEmpty;
                                  });
                                },
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child: Text(
                                  'Email address',
                                  style: GoogleFonts.notoSansHanunoo(
                                      color:
                                          const Color.fromARGB(255, 5, 5, 5)),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller:
                                    emailController, // Update to emailController
                                keyboardType: TextInputType
                                    .emailAddress, // Update to email input type
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 20),
                                decoration: InputDecoration(
                                  counterText:
                                      '', // You can remove this if email doesn't require maxLength
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  hintText: 'Enter email address',
                                  hintStyle: GoogleFonts.notoSansHanunoo(
                                      color: Colors.grey, fontSize: 14),
                                  prefixIcon: const Padding(
                                      padding:
                                          EdgeInsets.only(right: 5.0, left: 10),
                                      child: Icon(Icons.email)),
                                  prefixIconConstraints: const BoxConstraints(
                                      minWidth: 0, minHeight: 0),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _buttonEnabled = value.isNotEmpty &&
                                        nameController.text.isNotEmpty;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 80),
                        GestureDetector(
                          onTap: saveUser,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  offset: const Offset(4, 4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-4, -4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'ADD USER',
                                style: GoogleFonts.notoSansHanunoo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                      top: 40,
                      left: -14,
                      child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.chevron_left,
                            size: 37,
                            color: Colors.black,
                          ))),
                ],
              );
            },
          ),
        ));
  }
}
