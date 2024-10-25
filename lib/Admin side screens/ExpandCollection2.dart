
import 'package:aapkaparking/Admin%20side%20screens/CollectionDetail1.dart';
import 'package:aapkaparking/Admin%20side%20screens/CollectionDetail2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Expandcollect2 extends StatefulWidget {
  final String userNo; // Pass userNo as argument

  const Expandcollect2({super.key, required this.userNo});

  @override
  State<Expandcollect2> createState() => _ExpandcollectState();
}

class _ExpandcollectState extends State<Expandcollect2> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;
  List<Map<String, dynamic>> moneyCollectionList = [];
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCollectionDetails(); // Fetch initial set of data
    _scrollController.addListener(_scrollListener); // Add scroll listener
  }

  // Scroll listener for pagination
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoading && hasMore) {
        _fetchCollectionDetails(); // Load more documents when scrolled to the bottom
      }
    }
  }

  // Function to fetch money collection data with pagination and optional date filtering
  Future<List<Map<String, dynamic>>> _fetchCollectionDetails(
      {DateTime? from, DateTime? to}) async {
    if (isLoading) return []; // Return an empty list when already loading
    setState(() => isLoading = true);

    final currentUserPhone = FirebaseAuth.instance.currentUser?.email;
    if (currentUserPhone == null) {
      setState(() => isLoading = false);
      return []; // Return an empty list if currentUserPhone is null
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection('AllUsers')
          .doc(currentUserPhone)
          .collection('Users')
          .doc(widget.userNo)
          .collection('MoneyCollection');

      // Apply date filtering if dates are provided
      if (fromDate != null && toDate != null) {
        String fromId = DateFormat('yyyy-MM-dd').format(fromDate!);
        String toId = DateFormat('yyyy-MM-dd').format(toDate!);

        query = query
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: fromId)
            .where(FieldPath.documentId, isLessThanOrEqualTo: toId);
      }
      query = query.orderBy(FieldPath.documentId, descending: true).limit(10);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastDocument =
            querySnapshot.docs.last; // Update the last document for pagination

        final fetchedData = querySnapshot.docs.map((doc) {
          final data = doc.data()
              as Map<String, dynamic>?; // Ensure the data is cast correctly

          return {
            'date': doc.id,
            'dueMoney': data?['dueMoney'] ?? 0,
            'fixMoney': data?['fixMoney'] ?? 0,
            'passMoney': data?['passMoney'] ?? 0,
          };
        }).toList();

        setState(() {
          moneyCollectionList.addAll(fetchedData);
        });

        if (querySnapshot.docs.length < 10) {
          setState(() => hasMore = false); // No more documents to fetch
        }

        return fetchedData; // Return fetched data
      } else {
        setState(() => hasMore = false);
        return []; // Return empty list if no documents are fetched
      }
    } catch (e) {
      print('Error fetching data: $e');
      return []; // Return an empty list in case of an error
    } finally {
      setState(() => isLoading = false);
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
                          moneyCollectionList.clear();
                          lastDocument = null;
                          hasMore = true;
                        });
                        _fetchCollectionDetails(); // Clear filter and fetch all documents
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
                            moneyCollectionList.clear();
                            lastDocument = null;
                            hasMore = true;
                          });
                          _fetchCollectionDetails(
                              from: fromDate, to: toDate); // Apply date filter
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
      backgroundColor:
          const Color.fromARGB(255, 225, 215, 206), // Light background color
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color.fromARGB(
            0, 255, 255, 255), // Transparent AppBar background
        elevation: 0, // Remove AppBar shadow
        centerTitle: true,
        title: Text(
          'Collection Details', // Fixed typo in title
          style: GoogleFonts.nunito(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors
                .black, // Text color to make it visible on a transparent background
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list,
                color: Colors.black), // Black color for filter icon
            onPressed:
                _showDateFilterDialog, // Show date filter dialog on press
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller:
                  _scrollController, // Attach the scroll controller for pagination
              itemCount: moneyCollectionList.length +
                  1, // Add 1 for the loading indicator
              itemBuilder: (context, index) {
                if (index < moneyCollectionList.length) {
                  final collection = moneyCollectionList[index];

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          0), // Rectangle shape with no rounding
                    ),
                    elevation: 0, // No shadow for transparent card
                    color: Colors.transparent, // Transparent background
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.black,
                            width: 1), // 1px solid black border
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            12.0), // Padding for the content
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // Format date as '01 Sept 2024'
                              'Date: ${DateFormat('dd MMM yyyy').format(DateTime.parse(collection['date']))}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    16, // Slightly larger font size for title
                                color: Colors
                                    .black87, // Darker color for better readability
                              ),
                            ),
                            const SizedBox(
                                height:
                                    10), // Space between date and containers
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Due Money Container
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CollectionDetail2(
                                          title: 'Due',
                                          usernum: widget.userNo,
                                          date: collection['date'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width:
                                        90, // Fixed width for even containers
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(
                                          0.1), // Light red background
                                      border: Border.all(
                                          color: Colors.black,
                                          width: 1), // 1px border
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Due',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .red, // Red text for due money
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${collection['dueMoney']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Fix Money Container
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CollectionDetails1(
                                          title: 'Fix',
                                          usernum: widget.userNo,
                                          date: collection['date'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width:
                                        90, // Fixed width for even containers
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(
                                          0.1), // Light green background
                                      border: Border.all(
                                          color: Colors.black,
                                          width: 1), // 1px border
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Fix',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .green, // Green text for fix money
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${collection['fixMoney']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Pass Money Container
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CollectionDetails1(
                                          title: 'Pass',
                                          usernum: widget.userNo,
                                          date: collection['date'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width:
                                        90, // Fixed width for even containers
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(
                                          0.1), // Light blue background
                                      border: Border.all(
                                          color: Colors.black,
                                          width: 1), // 1px border
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Pass',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .blue, // Blue text for pass money
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${collection['passMoney']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                          : hasMore
                              ? const SizedBox(
                                  height: 60,
                                )
                              : const Text('No more data'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
        .dispose(); // Clean up the scroll controller when the widget is disposed
    super.dispose();
  }
}
