
import 'package:aapkaparking/Admin%20side%20screens/Admin.dart';
import 'package:aapkaparking/User%20side%20screens/users.dart';
import 'package:aapkaparking/sliding%20screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFFD700), // Gold (Yellow) color
      ),
      home: SplashVideoScreen(), // Initial route set to SplashVideoScreen
    );
  }
}

class SplashVideoScreen extends StatefulWidget {
  @override
  _SplashVideoScreenState createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _textAnimationController;
  bool parkingenable = false;
  @override
  void initState() {
    super.initState();

    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 00),
    );

    _textAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () async {
        await _navigateToNextScreen();
      });
    });
  }

  Future<void> _navigateToNextScreen() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Get the user's phone number
      String? Email = user.email;
print(Email);
      if (Email != null) {
        // User is logged in, check if they are an admin or regular user
        final userType = await _getUserType(Email);
        if (userType == 'user') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const UserDash()),
          );
        } else if (userType == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminPage()),
          );
        }
      } else {
        // Handle case where phone number is null, though it shouldn't be in your use case
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SplashScreen()),
        );
      }
    } else {
      // No user is logged in, navigate to the sliding screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SplashScreen()),
      );
    }
  }

  Future<String> _getUserType(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('AllUsers').doc(uid);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      print('admin');
      return 'admin'; // UID found in 'AllUsers' collection, user is an admin
    } else {
        print('user');
      return 'user'; // UID not found, user is a regular user
    }
  }

  @override
  void dispose() {
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const  Color.fromARGB(255, 225, 215, 206),
      ),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            onEnd: () => setState(() {}),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 225, 215, 206),
                  Color.fromARGB(255, 225, 215, 206),
                  Color.fromARGB(255, 225, 215, 206),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(
                    flex: 2), // Moves the logo and heading above the center
                // Logo in a square box with animated border
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1),
                  height: 170,
                  width: 170,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.primaries[DateTime.now().millisecond %
                          Colors.primaries
                              .length], // Cycling through colors every millisecond
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(
                        12), // Square border with rounded edges
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/aapka logo.webp',
                      height: 150,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                const Spacer(
                    flex:
                        3), // Spacer to push the footer text towards the bottom
                // Footer with unique parking-related slogan
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Parking Simplified, Spaces Maximized',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 11, 11, 11)
                          .withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isAapkaAnimating() {
    return _textAnimationController.isAnimating;
  }
}
