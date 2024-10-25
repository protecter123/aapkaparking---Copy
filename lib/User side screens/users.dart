import 'dart:ui'; // For ImageFilter

import 'package:aapkaparking/User%20side%20screens/PassScan.dart';
import 'package:aapkaparking/User%20side%20screens/bluetoothShowScreen.dart';
import 'package:aapkaparking/User%20side%20screens/fdpVehicleList.dart';
import 'package:aapkaparking/User%20side%20screens/fpList.dart';
import 'package:aapkaparking/User%20side%20screens/qrScanner.dart';
import 'package:aapkaparking/verify.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Update this import with the correct path

class UserDash extends StatefulWidget {
  const UserDash({super.key});

  @override
  State<UserDash> createState() => _UserDashState();
}

class _UserDashState extends State<UserDash> {
  String _keyboardType = 'numeric'; // Default value
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    _loadKeyboardType();
    findAdminPhoneNumber();
  }

  Future<void> findAdminPhoneNumber() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserPhoneNumber = currentUser?.email ?? 'unknown';

    try {
      // Reference to the AllUsers collection
      CollectionReference allUsersRef =
          FirebaseFirestore.instance.collection('AllUsers');

      // Fetch all admin documents
      QuerySnapshot adminsSnapshot = await allUsersRef.get();

      for (QueryDocumentSnapshot adminDoc in adminsSnapshot.docs) {
        // Reference to the Users subcollection
        CollectionReference usersRef = adminDoc.reference.collection('Users');

        // Check if the current user's phone number exists in this admin's Users subcollection
        DocumentSnapshot userDoc =
            await usersRef.doc(currentUserPhoneNumber).get();

        if (userDoc.exists) {
          // Save admin phone number to SharedPreferences if AdminNum is null
          SharedPreferences prefs = await SharedPreferences.getInstance();
          if (prefs.getString('AdminNum') == null) {
            await prefs.setString('AdminNum', adminDoc.id);
            // setState(() {
            //   // adminPhoneNumber = adminDoc.id; // Admin phone number or document ID
            // });
          }
          return;
        }
      }

      // Handle the case where no admin is found
      setState(() {
        // Handle no admin found logic if needed
      });
    } catch (e) {
      print('Error finding admin phone number: $e');
      setState(() {
        // Handle error state if needed
      });
    }
  }

  Future<void> _loadKeyboardType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _keyboardType = prefs.getString('keyboardType') ?? 'numeric';
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 15) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _saveKeyboardType(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('keyboardType', type);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedKeyboardType = _keyboardType;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                    24.0), // Increased padding for more space
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // Stretch items horizontally
                  children: [
                    // Title of the dialog
                    Text(
                      'Select Keyboard Type',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center, // Center title
                    ),
                    const SizedBox(height: 20),

                    // Numeric checkbox
                    CheckboxListTile(
                      title: Text(
                        'Numeric',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      value: selectedKeyboardType == 'numeric',
                      onChanged: (bool? value) {
                        if (value == true) {
                          setState(() {
                            selectedKeyboardType = 'numeric';
                          });
                        }
                      },
                      activeColor: const Color.fromARGB(255, 6, 2, 133),
                      checkColor: const Color.fromARGB(255, 249, 249, 249),
                    ),
                    const SizedBox(height: 8),

                    // Alphanumeric checkbox
                    CheckboxListTile(
                      title: Text(
                        'Alphanumeric',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      value: selectedKeyboardType == 'alphanumeric',
                      onChanged: (bool? value) {
                        if (value == true) {
                          setState(() {
                            selectedKeyboardType = 'alphanumeric';
                          });
                        }
                      },
                      activeColor: Color.fromARGB(255, 6, 2, 133),
                      checkColor: const Color.fromARGB(255, 249, 249, 249),
                    ),
                    const SizedBox(height: 24),

                    // Set button
                    ElevatedButton(
                      onPressed: () {
                        _saveKeyboardType(selectedKeyboardType);
                        setState(() {
                          _keyboardType = selectedKeyboardType;
                        });
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 6, 2, 133),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Set',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 250, 251, 251),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final userPhone = FirebaseAuth.instance.currentUser?.email;
    if (userPhone != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('LoginUsers')
          .doc(userPhone)
          .get();

      return docSnapshot.data();
    }
    return null;
  }

  void _logout() {
    _showLogoutDialog(context);
  }

  Widget dueBottomSheet(BuildContext context) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: Color.fromARGB(187, 73, 67, 240),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        //  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FdpVehicles(
                    keyboardtype: _keyboardType,
                    title: 'Due',
                  ),
                ),
              );
            },
            child: Container(
              height: 100,
              width: MediaQuery.of(context).size.width *
                  0.5, // Adjust width as needed
              color: const Color.fromARGB(
                  0, 0, 0, 0), // Changed to transparent to detect taps
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 60.0),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward,
                          color: Color.fromARGB(255, 255, 255, 255)),
                      const SizedBox(width: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Due In',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 20,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 50,
            width: 1,
            color: Color.fromARGB(255, 51, 255, 0),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Qrscanner(),
                ),
              );
            },
            child: Container(
              height: 100,
              width: MediaQuery.of(context).size.width *
                  0.49, // Adjust width as needed
              color: const Color.fromARGB(
                  0, 0, 0, 0), // Changed to transparent to detect taps
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 40.0),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_upward,
                          color: Color.fromARGB(255, 255, 255, 255)),
                      const SizedBox(width: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Due Out',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 20,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content to the left
              children: [
                const Row(
                  children: [
                    Text(
                      'Log out',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to log out?',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Align buttons to the right
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.remove('AdminNum');
                        await prefs.remove('vehicleData');
                        await prefs.remove('ParkingName');
                        await prefs.remove('ParkingLogo');
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Verify(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.white, // White background for "Yes"
                        side: const BorderSide(
                            color: Colors.black), // Black border for "Yes"
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                            255, 7, 7, 7), // Green background for "No"
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                            color: Color.fromARGB(255, 254, 254, 254),
                            fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 0),
      padding: const EdgeInsets.only(
          left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
      constraints: const BoxConstraints(
        maxWidth: 450, // Maintain max width
        maxHeight: 160, // Maintain max height
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Color.fromARGB(24, 0, 0, 0), // Optional: Set background color
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_getGreeting()}',
                        style: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 251, 251, 251),
                          fontSize: 20, // Bigger font for greeting
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: 5), // Space between greeting and name
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${userData['userName'] ?? 'User'}',
                        style: GoogleFonts.lora(
                          color: const Color.fromARGB(255, 251, 251, 251),
                          fontSize: 18, // Different font style for name
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: 10), // Space between name and phone number
                    // Phone Number Row
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.phoneAlt,
                          color: Color.fromARGB(255, 254, 253, 253),
                          size: 15,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: MediaQuery.of(context).size.width *
                              0.44, // Adjust width as needed
                          color: Colors
                              .transparent, // Set the background to transparent
                          child: AutoSizeText(
                            'Email: ${userData['uid'] ?? ''}',
                            style: GoogleFonts.poppins(
                              color: const Color.fromARGB(196, 248, 248, 248),
                              fontSize: 13,
                            ),
                            maxLines: 1, // Limits the text to one line
                            minFontSize: 10,
                            maxFontSize: 15, // Set a maximum font size
                            overflow: TextOverflow
                                .ellipsis, // Adds '...' if text still overflows
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                        height:
                            5), // Space between phone number and joined date
                    // Join Date Row
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.calendarAlt,
                          color: Color.fromARGB(255, 251, 250, 250),
                          size: 15,
                        ),
                        const SizedBox(width: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Joined: ${DateFormat('dd MMM yyyy').format((userData['CreatedAt'] as Timestamp).toDate())}',
                            style: GoogleFonts.poppins(
                              color: const Color.fromARGB(195, 247, 246, 246),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Lottie Animation on the right side
              SizedBox(
                height: 100, // Adjust height as needed
                width: 100, // Adjust width as needed
                child: Lottie.network(
                  'https://lottie.host/f5b61010-8baf-4e9a-8fdf-2a6180a98fec/xsQlisfFJA.json',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGridContainer(BuildContext context, String label, Color color,
      VoidCallback onTap, String Blocknum, String label2, String animation) {
    // Determine border radius based on Blocknum
    BorderRadius borderRadius;
    switch (Blocknum) {
      case '1': // Top-left rounded
        borderRadius = const BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.zero,
        );
        break;
      case '2': // Top-right rounded
        borderRadius = const BorderRadius.only(
          topRight: Radius.zero,
          topLeft: Radius.circular(12),
          bottomLeft: Radius.zero,
          bottomRight: Radius.circular(12),
        );
        break;
      case '3': // Bottom-right rounded
        borderRadius = const BorderRadius.only(
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(12),
          topRight: Radius.zero,
          bottomLeft: Radius.zero,
        );
        break;
      case '4': // Bottom-left rounded
        borderRadius = const BorderRadius.only(
          bottomRight: Radius.zero,
          topLeft: Radius.zero,
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        );
        break;
      default:
        borderRadius =
            BorderRadius.circular(12); // Default to all corners rounded
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        //  height: 600,
        child: Stack(
          children: [
            // Main container
            Container(
              // Fixed width
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius, // Apply conditional border radius
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                ), // Subtle border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Add animation at the top
                    SizedBox(
                      //height: 200, // Adjust size for the animation
                      child: Lottie.network(
                          //'https://lottie.host/de35767f-42a6-4448-8c99-c0eb5a16468f/OKr5v9EXuE.json',
                          animation), // Example animation
                    ),
                    const SizedBox(height: 0), // Spacing
                    // Label
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: GoogleFonts.inconsolata(
                          color: Color.fromARGB(221, 246, 243, 243),
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 0),
                    // Description lines
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Get the width of the available space
                          double availableWidth = constraints.maxWidth;

                          // Calculate a responsive font size based on the available width
                          double fontSize = availableWidth *
                              0.045; // Adjust the multiplier as needed

                          return Text(
                            label2,
                            style: GoogleFonts.inconsolata(
                              color: Color.fromARGB(255, 248, 247, 247),
                              fontSize: fontSize < 10
                                  ? 8
                                  : fontSize, // Ensure minimum font size
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2, // Limit to 2 lines to prevent overflow
                            overflow: TextOverflow.ellipsis, // Handle overflow
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Existing icon and interaction logic remains unchanged
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0, right: 30),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        childAspectRatio: 2 / 3.1,
        shrinkWrap: true,
        children: [
          _buildGridContainer(context, 'Due', Color.fromARGB(206, 220, 189, 15),
              () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return dueBottomSheet(context);
              },
            );
          }, '1', 'Tap to genrate or scan the reciept',
              'https://lottie.host/6d9d83cf-c148-49d9-a8ad-3b5fc041668c/gERbOpneL2.json'),
          _buildGridContainer(context, 'Fix', Color.fromARGB(201, 213, 15, 140),
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => FdpVehicles(
                        keyboardtype: _keyboardType,
                        title: 'Fix',
                      )),
            );
          }, '2', 'Tap to Select Fix Timing',
              'https://lottie.host/a72b4eab-f590-48d9-9976-cc73fd3dbedf/pNAOdrM24Z.json'),
          _buildGridContainer(
              context, 'Pass', Color.fromARGB(209, 187, 29, 226), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => FdpVehicles(
                        keyboardtype: _keyboardType,
                        title: 'Pass',
                      )),
            );
          }, '3', 'Tap to purchase pass',
              'https://lottie.host/5d3bc3a1-945a-4cc1-ad22-527c20b543d1/SoEz4YlIlH.json'),
          _buildGridContainer(
              context, 'Settings', Color.fromARGB(223, 6, 197, 143), () {
            _getSettings();
          }, '4', 'Tap for bluetooth and keyboard settings ',
              'https://lottie.host/438165aa-37f6-4757-9887-2d118439c336/3XJxuZF6yG.json'),
        ],
      ),
    );
  }

  void _getSettings() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: const Color.fromARGB(187, 73, 67, 240),
          height: 150, // Adjust height as needed
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    _showSettingsDialog();
                  },
                  child: Container(
                    height: 150,
                    width: 160,
                    color: const Color.fromARGB(187, 73, 67, 240),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.keyboard,
                          color: Color.fromARGB(255, 255, 255, 255),
                          size: 50, // Increase icon size
                        ), // Colorful icon
                        SizedBox(height: 10),
                        Text('Keyboard Setting',
                            style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(
                                    255, 255, 255, 255))), // Label
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 1, // Separator line width
                color:
                    Color.fromARGB(255, 255, 255, 255), // Separator line color
                height: 80, // Separator line height
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PrintOptionsScreen()),
                    );
                  },
                  child: Container(
                    height: 150,
                    width: 160,
                    color: const Color.fromARGB(187, 73, 67, 240),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.print,
                          color: Color.fromARGB(255, 255, 255, 255),
                          size: 50, // Increase icon size
                        ), // Colorful icon
                        SizedBox(height: 10),
                        Text('printer Setting',
                            style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(
                                    255, 255, 255, 255))), // Label
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget customAppBar(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromARGB(0, 4, 4, 4),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 30,
            top: 10,
            child: Row(
              children: [
                // The image asset
                GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                  child: const Icon(
                    Icons.list,
                    color: Colors.white,
                    size: 33,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 110,
            top: 10,
            child: AutoSizeText(
              'User Dashboard',
              style: GoogleFonts.lora(
                color: const Color.fromARGB(255, 246, 245, 245),
                fontSize: 20, // Default font size
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1, // Limits the text to one line
              minFontSize: 18, // Minimum font size to ensure readability
              maxFontSize: 25, // Ensures the font doesn't go beyond 25
              overflow: TextOverflow.ellipsis, // Adds '...' if necessary
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            child: GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                      0, 247, 247, 247), // Transparent background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Color.fromARGB(255, 250, 250, 250),
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(5), // Rounded corners for the dialog
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align content to the left
                  children: [
                    // "Exit app" heading
                    const Text(
                      'Exit app',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Confirmation message
                    const Text(
                      'Do you want to exit the app?',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    // Row with "Yes" and "No" buttons
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end, // Align buttons to the right
                      children: [
                        // "Yes" button with transparent background (only text)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(true); // Close dialog and exit app
                          },
                          child: const Text(
                            'Yes',
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // "No" button with green background
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(false); // Close dialog, stay in app
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 124, 244,
                                109), // Green background for "No"
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'No',
                            style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return await _showExitDialog(context); // Show exit dialog on back press
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(255, 0, 12, 55),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0, 212, 123, 123),
          toolbarHeight: -0,
        ),
        drawer: Drawer(
          width: 250,
          surfaceTintColor: const Color.fromARGB(255, 236, 219, 178),
          shadowColor: Colors.orangeAccent, // Subtle shadow for 3D effect
          elevation: 45,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Custom DrawerHeader with parking logo and name
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 10, 62, 232),
                      Color.fromARGB(
                          255, 229, 139, 166), // Darker grey for depth
                      Color.fromARGB(
                          255, 165, 222, 149), // Orange gradient transition
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          Colors.grey.shade300, // Border around the image
                      child: ClipOval(
                        child: Image.asset(
                          'assets/aapka logo.webp', // Path to the asset image
                          // fit: BoxFit.contain,
                          width:
                              80, // Set width and height to match the CircleAvatar radius
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons
                                .error_outline); // Display error icon if asset fails to load
                          },
                        ),
                      ),
                    ),
                    const Text(
                      'Aapka Parking',
                      style: const TextStyle(
                        color: Color.fromARGB(
                            255, 10, 10, 10), // Orange for text contrast
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily:
                            'GoogleFontName', // Replace with the Google Font you want
                      ),
                    )
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_outlined,
                    color: Colors.red),
                title: const Text('Scan for pass '),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Passcan()));
                },
              ),
              const SizedBox(
                height: 500,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0, left: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Container for the image
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey, // Grey filter for the logo
                        BlendMode.srcATop, // Blend mode
                      ),
                      child: Image.asset(
                        'assets/aapka logo.webp', // Image asset path
                        width: 15,
                        height: 15,
                      ),
                    ),
                    const SizedBox(
                        width: 10), // Space between the logo and text
                    const Text(
                      'Aapka Parking \u00A9',
                      style: TextStyle(
                        color: Color.fromARGB(255, 158, 158, 158), // Text color
                        fontSize: 15, // Font size
                        fontWeight: FontWeight.bold, // Bold text
                      ),
                    ),
                  ],
                ),
              )
              // Add more ListTiles as needed
            ],
          ),
        ),
        body: Column(
          children: [
            customAppBar(context),
            //const SizedBox(height: 0),
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show black loader while waiting for data
                  return const Center(
                    heightFactor: 4.5,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black), // Black color loader
                    ),
                  );
                } else if (snapshot.hasError) {
                  // Handle error scenario
                  return Center(
                    child: Text(
                      'Error loading data',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  );
                } else if (snapshot.hasData) {
                  // Data is available, show user card
                  return _buildUserCard(snapshot.data!);
                } else {
                  // If no data is present
                  return Center(
                    child: Text(
                      'No data available',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
              },
            ),

            // Image.asset(
            //   'assets/animations/tesla_car_PNG30.png', // Replace with your actual image asset path
            //   width: 400,
            //   height: 160,
            // ),
            // const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                // Uncomment the image line if you want to add the background image later
                // image: const DecorationImage(
                //   image: AssetImage('assets/animations/OIP (4)4.jpeg'), // Background image path
                //   fit: BoxFit.cover, // Cover the entire container with the image
                // ),
                border: Border.all(
                  color: Colors.black, // Border color
                  width: 1.0, // Border width (1px)
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0), // Rounded top-left corner
                  topRight: Radius.circular(0), // Rounded top-right corner
                ),
                // Adding the green shadow
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 25, 239, 1)
                        .withOpacity(0.9), // Slight green shadow with opacity
                    blurRadius: 15, // How blurred the shadow will be
                    offset: const Offset(
                        0, 1), // Horizontal and vertical offsets of the shadow
                  ),
                ],
              ),

              height: 600, // Example height, can be adjusted
              width:
                  MediaQuery.of(context).size.width - 30, // Full screen width
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Stick content to bottom
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                  _buildGrid(),
                  const SizedBox(
                    height: 22,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // First Button for "Fix Entries"
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FpList(label: "Fix"),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.black, // Button background color
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 25, 239, 1)
                                    .withOpacity(
                                        0.9), // Green shadow on four sides
                                blurRadius: 11,
                                offset: const Offset(0, 1), // Offset for shadow
                              ),
                            ],
                          ),
                          child: Text(
                            'Fix entries',
                            style: GoogleFonts.lato(
                              // You can replace 'lato' with any other Google Font
                              color: Colors.white, // Text color
                              fontSize: 16, // Text size
                              fontWeight: FontWeight.w600, // Text weight
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20), // Space between the buttons

                      // Second Button for "Pass Entries"
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FpList(label: "Pass"),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.black, // Button background color
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(255, 25, 239, 1)
                                    .withOpacity(
                                        0.9), // Green shadow on four sides
                                blurRadius: 11,
                                offset: Offset(0, 1), // Offset for shadow
                              ),
                            ],
                          ),
                          child: Text(
                            'Pass entries',
                            style: GoogleFonts.lato(
                              // You can replace 'lato' with any other Google Font
                              color: Colors.white, // Text color
                              fontSize: 16, // Text size
                              fontWeight: FontWeight.w600, // Text weight
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, left: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Container for the image
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey, // Grey filter for the logo
                            BlendMode.srcATop, // Blend mode
                          ),
                          child: Image.asset(
                            'assets/aapka logo.webp', // Image asset path
                            width: 15,
                            height: 15,
                          ),
                        ),
                        const SizedBox(
                            width: 10), // Space between the logo and text
                        const Text(
                          'Aapka Parking \u00A9',
                          style: TextStyle(
                            color: Color.fromARGB(
                                255, 158, 158, 158), // Text color
                            fontSize: 15, // Font size
                            fontWeight: FontWeight.bold, // Bold text
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
