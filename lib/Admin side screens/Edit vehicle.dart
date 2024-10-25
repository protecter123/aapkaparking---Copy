import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EditVehicle extends StatefulWidget {
  const EditVehicle({super.key});

  @override
  State<EditVehicle> createState() => _EditVehicleState();
}

class _EditVehicleState extends State<EditVehicle> {
  Future<void> _showEditPricingDialog(String docId, String pricing30,
      String pricing60, String pricing120, String passPrice) async {
    final TextEditingController _pricing30Controller =
        TextEditingController(text: pricing30);
    final TextEditingController _pricing60Controller =
        TextEditingController(text: pricing60);
    final TextEditingController _pricing120Controller =
        TextEditingController(text: pricing120);
    final TextEditingController _passPricingController =
        TextEditingController(text: passPrice);
    final String vehiclename = docId;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 225, 215, 206),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            'Edit ${vehiclename.toUpperCase()} Pricing',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPricingField(
                  'Edit pricing for 30 minutes', _pricing30Controller),
              const SizedBox(height: 10),
              _buildPricingField(
                  'Edit pricing for 60 minutes', _pricing60Controller),
              const SizedBox(height: 10),
              _buildPricingField(
                  'Edit pricing for 120 minutes', _pricing120Controller),
              const SizedBox(height: 10),
              _buildPricingField(
                  'Edit pricing for Pass', _passPricingController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without action
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Black button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rectangular shape
                ),
              ),
              onPressed: () async {
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
                await _updateVehiclePricing(
                    docId,
                    _pricing30Controller.text,
                    _pricing60Controller.text,
                    _pricing120Controller.text,
                    _passPricingController.text);
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close dialog after saving
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPricingField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly
      ], // Restrict input to numbers only
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(), // Rectangular shape
      ),
    );
  }

  Future<void> _updateVehiclePricing(String docId, String pricing30,
      String pricing60, String pricing120, String passPrice) async {
    final phoneNumber = FirebaseAuth.instance.currentUser?.email ?? '';
    await FirebaseFirestore.instance
        .collection('AllUsers')
        .doc(phoneNumber)
        .collection('Vehicles')
        .where('vehicleName', isEqualTo: docId) // Query by vehicleName
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // Assuming only one document matches, get the first document
        var docId = querySnapshot.docs.first.id;

        // Now update the document with the found docId
        FirebaseFirestore.instance
            .collection('AllUsers')
            .doc(phoneNumber)
            .collection('Vehicles')
            .doc(docId)
            .update({
          'Pricing30Minutes': pricing30,
          'Pricing1Hour': pricing60,
          'Pricing120Minutes': pricing120,
          'PassPrice': passPrice,
        }).then((_) {
          print('Vehicle pricing updated successfully.');
        }).catchError((error) {
          print('Failed to update vehicle pricing: $error');
        });
      } else {
        print('No vehicle found with the given name.');
      }
    }).catchError((error) {
      print('Error fetching vehicle: $error');
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle pricing updated successfully'),
          duration: Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 215, 206),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Vehicle List',
          style: GoogleFonts.baskervville(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(0, 255, 235, 59),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('AllUsers')
            .doc(FirebaseAuth.instance.currentUser?.email)
            .collection('Vehicles')
            .where('pricingdone',
                isEqualTo: true) // Filter where pricingdone is true
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
              color: Color.fromARGB(255, 7, 7, 7),
            ));
          }

          final vehicles = snapshot.data!.docs;

          if (vehicles.isEmpty) {
            return const Center(
              child: Text(
                'No vehicles found.',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final vehicleName =
                  _capitalizeFirstLetter(vehicle['vehicleName'] ?? '');
              final vehicleImage = vehicle['vehicleImage'] ?? '';
              final pricing30Minutes = vehicle['Pricing30Minutes'] ?? 'N/A';
              final pricing1Hour = vehicle['Pricing1Hour'] ?? 'N/A';
              final pricing120Minutes = vehicle['Pricing120Minutes'] ?? 'N/A';
              final passPrice = vehicle['PassPrice'] ?? 'N/A';

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: vehicleImage.isNotEmpty
                            ? Stack(
                                children: [
                                  // Asset image placeholder (visible while the network image is loading)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/animations/placeholder.png', // Placeholder asset image
                                      fit: BoxFit.cover,
                                      height: 144,
                                      width: double.infinity,
                                    ),
                                  ),

                                  // Cached network image with a loader
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(0),
                                    child: CachedNetworkImage(
                                      imageUrl: vehicleImage,
                                      fit: BoxFit.cover,
                                      height: 144,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        alignment: Alignment.center,
                                        color: Colors.transparent,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 1,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.black), // Loader color
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                      cacheKey:
                                          vehicleImage, // Ensuring image is cached correctly
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(Icons.directions_car, size: 80),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      vehicleName,
                                      style: GoogleFonts.nunito(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10.0,
                              runSpacing: 8.0,
                              children: [
                                _buildPriceRow('30 min', pricing30Minutes,
                                    Icons.timer, Colors.red),
                                _buildPriceRow('1 hour', pricing1Hour,
                                    Icons.access_time, Colors.blue),
                                _buildPriceRow('120 min', pricing120Minutes,
                                    Icons.watch_later, Colors.green),
                                _buildPassPriceRow('Pass', passPrice),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              onPressed: () {
                                _showEditPricingDialog(
                                    vehicle['vehicleName'],
                                    pricing30Minutes,
                                    pricing1Hour,
                                    pricing120Minutes,
                                    passPrice);
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.black),
                              onPressed: () {
                                _showDeleteConfirmationDialog(vehicle.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  Widget _buildPriceRow(
      String label, String price, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$label: ₹$price',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassPriceRow(String label, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: Colors.black),
          const SizedBox(width: 5),
          Text(
            '$label: ₹$price',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(String docId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 225, 215, 206),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Are you sure you want to delete?',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without action
              },
              child: const Text(
                'No',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteVehicle(docId); // Call the delete function
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVehicle(String docId) async {
    final phoneNumber = FirebaseAuth.instance.currentUser?.email ?? '';
    await FirebaseFirestore.instance
        .collection('AllUsers')
        .doc(phoneNumber)
        .collection('Vehicles')
        .doc(docId)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle deleted successfully')),
      );
    }
  }
}
