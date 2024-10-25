import 'dart:io';
import 'dart:ui' as ui;

import 'package:aapkaparking/User%20side%20screens/bluetoothManager.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;

class Receipt extends StatefulWidget {
  final String vehicleNumber;
  final String rateType;
  final String price;
  final String page;

  const Receipt({
    super.key,
    required this.vehicleNumber,
    required this.rateType,
    required this.price,
    required this.page,
  });

  @override
  State<Receipt> createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  final DateFormat formatter = DateFormat('HH:mm:ss');
  String parkingLogo = '';
  String parkingName = '';
  bool isLoading = true;
  BluetoothManager bluetoothManager = BluetoothManager();
  String? pdfFilePath;
  @override
  void initState() {
    super.initState();
    findAdminAndFetchParkingDetails();
    // if (widget.page == 'Pass') {
    //   _saveQrCodeToFile(widget.vehicleNumber);
    // }
  }

  Future<void> clearParkingDetailsFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Remove specific fields (parkingLogo and parkingName) from SharedPreferences
    await prefs.remove('ParkingName');
    await prefs.remove('ParkingLogo');

    // Optionally, update your state to reflect the cleared data
    setState(() {
      parkingName = ''; // Clear the parkingName variable in the app
      parkingLogo = ''; // Clear the parkingLogo variable in the app
    });
    findAdminAndFetchParkingDetails();
    print('Parking details cleared from SharedPreferences');
  }

  Future<void> findAdminAndFetchParkingDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Check if parkingName and parkingLogo are already saved in SharedPreferences
      String? savedParkingName = prefs.getString('ParkingName');
      String? savedParkingLogo = prefs.getString('ParkingLogo');

      if (savedParkingName != null && savedParkingLogo != null) {
        // If parking details are already in SharedPreferences, use them
        setState(() {
          parkingName = savedParkingName;
          parkingLogo = savedParkingLogo;
          isLoading = false;
        });
      } else {
        // Get the admin's phone number from SharedPreferences
        String? adminPhoneNumber = prefs.getString('AdminNum');

        if (adminPhoneNumber == null) {
          // Handle the case where the admin phone number is not available
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Reference to the AllUsers collection
        DocumentReference adminDocRef = FirebaseFirestore.instance
            .collection('AllUsers')
            .doc(adminPhoneNumber);

        // Fetch the admin document
        DocumentSnapshot adminDoc = await adminDocRef.get();

        if (adminDoc.exists) {
          // Extract parking name and logo from the admin's document
          Map<String, dynamic> adminData =
              adminDoc.data() as Map<String, dynamic>;
          String fetchedParkingName =
              adminData['ParkingName'] ?? 'Parking Name';
          String fetchedParkingLogo = adminData['ParkingLogo'] ?? '';

          // Save parking details to SharedPreferences
          await prefs.setString('ParkingName', fetchedParkingName);
          await prefs.setString('ParkingLogo', fetchedParkingLogo);

          setState(() {
            parkingName = fetchedParkingName;
            parkingLogo = fetchedParkingLogo;
            isLoading = false;
          });

          // Call printReceipt to print the receipt
          printReceipt();
        } else {
          // If admin document doesn't exist
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching parking details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateAndSharePDF(String data) async {
    final pdf = pw.Document();

    // Generate the PDF layout
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  parkingName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 50),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Parking Type: Pass',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    'Vehicle No.: ${widget.vehicleNumber}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 50),
              pw.Center(
                child: pw.Text(
                  'Amount Paid: Rs. ${widget.price}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Container(
                  width: 300,
                  height: 300,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: data,
                    width: 300,
                    height: 300,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Convert PDF to bytes and share directly
    final pdfBytes = await pdf.save();
    final tempDir = Directory.systemTemp;
    final file =
        File('${tempDir.path}/Pass_qr_code_${widget.vehicleNumber}.pdf');
    await file.writeAsBytes(pdfBytes);

    // Show dialog to share
    _showShareDialog(file.path);
  }

  void _showShareDialog(String pdfFilePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'PDF Generated',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'The Pass PDF has been generated successfully. Do you want to share?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0), // Square shape
                  side: const BorderSide(color: Colors.black), // Black border
                ),
                backgroundColor: Colors.white, // White background
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.black, // Black text
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0), // Square shape
                ),
                backgroundColor: Colors.black, // Black background
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _shareOnWhatsApp(pdfFilePath);
              },
              child: const Text(
                'Share PDF',
                style: TextStyle(
                  color: Colors.white, // White text
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareOnWhatsApp(String pdfFilePath) async {
    try {
      // Use share_plus to share the PDF file via WhatsApp or any other app
      await Share.shareXFiles(
        [XFile(pdfFilePath)],
        text:
            'Here is your parking receipt for vehicle ${widget.vehicleNumber}.',
      );
    } catch (e) {
      print("Error sharing PDF on WhatsApp: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
        ),
      );
    }
  }

  Future<void> printReceipt() async {
    final printer = bluetoothManager.printer;

    printer.printNewLine();
    printer.printCustom('${widget.page} Receipt Details', 4, 1);
    printer.printNewLine();

    printer.printCustom(parkingName, 4, 1);
    printer.printNewLine();

    String dateTime =
        'DATE: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}, Time: ${DateFormat('hh:mm a').format(DateTime.now())}';
    printer.printCustom(dateTime, 1, 1);
    printer.printNewLine();

    printer.printCustom('Vehicle No.:${widget.vehicleNumber}', 2, 1);
    printer.printNewLine();
    printer.printCustom('Amount: Rs:${widget.price}', 2, 1);
    printer.printNewLine();

    printer.printQRcode(widget.vehicleNumber, 220, 220, 1);
    printer.printNewLine();
    // final qrFilePath = await _saveQrCodeToFile(widget.vehicleNumber);

    // Print the QR code image from the file path
    // printer.printImage(qrFilePath);
    printer.printNewLine();
    printer.printCustom('Thank you, Lucky Road!', 1, 1);
    printer.printNewLine();
    printer.paperCut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 215, 206),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 225, 215, 206),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              clearParkingDetailsFromSharedPreferences();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              _generateAndSharePDF(widget.vehicleNumber);
            },
          )
        ],
        centerTitle: true,
        title: Text(
          'Receipt Details',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 3.0, // Add elevation
        shadowColor: const Color.fromARGB(
            255, 25, 239, 1), // Green shadow color with slight transparency
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: ui.Color.fromARGB(255, 2, 2, 2),
            ))
          : LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 55, // Adjust the radius as needed
                                backgroundColor: Colors.grey[
                                    200], // Background color for the avatar
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: parkingLogo,
                                    height: constraints.maxHeight * 0.15,
                                    width: constraints.maxHeight *
                                        0.15, // Ensure the width and height are equal for the circle
                                    fit: BoxFit
                                        .cover, // Ensures the image covers the whole circle
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(
                                      color: Colors.black,
                                    ), // optional: placeholder while loading
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons
                                            .error), // optional: error widget
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              AutoSizeText(
                                parkingName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1, // Limits the text to one line
                                minFontSize:
                                    16, // Minimum font size it will scale down to
                                overflow: TextOverflow
                                    .ellipsis, // Adds '...' if text overflows
                              ),
                            ],
                          ),
                          Container(
                            height: 2,
                            color: const Color.fromARGB(255, 25, 239, 1),
                          ),
                          Text(
                            'Paid Parking',
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'DATE: ${DateFormat('dd MMM yyyy').format(DateTime.now())}, Time: ${DateFormat('hh:mm a').format(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Column(
                            children: [
                              Text(
                                'Vehicle No.: ${widget.vehicleNumber}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Amount: ₹${widget.price}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          QrImageView(
                            data: widget.vehicleNumber,
                            size: constraints.maxHeight * 0.3,
                            backgroundColor: Colors.white,
                          ),
                          Container(
                            height: 2,
                            color: const Color.fromARGB(255, 25, 239, 1),
                          ),
                          const Text(
                            'Thank you, Lucky Road!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
