import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AfterPassScan extends StatefulWidget {
  final String vehicleNumber;

  const AfterPassScan({Key? key, required this.vehicleNumber})
      : super(key: key);

  @override
  State<AfterPassScan> createState() => _AfterPassScanState();
}

class _AfterPassScanState extends State<AfterPassScan> {
  String adminNum = '';
  String entryTime = '';
  String selectedTime = '';
  bool isPassValid = false;
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _fetchAdminNumAndPassDetails();
  }

  Future<void> _fetchAdminNumAndPassDetails() async {
    // Fetch admin number from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    adminNum = prefs.getString('AdminNum') ?? '';
    print('AdminNum from SharedPreferences: $adminNum');

    // Fetch the current user's phone number (auth phone number)
    User? currentUser = FirebaseAuth.instance.currentUser; // Get current user
    String? userPhoneNumber = currentUser
        ?.email; // You need to fetch this based on your auth logic
    print(
        'UserPhoneNumber (should be filled with actual auth logic): $userPhoneNumber');

    // Check if adminNum or userPhoneNumber is empty
    if (adminNum.isEmpty || userPhoneNumber == null) {
      print('Error: Either adminNum or userPhoneNumber is empty');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Navigate Firestore path: AllUsers -> AdminNum (doc) -> users (subcollection) -> userPhoneNumber -> MoneyCollection
    var moneyCollection = FirebaseFirestore.instance
        .collection('AllUsers')
        .doc(adminNum)
        .collection('Users')
        .doc(userPhoneNumber)
        .collection('MoneyCollection');

    print('Fetching documents from MoneyCollection...');

    // Get all documents in MoneyCollection (which are date documents) and reverse them
    var querySnapshot = await moneyCollection.get();
    final dateDocs = querySnapshot.docs.reversed.toList();
    print('Fetched ${dateDocs.length} documents from MoneyCollection');

    // Iterate through each date document in reversed order
    for (var dateDoc in dateDocs) {
      print('Checking dateDoc ID: ${dateDoc.id}');

      var vehicleEntryCollection = dateDoc.reference.collection('vehicleEntry');

      // Query for the vehicle with the matching number and entryType 'Pass'
      var vehicleQuerySnapshot = await vehicleEntryCollection
          .where('vehicleNumber', isEqualTo: widget.vehicleNumber)
          .where('entryType', isEqualTo: 'Pass')
          .get();

      print(
          'Found ${vehicleQuerySnapshot.docs.length} matching vehicle entries in vehicleEntry for vehicleNumber: ${widget.vehicleNumber}');

      // If we find matching entries, process the data
      for (var vehicleDoc in vehicleQuerySnapshot.docs) {
        Map<String, dynamic> data = vehicleDoc.data();
        print('Vehicle doc data: $data');

        entryTime = (data['entryTime'] as Timestamp)
            .toDate()
            .toString(); // The time when the pass was generated
        selectedTime = data['selectedTime']; // E.g., '1 month Pass'

        print('EntryTime: $entryTime');
        print('SelectedTime: $selectedTime');

        // Check pass validity
        _checkPassValidity();
        setState(() {
          isLoading = false; // Data is now loaded
        });

        // Stop further searching once a match is found
        return;
      }
    }

    // If no match is found, stop loading
    setState(() {
      isLoading = false;
    });
    print('No matching vehicle entries found.');
  }

  void _checkPassValidity() {
    try {
      // Extract the number of months from selectedTime (e.g., '1 month Pass')
      int months = int.parse(selectedTime.split(' ')[0]);
      print('Extracted months from selectedTime: $months');

      // Parse entryTime into a DateTime object
      DateTime entryDateTime = DateTime.parse(entryTime);
      print('Parsed entryDateTime: $entryDateTime');

      // Add the months to the entryTime to calculate expiry
      DateTime expiryDate = DateTime(
          entryDateTime.year, entryDateTime.month + months, entryDateTime.day);
      print('Calculated expiryDate: $expiryDate');

      // Compare expiryDate with the current date
      isPassValid = expiryDate.isAfter(DateTime.now());
      print('Is pass valid: $isPassValid');
    } catch (e) {
      // Handle any errors
      print('Error while checking pass validity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pass Scan Details ${widget.vehicleNumber}'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ), // Show loader when data is being fetched
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Entry Time: ${entryTime.isNotEmpty ? DateFormat('d MMM yyyy').format(DateTime.parse(entryTime)) : 'Loading...'}'),
                      Text('Selected Time: $selectedTime'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    isPassValid ? Icons.check_circle : Icons.error,
                    color: isPassValid ? Colors.green : Colors.red,
                    size: 100,
                  ),
                  Text(
                    isPassValid ? 'Pass is Valid' : 'Pass is Not Valid',
                    style: TextStyle(
                        fontSize: 24,
                        color: isPassValid ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ),
    );
  }
}
