import 'dart:async';
import 'dart:io';

import 'package:aapkaparking/User%20side%20screens/AfterPassScan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

class FpList extends StatefulWidget {
  final String label;

  const FpList({super.key, required this.label});

  @override
  State<FpList> createState() => _FpListState();
}

class _FpListState extends State<FpList> {
  String? adminNum;
  String? userPhoneNumber;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> allEntries = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredEntries = [];
  bool isLoading = false;
  bool hasMoreData = true;
  DocumentSnapshot<Map<String, dynamic>>? lastDocument; // For pagination
  final int pageSize = 5; // Fetch 5 documents at a time
  final ScrollController _scrollController = ScrollController();
  String searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;
  String ParkingName = '';
  @override
  void initState() {
    super.initState();
    _getUserPhoneNumber();
    _getAdminNum();
    fetchParkingNameFromSharedPreferences();
    _scrollController.addListener(_onScroll); // Listen for scroll to bottom
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose(); // Dispose search controller when done
    super.dispose();
  }

  Future<void> fetchParkingNameFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedParkingName = prefs.getString('ParkingName');

    // Check if the value exists and assign it to parkingName
    if (storedParkingName != null && storedParkingName.isNotEmpty) {
      setState(() {
        ParkingName = storedParkingName;
      });
    } else {
      print('Parking name not found in SharedPreferences');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query.toLowerCase();
        _filterEntriesBySearchQuery();
      });
    });
  }

  void _filterEntriesBySearchQuery() {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredEntries =
            List.from(allEntries); // Copy all entries to filtered list
      } else {
        filteredEntries = allEntries.where((entry) {
          final vehicleNumber =
              (entry['vehicleNumber'] ?? '').toString().toLowerCase();
          return vehicleNumber.contains(searchQuery);
        }).toList();
      }
    });
  }

  // Fetch the admin number from shared preferences
  Future<void> _getAdminNum() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      adminNum = prefs.getString('AdminNum');
      debugPrint('AdminNum fetched: $adminNum');
      _fetchVehicleData(); // Fetch initial data after adminNum is loaded
    });
  }

  // Fetch the current user's phone number from Firebase Auth
  void _getUserPhoneNumber() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userPhoneNumber = user.email;
        debugPrint('User phone number fetched: $userPhoneNumber');
      });
    }
  }

  // Fetch the vehicle entry data with pagination
  // Fetch the vehicle entry data with pagination and limit to 5
  Future<void> _fetchVehicleData({DateTime? from, DateTime? to}) async {
    if (isLoading || !hasMoreData) return;
    setState(() {
      isLoading = true;
    });

    try {
      if (adminNum != null && userPhoneNumber != null) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('AllUsers')
            .doc(adminNum)
            .collection('Users')
            .doc(userPhoneNumber)
            .collection('MoneyCollection');

        // Apply date range filter only if fromDate and toDate are both selected
        if (from != null && to != null) {
          String formattedFromDate = DateFormat('yyyy-MM-dd').format(from);
          String formattedToDate = DateFormat('yyyy-MM-dd').format(to);
          query = query
              .where(FieldPath.documentId,
                  isGreaterThanOrEqualTo: formattedFromDate)
              .where(FieldPath.documentId,
                  isLessThanOrEqualTo: formattedToDate);
          debugPrint(
              'Date range applied: $formattedFromDate to $formattedToDate');
        }

        query = query
            .orderBy(FieldPath.documentId, descending: true)
            .limit(pageSize);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument!);
        }

        QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
        debugPrint('Fetched ${snapshot.docs.length} documents from Firestore');

        if (snapshot.docs.isNotEmpty) {
          final docs = snapshot.docs;
          lastDocument = docs.last;

          for (var doc in docs) {
            QuerySnapshot<Map<String, dynamic>> vehicleEntries =
                await FirebaseFirestore.instance
                    .collection('AllUsers')
                    .doc(adminNum)
                    .collection('Users')
                    .doc(userPhoneNumber)
                    .collection('MoneyCollection')
                    .doc(doc.id)
                    .collection('vehicleEntry')
                    .where('entryType', isEqualTo: widget.label)
                    .orderBy('entryTime', descending: true)
                    .get();

            allEntries.addAll(vehicleEntries.docs);
            debugPrint('Vehicle entries added: ${vehicleEntries.docs.length}');
            _filterEntriesBySearchQuery();
          }

          if (snapshot.docs.length < pageSize) {
            hasMoreData = false;
          }
        } else {
          hasMoreData = false;
          debugPrint('No more data available');
        }
      }
    } catch (e) {
      debugPrint('Error fetching vehicle data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Load more data when user scrolls to the bottom
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchVehicleData();
    }
  }

  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 225, 215, 206),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Date Range',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildDateField('From Date', _fromDateController, (pickedDate) {
                  setState(() {
                    fromDate = pickedDate;
                  });
                }),
                const SizedBox(height: 10),
                _buildDateField('To Date', _toDateController, (pickedDate) {
                  setState(() {
                    toDate = pickedDate;
                  });
                }),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _fromDateController.clear();
                          _toDateController.clear();
                          fromDate = null;
                          toDate = null;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      child: const Text('Clear',
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (fromDate != null && toDate != null) {
                          setState(() {
                            allEntries
                                .clear(); // Clear previous data when applying new filters
                            filteredEntries.clear();
                            lastDocument = null;
                            _fetchVehicleData(from: fromDate, to: toDate);
                          });
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      child: const Text('Apply',
                          style: TextStyle(color: Colors.white)),
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

  Future<void> _generateAndSharePDF(
      String Vehiclenum, String Rate, String time) async {
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
                  ParkingName.toUpperCase(),
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
                    'Vehicle No.: ${Vehiclenum}',
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
                  'Amount Paid: Rs. ${Rate}',
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
                    data: Vehiclenum,
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
    final file = File('${tempDir.path}/Pass_qr_code_${Vehiclenum}.pdf');
    await file.writeAsBytes(pdfBytes);

    // Show dialog to share
    _showShareDialog(file.path, Vehiclenum);
  }

  void _showShareDialog(String pdfFilePath, String Vehiclenum) {
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
            'The Pass PDF has been generated successfully. Do you want to share it on WhatsApp?',
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
                await _shareOnWhatsApp(pdfFilePath, Vehiclenum);
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

  Future<void> _shareOnWhatsApp(String pdfFilePath, String Vehiclenum) async {
    try {
      // Use share_plus to share the PDF file via WhatsApp or any other app
      await Share.shareXFiles(
        [XFile(pdfFilePath)],
        text: 'Here is your parking receipt for vehicle ${Vehiclenum}.',
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

  Widget _buildDateField(String label, TextEditingController controller,
      Function(DateTime) onDatePicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            focusColor: Colors.orange,
            hintText: 'Select Date',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(DateTime.now().year, DateTime.now().month - 3,
                  DateTime.now().day),
              lastDate: DateTime.now(),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors
                          .orange, // Header background color and selection color
                      onPrimary: Colors.white, // Text color on the header
                      onSurface: Colors.black, // Default text color
                    ),
                    dialogBackgroundColor:
                        Colors.white, // Background color of the dialog
                  ),
                  child: child!,
                );
              },
            );

            if (pickedDate != null) {
              controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
              onDatePicked(pickedDate);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4.0,
        centerTitle: true,
        title: Text(
          '${widget.label} Entries',
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showDateFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8, top: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromARGB(255, 255, 255, 255),
                labelText: 'Search by vehicle number',
                labelStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color.fromARGB(255, 255, 204, 0), // Modern icon color
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? IconButton(
                        icon: const Icon(Icons.keyboard, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          FocusScope.of(context).unfocus();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                  borderSide: const BorderSide(
                    color: Color.fromARGB(94, 0, 0, 0), // No visible border
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(97, 0, 0, 0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Colors.orange, // Highlighted border on focus
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 20.0),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
              onChanged: (value) {
                _onSearchChanged(value);
              },
            ),
          ),
          adminNum == null || userPhoneNumber == null
              ? const Center(
                  child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 0, 0, 0),
                ))
              : Expanded(
                  child: filteredEntries.isEmpty && !isLoading
                      ? Center(
                        child: Lottie.asset(
                          'assets/animations/notfound2.json', // Path to the Lottie file
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      )
                      : filteredEntries.isEmpty && isLoading
                      ?const Center(
                        child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 0, 0, 0),
                )
                      )
                      : ListView.builder(
                          controller:
                              _scrollController, // Attach scroll controller
                          itemCount:
                              filteredEntries.length + (isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredEntries.length) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                    child: CircularProgressIndicator(
                                  color: Color.fromARGB(0, 0, 0, 0),
                                )),
                              ); // Loading indicator at the end
                            }
                            if (filteredEntries.isEmpty) {
                              return Center(
                                child: Lottie.asset(
                                  'assets/animations/animation.json', // Path to the Lottie file
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            final doc = filteredEntries[index];
                            final vehicleNumber =
                                doc['vehicleNumber'] ?? 'No Vehicle Number';
                            final selectedTime =
                                doc['selectedTime'] ?? 'No Selected Time';
                            final entryTime =
                                (doc['entryTime'] as Timestamp).toDate();

                            return GestureDetector(
                              onTap: () {
                              if (widget.label=='Pass') {
                                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AfterPassScan(
                        vehicleNumber: vehicleNumber,
                      ),
                    ),
                  );
                              }
                              },
                              child: Container(
                                margin: const EdgeInsets.all(8.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween, // Ensures spacing between elements
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.directions_car,
                                                color: Colors.yellow),
                                            const SizedBox(width: 8),
                                            Text(
                                              vehicleNumber,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (widget.label == 'Pass')
                                          IconButton(
                                            icon: const Icon(Icons.share,
                                                color: Colors.black),
                                            onPressed: () {
                                              // Call the function to generate and share the PDF
                                              _generateAndSharePDF(
                                                  vehicleNumber,
                                                  doc['selectedRate'],
                                                  selectedTime);
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Selected Time: $selectedTime',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('d MMM yyyy')
                                              .format(entryTime),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          DateFormat('h:mm a')
                                              .format(entryTime),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
