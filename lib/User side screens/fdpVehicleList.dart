

import 'package:aapkaparking/User%20side%20screens/PassRate.dart';
import 'package:aapkaparking/User%20side%20screens/dueInRate.dart';
import 'package:aapkaparking/User%20side%20screens/fixrate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // To handle JSON encoding and decoding

class FdpVehicles extends StatefulWidget {
  final String keyboardtype;
  final String title;
  const FdpVehicles(
      {super.key, required this.keyboardtype, required this.title});

  @override
  State<FdpVehicles> createState() => _fdpState();
}

class _fdpState extends State<FdpVehicles> {
  List<Map<String, dynamic>> vehicleList = [];

  @override
  void initState() {
    super.initState();
    loadVehicleData();
  }

  Future<void> loadVehicleData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? vehicleData = prefs.getString('vehicleData');

    if (vehicleData != null) {
      // Data exists in SharedPreferences, decode it and use it
      setState(() {
        vehicleList = List<Map<String, dynamic>>.from(
            jsonDecode(vehicleData)); // Corrected type
      });
    } else {
      // Data not in SharedPreferences, fetch it from Firestore
      await fetchVehicleDataFromFirestore();
    }
  }

  Future<void> fetchVehicleDataFromFirestore() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentUserPhoneNumber = currentUser?.email ?? 'unknown';

    try {
      // Retrieve the admin phone number from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? adminPhoneNumber = prefs.getString('AdminNum');

      if (adminPhoneNumber != null) {
        CollectionReference allUsersRef =
            FirebaseFirestore.instance.collection('AllUsers');
        DocumentReference adminDocRef = allUsersRef.doc(adminPhoneNumber);
        CollectionReference usersRef = adminDocRef.collection('Users');
        DocumentSnapshot userDoc =
            await usersRef.doc(currentUserPhoneNumber).get();

        if (userDoc.exists) {
          CollectionReference vehiclesRef = adminDocRef.collection('Vehicles');
          QuerySnapshot vehiclesSnapshot =
              await vehiclesRef.where('pricingdone', isEqualTo: true).get();

          List<Map<String, dynamic>> fetchedVehicles =
              vehiclesSnapshot.docs.map((doc) {
            return {
              'vehicleImage': doc['vehicleImage'],
              'vehicleName': capitalize(doc['vehicleName'] ?? 'Unknown'),
            };
          }).toList();

          // Save fetched vehicle data to SharedPreferences
          await prefs.setString('vehicleData', jsonEncode(fetchedVehicles));

          // Update UI with the fetched data
          setState(() {
            vehicleList = fetchedVehicles;
          });
        }
      }
    } catch (e) {
      print('Error retrieving vehicle data: $e');
      setState(() {
        vehicleList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 215, 206),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 253, 216, 53),
        title: Text(
          'All Vehicles',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchVehicleDataFromFirestore,
        child: vehicleList.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 9, 9, 9)))
            : GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: vehicleList.length,
                itemBuilder: (context, index) {
                  var vehicle = vehicleList[index];
                  var imageUrl = vehicle['vehicleImage'];
                  var vehicleName = vehicle['vehicleName'];

                  return GestureDetector(
                    onTap: () {
                      if (widget.title == 'Fix') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Fixirate(
                              imgUrl: imageUrl,
                              keyboardtype: widget.keyboardtype,
                            ),
                          ),
                        );
                      }
                      if (widget.title == 'Due') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Duerate(
                              imgUrl: imageUrl,
                              keyboardtype: widget.keyboardtype,
                            ),
                          ),
                        );
                      }
                      if (widget.title == 'Pass') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Passrate(
                              imgUrl: imageUrl,
                              keyboardtype: widget.keyboardtype,
                            ),
                          ),
                        );
                      }
                    },
                    child: Card(
                      elevation: 10.0,
                      color: const Color.fromARGB(255, 225, 215, 206),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/animations/placeholder.png',
                                    fit: BoxFit.cover,
                                    height: 134,
                                    width: double.infinity,
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    height: 134,
                                    width: double.infinity,
                                    placeholder: (context, url) => Container(
                                      alignment: Alignment.center,
                                      color: Colors.transparent,
                                      child: const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.yellow),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: AutoSizeText(
                              vehicleName,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              minFontSize: 12,
                              maxFontSize: 17,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
