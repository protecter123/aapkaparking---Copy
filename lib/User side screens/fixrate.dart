import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reciept.dart';

class Fixirate extends StatefulWidget {
  final String imgUrl;
  final String keyboardtype;

  const Fixirate({super.key, required this.imgUrl, required this.keyboardtype});

  @override
  _FixirateState createState() => _FixirateState();
}

class _FixirateState extends State<Fixirate> {
  int? _selectedContainerIndex;
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? pricingData;
  String? adminPhoneNumber = '';
  String currentUserPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    loadPricingData(); // Load data when the screen loads
  }

  Future<void> loadPricingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    adminPhoneNumber = prefs.getString('AdminNum');
    User? currentUser = FirebaseAuth.instance.currentUser;
    currentUserPhoneNumber = currentUser?.email ?? 'unknown';
    String? cachedPricingData = prefs.getString('pricingData_${widget.imgUrl}');

    if (cachedPricingData != null) {
      // Data exists in SharedPreferences, decode it and use it
      setState(() {
        pricingData = jsonDecode(cachedPricingData);
      });
    } else {
      // Data not in SharedPreferences, fetch it from Firestore
      await fetchPricingDetailsFromFirestore();
    }
  }

  Future<void> fetchPricingDetailsFromFirestore() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    currentUserPhoneNumber = currentUser?.email ?? 'unknown';

    try {
      // Retrieve the admin phone number from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      adminPhoneNumber = prefs.getString('AdminNum');

      if (adminPhoneNumber != null) {
        // Reference to the admin's Vehicles collection
        CollectionReference vehiclesCollection = FirebaseFirestore.instance
            .collection('AllUsers')
            .doc(adminPhoneNumber)
            .collection('Vehicles');

        // Fetch pricing details based on the vehicle image URL
        var snapshot = await vehiclesCollection
            .where('vehicleImage', isEqualTo: widget.imgUrl)
            .get();

        if (snapshot.docs.isNotEmpty) {
          pricingData = snapshot.docs.first.data() as Map<String, dynamic>;

          // Save fetched data to SharedPreferences for future use
          await prefs.setString(
              'pricingData_${widget.imgUrl}', jsonEncode(pricingData!));

          // Update UI
          setState(() {});
        } else {
          setState(() {
            pricingData = null; // Handle no matching vehicle
          });
        }
      } else {
        // Handle case where adminPhoneNumber is not in SharedPreferences
        setState(() {
          pricingData = null;
        });
      }
    } catch (e) {
      print('Error fetching pricing details: $e');
      setState(() {
        pricingData = null;
      });
    }
  }

  void _generateReceipt() async {
    FocusScope.of(context).unfocus();

    // Check if the container is selected and input is provided
    if (_selectedContainerIndex != null &&
        _controller.text.isNotEmpty &&
        pricingData != null) {
      // Show loading after validation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Color.fromARGB(255, 206, 200, 200),
              color: Colors.black,
            ),
          );
        },
      );

      // Define selected rate and price based on index
      var selectedRate = _selectedContainerIndex == 0
          ? '30 Minutes'
          : _selectedContainerIndex == 1
              ? '60 Minutes'
              : '120 Minutes';

      var price = _selectedContainerIndex == 0
          ? pricingData!['Pricing30Minutes']
          : _selectedContainerIndex == 1
              ? pricingData!['Pricing1Hour']
              : pricingData!['Pricing120Minutes'];

      num priceAsDouble = num.tryParse(price.toString()) ?? 0.0;

      // Firestore update logic with batch for efficiency
      WriteBatch batch = FirebaseFirestore.instance.batch();

      try {
        // Reference to the user's money collection document
        CollectionReference usersRef = FirebaseFirestore.instance
            .collection('AllUsers')
            .doc(adminPhoneNumber)
            .collection('Users')
            .doc(currentUserPhoneNumber)
            .collection('MoneyCollection');

        DocumentReference fixDocRef =
            usersRef.doc(DateFormat('yyyy-MM-dd').format(DateTime.now()));

        // Fetch document to check existing fixMoney
        DocumentSnapshot snapshot = await fixDocRef.get();
        num newTotal = priceAsDouble;

        if (snapshot.exists) {
          // If document exists, update the fixMoney field
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('fixMoney')) {
            num existingTotal = num.tryParse(data['fixMoney'] ?? '0.0') ?? 0.0;
            newTotal = existingTotal + priceAsDouble;
          }
        }

        // Batch update or set the fixMoney field
        batch.set(fixDocRef, {'fixMoney': newTotal.toString()},
            SetOptions(merge: true));

        // Add a new vehicle entry to the sub-collection
        CollectionReference vehicleEntryRef =
            fixDocRef.collection('vehicleEntry');
        batch.set(vehicleEntryRef.doc(), {
          'vehicleNumber': _controller.text,
          'entryTime': DateTime.now(),
          'entryType': 'Fix',
          'selectedTime': selectedRate,
          'selectedRate': price,
        });

        // Commit the batch write
        await batch.commit();

        // Close the loader
        Navigator.of(context).pop();

        // Navigate to the receipt screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Receipt(
              vehicleNumber: _controller.text,
              rateType: selectedRate,
              price: priceAsDouble.toString(),
              page: 'Fix',
            ),
          ),
        );
      } catch (e) {
        // Close the loader
        Navigator.of(context).pop();

        // Handle the error
        print('Error updating total money: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update total money. Please try again.'),
          ),
        );
      }
    } else {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select price and enter vehicle number.'),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 10, 10, 10),
          duration: Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 215, 206),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 225, 215, 206),
        title: Text(
          'Parking Rates',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: pricingData == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 6, 6, 6)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 3, 3, 3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _buildPricingContainer(
                            context,
                            '30 Minutes',
                            int.tryParse(
                                pricingData!['Pricing30Minutes'] ?? '0'),
                            0,
                          ),
                          const SizedBox(height: 16),
                          _buildPricingContainer(
                            context,
                            '60 Minutes',
                            int.tryParse(pricingData!['Pricing1Hour'] ?? '0'),
                            1,
                          ),
                          const SizedBox(height: 16),
                          _buildPricingContainer(
                            context,
                            '120 Minutes',
                            int.tryParse(
                                pricingData!['Pricing120Minutes'] ?? '0'),
                            2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                        width: MediaQuery.of(context).size.width -
                            48, // Decreases the width by 10 pixels
                        child: TextField(
                          controller: _controller,
                          keyboardType: widget.keyboardtype == 'numeric'
                              ? TextInputType.number
                              : TextInputType.text,
                          decoration: const InputDecoration(
                            hintText: 'Add vehicle number',
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2,
                                color: Colors.black, // Default black border
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2,
                                color: Color.fromARGB(255, 207, 239,
                                    1), // Green border when focused
                              ),
                            ),
                            border:
                                const OutlineInputBorder(), // This acts as a fallback border if others are not defined
                          ),
                        )),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generateReceipt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 207, 239, 1),
                              Color.fromARGB(255, 1, 1, 1),
                              Color.fromARGB(255, 207, 239, 1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 48,
                          height: 70,
                          alignment: Alignment.center,
                          child: Text(
                            'Generate Receipt',
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPricingContainer(
      BuildContext context, String timing, int? price, int index) {
    bool isSelected = _selectedContainerIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContainerIndex = index;
        });
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 225, 215, 206),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Color.fromARGB(255, 207, 239, 1)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(66, 247, 252, 226),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color.fromARGB(255, 207, 239, 1)
                      : Color.fromARGB(165, 250, 249, 248),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset('assets/animations/clock.json',
                        height: 23, width: 23),
                    const SizedBox(width: 4),
                    Text(timing),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 50),
              child: Text(
                '₹ ${price ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Lottie.asset('assets/animations/line.json', repeat: false),
            ),
          ],
        ),
      ),
    );
  }
}
