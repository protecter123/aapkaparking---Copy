import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // For date formatting

class CollectionDetails1 extends StatefulWidget {
  final String title;
  final String date;
  final String usernum;

  const CollectionDetails1({
    super.key,
    required this.title,
    required this.date,
    required this.usernum,
  });

  @override
  State<CollectionDetails1> createState() => _CollectionDetails1State();
}

class _CollectionDetails1State extends State<CollectionDetails1> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  String? adminPhoneNumber; // Current user's phone number (admin)

  @override
  void initState() {
    super.initState();
    _getCurrentUserPhoneNumber(); // Fetch admin phone number (current user)
  }

  // Method to get the current authenticated user's phone number
  void _getCurrentUserPhoneNumber() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        adminPhoneNumber = user.email; // Set admin phone number
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 215, 206),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        title: Text(
          '${widget.title} Collection',
          style: GoogleFonts.nunito(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: adminPhoneNumber == null
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading while phone number is being fetched
          : _buildBody(), // Build the body with Firestore data
    );
  }

  // Method to build the body of the screen
  Widget _buildBody() {
    CollectionReference vehicleEntryRef = FirebaseFirestore.instance
        .collection('AllUsers')
        .doc(adminPhoneNumber)
        .collection('Users')
        .doc(widget.usernum)
        .collection('MoneyCollection')
        .doc(widget.date) // Document for the specific date
        .collection('vehicleEntry');

    return StreamBuilder<QuerySnapshot>(
      stream: vehicleEntryRef
          .where('entryType', isEqualTo: widget.title)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching data'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
         return Center(
                child: Lottie.asset('assets/animations/notfound2.json',
                    height: 300, width: 300));
        }

        // List of vehicle entries
        List<DocumentSnapshot> vehicleEntries = snapshot.data!.docs;

        return ListView.builder(
          itemCount: vehicleEntries.length,
          itemBuilder: (context, index) {
            var entry = vehicleEntries[index];
            return _buildEntryTile(entry);
          },
        );
      },
    );
  }

  // Method to build a single list tile for each entry
  Widget _buildEntryTile(DocumentSnapshot entry) {
    // Extract data from the entry document
    var entryTime = (entry['entryTime'] as Timestamp).toDate();
    var entryType = entry['entryType'];
    var selectedRate = entry['selectedRate'];
    var selectedTime = entry['selectedTime'];
    var vehicleNumber = entry['vehicleNumber'];

    // Format the date and time to include seconds
    String formattedDate =
        DateFormat('d MMM yyyy').format(entryTime); // e.g., 29 Sept 2024
    String formattedTime =
        DateFormat('h a').format(entryTime); // e.g., 10 AM or 10 PM

    String formattedDateTime =
        '$formattedDate, $formattedTime'; // e.g., 29 Sept 2024, 10 AM

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0), // Sharp edges
        side: BorderSide(color: Colors.black, width: 1), // Black border
      ),
      elevation: 0, // No shadow
      color: Colors.transparent, // Transparent background
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      color: Colors.black,
                      child: Text(
                        entryType,
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      color: Colors.black,
                      child: Text(
                        vehicleNumber,
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  icon: Icons.access_time,
                  text: 'Entry Time: $formattedDateTime',
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  icon: Icons.attach_money,
                  text: 'Selected Rate: $selectedRate',
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  icon: Icons.timer,
                  text: 'Selected Time: $selectedTime',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper method to build a row with an icon and text
  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: Colors.black),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
