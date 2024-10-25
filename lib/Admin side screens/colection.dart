
import 'package:aapkaparking/Admin%20side%20screens/ExpandCollection2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class Collection extends StatefulWidget {
  const Collection({super.key});

  @override
  State<Collection> createState() => _CollectionState();
}

class _CollectionState extends State<Collection> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;

  Future<List<Map<String, dynamic>>> fetchMoneyCollectionData(
      {DateTime? from, DateTime? to}) async {
    String currentUserPhoneNumber =
        FirebaseAuth.instance.currentUser?.email ?? '';

    if (currentUserPhoneNumber.isEmpty) {
      print("Error: User phone number is empty");
      return [];
    }

    // Define the date format
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    String todayDate = dateFormat.format(DateTime.now());

    var usersCollection = FirebaseFirestore.instance
        .collection('AllUsers')
        .doc(currentUserPhoneNumber)
        .collection('Users');

    // Get all user documents
    QuerySnapshot<Map<String, dynamic>> usersSnapshot =
        await usersCollection.get();

    List<Map<String, dynamic>> usersMoneyData = [];

    for (var userDoc in usersSnapshot.docs) {
      var userMoneyCollection =
          usersCollection.doc(userDoc.id).collection('MoneyCollection');

      int totalMoneyForUser = 0; // Total money sum for each user

      if (from != null && to != null) {
        // Convert from and to dates to 'yyyy-MM-dd' format
        String fromDateString = dateFormat.format(from);
        String toDateString = dateFormat.format(to);

        print("Filtering by document ID from $fromDateString to $toDateString");

        // Get all documents between the date range
        QuerySnapshot<Map<String, dynamic>> moneyCollectionSnapshot =
            await userMoneyCollection
                .where(FieldPath.documentId,
                    isGreaterThanOrEqualTo: fromDateString)
                .where(FieldPath.documentId, isLessThanOrEqualTo: toDateString)
                .get();

        for (var moneyDoc in moneyCollectionSnapshot.docs) {
          var moneyData = moneyDoc.data();
          if (moneyData != null) {
            // Parse and sum up each field only if present
            int fixMoney = int.tryParse(moneyData['fixMoney'] ?? '0') ?? 0;
            int dueMoney = int.tryParse(moneyData['dueMoney'] ?? '0') ?? 0;
            int passMoney = int.tryParse(moneyData['passMoney'] ?? '0') ?? 0;

            int sumOfFields = fixMoney + dueMoney + passMoney;

            // Add the money from this document if it's greater than 0
            if (sumOfFields > 0) {
              totalMoneyForUser += sumOfFields;
            }
          }
        }
      } else {
        // If no date range is provided, get today's document
        print("Fetching document for today: $todayDate");
        DocumentSnapshot<Map<String, dynamic>> todaySnapshot =
            await userMoneyCollection.doc(todayDate).get();

        if (todaySnapshot.exists) {
          var moneyData = todaySnapshot.data();
          if (moneyData != null) {
            // Parse and sum up each field only if present
            int fixMoney = int.tryParse(moneyData['fixMoney'] ?? '0') ?? 0;
            int dueMoney = int.tryParse(moneyData['dueMoney'] ?? '0') ?? 0;
            int passMoney = int.tryParse(moneyData['passMoney'] ?? '0') ?? 0;

            totalMoneyForUser = fixMoney + dueMoney + passMoney;
          }
        }
      }

      // Add the data for the user, regardless of whether today or filtered dates
      if (totalMoneyForUser > 0) {
        usersMoneyData.add({
          'userName': userDoc.data()['userName'] ?? 'Unknown User',
          'uid': userDoc.data()['uid'] ?? 'Unknown UID',
          'totalMoney': totalMoneyForUser.toString(),
        });
      }
    }

    return usersMoneyData;
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
                          setState(() {});
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
      backgroundColor: const Color.fromARGB(255, 225, 215, 206),
      appBar: AppBar(
        title: Text(
          'Money Collection',
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
        backgroundColor: const Color.fromARGB(0, 238, 236, 236),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showDateFilterDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchMoneyCollectionData(from: fromDate, to: toDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 2, 2, 2)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Lottie.asset('assets/animations/notfound2.json',
                    height: 300, width: 300));
          }

          var usersMoneyData = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: usersMoneyData.length,
            itemBuilder: (context, index) {
              var userData = usersMoneyData[index];
              var userName = userData['userName'];
              var userUID = userData['uid'];
              var totalMoney = userData['totalMoney'];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double containerWidth = constraints.maxWidth;
                    double containerHeight = containerWidth * 0.46;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Expandcollect2(
                                    userNo: userUID.toString(),
                                  )),
                        );
                      },
                      child: Container(
                        width: containerWidth,
                        height: containerHeight *
                            0.8, // Reducing the height slightly
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                              10.0), // Adjust padding to ensure alignment
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row for the username with the person icon
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person, // Person icon
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                  const SizedBox(
                                      width:
                                          8), // Spacing between icon and text
                                  Expanded(
                                    child: Text(
                                      userName,
                                      style: GoogleFonts.nunito(
                                        color: Colors.black,
                                        fontSize:
                                            18, // Slightly reduced font size for balance
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow
                                          .ellipsis, // Ensure text doesn't overflow
                                    ),
                                  ),
                                ],
                              ),
                              // Row for the UID with the phone icon
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone, // Phone icon
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Email: $userUID',
                                    style: GoogleFonts.nunito(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              // Total money section
                              _buildTotalMoneyCard('Total', totalMoney),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTotalMoneyCard(String title, String amount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = constraints.maxWidth * 0.06;

        return Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(91, 255, 255, 255),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
              Text(
                '₹ $amount',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: Colors.green[900],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
