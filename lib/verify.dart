import 'package:aapkaparking/Admin%20side%20screens/Admin.dart';

import 'package:aapkaparking/User%20side%20screens/users.dart';
import 'package:aapkaparking/forgetpassword.dart';

import 'package:aapkaparking/sign%20up.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class Loader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 180,
      color: Colors.yellow.shade700,
      child: const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 249, 251, 187),
          backgroundColor: Color.fromARGB(255, 0, 4, 57),
          strokeWidth: 4,
        ),
      ),
    );
  }
}

class Verify extends StatefulWidget {
  const Verify({Key? key}) : super(key: key);

  @override
  VerifyState createState() => VerifyState();
}

class VerifyState extends State<Verify> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isValidEmail = true;
  bool _isValidPassword = true;
  bool _isLoading = false;
  bool _isCompleted = false;
  bool _buttonEnable = false;
  bool clearEmail = false;
  bool clearPassword = false;
  bool _obscurePassword = true;
  void signInWithEmailPassword() async {
    setState(() {
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide email and password'),
            backgroundColor: Color.fromARGB(255, 10, 10, 10),
            duration: const Duration(milliseconds: 300)),
      );
      setState(() {
        _isLoading = false;
      });
      return; // Exit the method if validation fails
    }
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide email'),
            backgroundColor: Color.fromARGB(255, 10, 10, 10),
            duration: const Duration(milliseconds: 300)),
      );
      setState(() {
        _isLoading = false;
      });
      return; // Exit the method if validation fails
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide password'),
            backgroundColor: Color.fromARGB(255, 10, 10, 10),
            duration: const Duration(milliseconds: 300)),
      );
      setState(() {
        _isLoading = false;
      });
      return; // Exit the method if validation fails
    }
    try {
      // Attempt email and password sign-in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check Firestore to determine if the user is an admin or a regular user
      final adminDoc = await FirebaseFirestore.instance
          .collection('AllUsers')
          .doc(email)
          .get();

      setState(() {
        _isLoading = false;
      });

      if (adminDoc.exists) {
        // Check if the 'isDeleted' field is false before navigating to AdminPage
        if (adminDoc.data()!['isdeleted'] == false) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPage(), // Navigate to Admin page
            ),
          );
        } else {
          // Handle case where 'isDeleted' is true (could show a message or log out the user)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Admin access deniedd. Account is deleted.')),
          );
        }
      } else {
        // If not in AllUsers, check in LoginUsers
        final userDoc = await FirebaseFirestore.instance
            .collection('LoginUsers')
            .doc(email)
            .get();

        if (userDoc.exists) {
          // Check if the 'isDeleted' field is false before navigating to UserDash
          print('im in userdoc exist');
          if (userDoc.data()!['isDeleted'] == false) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const UserDash(), // Navigate to User page
              ),
            );
          } else {
            // Handle case where 'isDeleted' is true (could show a message or log out the user)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('User access denieddd. Account is deleted.')),
            );
          }
        } else {
          // Handle case where the user is not found in either collection
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User not found. Please contact support.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error occurred: $e');
      // Handle error (e.g., show a bottom sheet with the error message)
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(height: 8),
              Text(
                'Error occurred: Account not found. Please sign up first or change the password',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 247, 249, 229),
        appBar: AnimatedAppBar(title: 'Sign In'),
        body: SingleChildScrollView(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: SizedBox(
                  height: 400,
                  width: 400,
                  child: Container(
                    child: Lottie.asset(
                      'assets/animations/verify.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    const SizedBox(height: 330, child: Text("")),
                    const SizedBox(height: 0),
                    const Padding(
                      padding: EdgeInsets.only(left: 34.0),
                      child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text('Sign in with your email and password')),
                    ),
                    const SizedBox(height: 5),

                    // Email TextField
                    SizedBox(
                      width: 340,
                      height: 50,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(seconds: 1),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _isCompleted
                                        ? const Color.fromARGB(
                                            255, 206, 181, 136)
                                        : _isValidEmail
                                            ? const Color.fromARGB(
                                                255, 108, 95, 42)
                                            : Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: _isCompleted
                                      ? LinearGradient(
                                          colors: [
                                            Colors.yellow.shade100,
                                            Colors.yellow.shade300,
                                            Colors.yellow.shade400,
                                            Colors.yellow.shade600,
                                            Color.fromARGB(255, 241, 245, 23),
                                            Color.fromARGB(255, 254, 254, 1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 5, right: 25),
                                  child: TextField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.05, // Responsive font size
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.email,
                                          color: Colors.black),
                                      border: InputBorder.none,
                                      hintText: 'Enter email address',
                                      hintStyle: TextStyle(
                                        color: Colors.brown,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.045,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _isValidEmail = RegExp(
                                                r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+')
                                            .hasMatch(value);
                                        if (value.isNotEmpty) {
                                          clearEmail = true;
                                        }
                                        if (value.isEmpty) {
                                          _isValidEmail = true;
                                          _isCompleted = false;
                                          _isLoading = false;
                                          clearEmail = false;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 307.0, top: 10),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  emailController.clear();
                                  clearEmail = false;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: CircleAvatar(
                                  backgroundColor: clearEmail
                                      ? !_isValidEmail
                                          ? const Color.fromARGB(
                                              255, 248, 120, 133)
                                          : _isCompleted
                                              ? const Color.fromARGB(
                                                  255, 144, 249, 172)
                                              : const Color.fromARGB(
                                                  255, 69, 69, 69)
                                      : Colors.transparent,
                                  radius: 15,
                                  child: Icon(
                                    _isCompleted ? Icons.check : Icons.clear,
                                    color: clearEmail
                                        ? !_isValidEmail
                                            ? const Color.fromARGB(
                                                255, 250, 20, 4)
                                            : _isCompleted
                                                ? const Color.fromARGB(
                                                    255, 27, 130, 1)
                                                : const Color.fromARGB(
                                                    255, 207, 206, 206)
                                        : const Color.fromARGB(0, 255, 193, 7),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Password TextField
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 340,
                      height: 50,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(seconds: 1),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _isCompleted
                                        ? const Color.fromARGB(
                                            255, 206, 181, 136)
                                        : _isValidPassword
                                            ? const Color.fromARGB(
                                                255, 108, 95, 42)
                                            : Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: _isCompleted
                                      ? LinearGradient(
                                          colors: [
                                            Colors.yellow.shade100,
                                            Colors.yellow.shade300,
                                            Colors.yellow.shade400,
                                            Colors.yellow.shade600,
                                            Color.fromARGB(255, 241, 245, 23),
                                            Color.fromARGB(255, 254, 254, 1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 5, right: 25),
                                  child: TextField(
                                    controller: passwordController,
                                    obscureText:
                                        _obscurePassword, // Obscures text when _obscurePassword is true
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.05, // Responsive font size
                                    ),
                                    decoration: InputDecoration(
                                      // Prefix Icon (Lock icon)
                                      prefixIcon:
                                          Icon(Icons.lock, color: Colors.black),

                                      // Suffix Icon (Eye to toggle password visibility), visible only when user types
                                      suffixIcon: clearPassword
                                          ? IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                size: 26,
                                                color: Colors.black,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword; // Toggles the obscure state
                                                });
                                              },
                                            )
                                          : null, // If no password is typed, suffixIcon is null (hidden)

                                      // Password field hint text and styling
                                      hintText: 'Enter password',
                                      hintStyle: TextStyle(
                                        color: Colors.brown,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.045,
                                      ),

                                      // Remove the custom border to use default
                                      border:
                                          InputBorder.none, // No custom border
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _isValidPassword = value.length >= 6;
                                        clearPassword = value
                                            .isNotEmpty; // Controls visibility of eye icon
                                        if (value.isEmpty) {
                                          _isValidPassword = true;
                                          _isCompleted = false;
                                          _isLoading = false;
                                          clearPassword = false;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 307.0, top: 10),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  passwordController.clear();
                                  clearPassword = false;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: CircleAvatar(
                                  backgroundColor: clearPassword
                                      ? !_isValidPassword
                                          ? const Color.fromARGB(
                                              255, 248, 120, 133)
                                          : _isCompleted
                                              ? const Color.fromARGB(
                                                  255, 144, 249, 172)
                                              : const Color.fromARGB(
                                                  255, 69, 69, 69)
                                      : Colors.transparent,
                                  radius: 15,
                                  child: Icon(
                                    _isCompleted ? Icons.check : Icons.clear,
                                    color: clearPassword
                                        ? !_isValidPassword
                                            ? const Color.fromARGB(
                                                255, 250, 20, 4)
                                            : _isCompleted
                                                ? const Color.fromARGB(
                                                    255, 27, 130, 1)
                                                : const Color.fromARGB(
                                                    255, 207, 206, 206)
                                        : const Color.fromARGB(0, 255, 193, 7),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Stack(children: [
                        Center(
                          child: ElevatedButton(
                            onPressed: (_isValidEmail && _isValidPassword)
                                ? signInWithEmailPassword
                                : null,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                _isValidEmail && _isValidPassword
                                    ? Colors.yellow.shade700
                                    : Colors.grey.shade400,
                              ),
                              fixedSize: MaterialStateProperty.all<Size>(
                                  const Size(340, 47)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (_isLoading)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Loader(),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SignupScreen()), // Navigate to the SignupScreen
                        );
                      },
                      child: const Text(
                        'Don\'t have an account? Sign Up',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgetPassword()), // Navigate to the SignupScreen
                        );
                      },
                      child: const Text(
                        'forget Password?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const AnimatedAppBar({required this.title, Key? key}) : super(key: key);

  @override
  _AnimatedAppBarState createState() => _AnimatedAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AnimatedAppBarState extends State<AnimatedAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;
  late Animation<Color?> _colorAnimation3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:
            Color.fromARGB(243, 0, 0, 0), // Make the status bar transparent
        statusBarIconBrightness:
            Brightness.dark, // Dark icons for light backgrounds
        statusBarBrightness: Brightness.dark, // For iOS
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: const Color.fromARGB(255, 254, 232, 37),
      end: const Color.fromARGB(255, 138, 134, 16),
    ).animate(_controller);

    _colorAnimation2 = ColorTween(
      begin: const Color.fromARGB(255, 153, 138, 2),
      end: Colors.yellow.shade500,
    ).animate(_controller);

    _colorAnimation3 = ColorTween(
      begin: const Color.fromARGB(255, 247, 247, 104),
      end: Colors.yellowAccent,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Dark icons
          statusBarBrightness: Brightness.light, // For iOS
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _colorAnimation1.value!,
                      _colorAnimation2.value!,
                      _colorAnimation3.value!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: Color.fromARGB(255, 4, 4, 4),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            );
          },
        ));
  }
}

class AnimatedImage extends StatefulWidget {
  final String imageUrl;

  const AnimatedImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  _AnimatedImageState createState() => _AnimatedImageState();
}

class _AnimatedImageState extends State<AnimatedImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true); // Reverse animation for continuous loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: _animation.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 800,
            ),
          ),
        );
      },
    );
  }
}
