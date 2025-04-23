import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fitsync/state/userscreen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  //PAGE CONTROLLER & PROFILE IMAGE
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isButtonClicked = false;
  XFile? _profileImage;

  //SIGN IN & SIGN UP
  bool _obscureTextSignInPassword = true;
  bool _obscureTextPassword = true;
  bool _obscureTextConfirmPassword = true;

  // Controllers for input fields :: Sign in
  final TextEditingController _emailControllerSignIn = TextEditingController();
  final TextEditingController _passwordControllerSignIn = TextEditingController();

  // Controllers for input fields :: Sign up
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  //SUPABASE CLIENT INITIALIZATION
  late final SupabaseClient supabase;

  @override
  void initState() 
  {
    super.initState();
    supabase = Supabase.instance.client;
  }

  @override
  void dispose() 
  {
    _pageController.dispose();
    super.dispose();
  }
  //SUPABASE CLIENT INITIALIZATION END

  //PAGE CONTROLLER 
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _goToNextPage() {
    setState(() {
      _isButtonClicked = true;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_currentPage < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
      setState(() {
        _isButtonClicked = false;
      });
    });
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }
  //PAGE CONTROLLER END

  //GOOGLE CLIENT INITIALIZATION TO::DO
  Future<UserCredential?> _SignInWithGoogle() async {
    return null;
  }
 
  //SIGN IN USER WITH FIREBASE AUTHENTICATION
  Future<void> _signInUser() async {
    final email = _emailControllerSignIn.text.trim();
    final password = _passwordControllerSignIn.text.trim(); // You had a typo here

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both email and password.")),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Navigate to userscreen.dart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found for that email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address.";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred.")),
      );
      print("Unexpected error: $e");
    }
  }
  //SIGN IN USER END

  //PICK IMAGE FROM GALLERY 
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }
  //PICK IMAGE FROM GALLERY END

  //UPLOAD IMAGE TO SUPABASE
  Future<void> _uploadProfileImage(String filePath) async {
    final file = File(filePath);
    try {
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await supabase.storage.from('profilepictures').upload(fileName, file);

      if (response.isNotEmpty) {
        setState(() {
          _profileImage = XFile(filePath);
        });
      } else {
        debugPrint("Upload failed: Empty response.");
      }
    } catch (e) {
      debugPrint("Upload failed: $e");
    }
  }
  //UPLOAD IMAGE TO SUPABASE END

  //VALIDATE INPUTS
  bool _validateInputs() {
    if (_emailController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      return false; // All fields must be filled
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      return false; // Passwords do not match
    }

    return true; // All validations passed
  }
  //VALIDATE INPUTS END


  //SIGN UP USER WITH FIREBASE AUTHENTICATION AND SUPABASE
  Future<void> _submitData() async {
    // Check if profile image is provided
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text("Please select a profile picture."),
            ],
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate text inputs
    if (!_validateInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text("Please fill all fields correctly."),
            ],
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    //Get input values
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String contactNumber = _contactNumberController.text;

    try {
      //FIREBASE SIGNUP
      UserCredential firebaseUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //SEND EMAIL VERIFICATION WITH FIREBASE
      await firebaseUserCredential.user?.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.mark_email_read_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text("Verification email sent. Please check your inbox."),
            ],
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text("Firebase signup failed: ${e.message}"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    //SIGN UP WITH SUPABASE
    final _ = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'contact_number': contactNumber,
      },
    );

    // Upload image
    await _uploadProfileImage(_profileImage!.path);
  }

  Widget buildBackgroundImage(String imagePath) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.black), // Placeholder
        ),
        Positioned.fill(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 600),
                  child: child,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              // Page 1
              Stack(
                children: [
                  buildBackgroundImage('assets/loginpage/weight.jpg'),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color.fromRGBO(0, 0, 0, 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedOpacity(
                          opacity: _currentPage == 0 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Welcome to FitSync!",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          opacity: _currentPage == 0 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Your smart fitness companion for everything.",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _goToNextPage,
                      child: AnimatedScale(
                        scale: _isButtonClicked ? 1.2 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.0),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Page 2
              Stack(
                children: [
                  buildBackgroundImage('assets/loginpage/gymgirl.jpg'),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color.fromRGBO(0, 0, 0, 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedOpacity(
                          opacity: _currentPage == 1 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Achieve Your Best Self!",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          opacity: _currentPage == 1 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Track. Train. Transform with smart precision.",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _goToNextPage,
                      child: AnimatedScale(
                        scale: _isButtonClicked ? 1.2 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.0),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Page 3
              Stack(
                children: [
                  buildBackgroundImage('assets/loginpage/gym.jpg'),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color.fromRGBO(0, 0, 0, 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedOpacity(
                          opacity: _currentPage == 2 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Fitness at Fingertips!",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          opacity: _currentPage == 2 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Personalized progress powered by smart app.",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _goToNextPage,
                      child: AnimatedScale(
                        scale: _isButtonClicked ? 1.2 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.0),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            // Page 4
            Stack(
              children: [
                buildBackgroundImage('assets/loginpage/girlblue.jpg'),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color.fromRGBO(0, 0, 0, 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _currentPage == 3 ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Sign in to your\nAccount!",
                            textAlign: TextAlign.end,
                            style: GoogleFonts.poppins(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "The body achieves\nWhat the mind believes.",
                            textAlign: TextAlign.end,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Email TextField
                          TextField(
                            controller: _emailControllerSignIn,
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                            cursorColor: Colors.grey,
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              prefixIcon: const Icon(
                                Symbols.person,
                                color: Colors.grey,
                                weight: 700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Password TextField
                          TextField(
                            controller: _passwordControllerSignIn,
                            obscureText: _obscureTextSignInPassword,
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                            cursorColor: Colors.grey,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              prefixIcon: const Icon(
                                Symbols.lock,
                                color: Colors.grey,
                                weight: 700,
                              ),
                              suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureTextSignInPassword ? Symbols.visibility : Symbols.visibility_off,
                                      color: Colors.grey,
                                      weight: 700,
                                    ), onPressed: () { 
                                      setState(() {
                                        _obscureTextSignInPassword = !_obscureTextSignInPassword;
                                      });
                               },
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Divider with "or continue with"
                          // Sign In Button
                          Center(
                            child: ElevatedButton(
                              onPressed: _signInUser, // Your sign-in logic function
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                backgroundColor: Colors.grey[900],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                              ),
                              child: Text(
                                "Sign In",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Divider(thickness: 2, color: Colors.white),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  "or continue with",
                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              ),
                              Expanded(
                                child: Divider(thickness: 2, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Social Buttons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                    _SignInWithGoogle(); // Add Google sign-in logic
                                }, // Add Google sign-in logic
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  margin: EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black,
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "assets/icons/google.png",
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {

                                }, // Add Facebook sign-in logic
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black,
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "assets/icons/facebook.png",
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _goToNextPage,
                      child: AnimatedScale(
                        scale: _isButtonClicked ? 1.2 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.0),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
              // Page 5
              Stack(
                children: [
                  Container(
                    color: Colors.black, // Background color
                  ),
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          opacity: _currentPage == 4 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Or Sign Up Now!",
                            textAlign: TextAlign.end,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          opacity: _currentPage == 4 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Get Stronger Every Day!",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        //Image Picker
                        AnimatedOpacity(
                          opacity: _currentPage == 4 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Center(
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Circle avatar: picked image OR default asset
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 4),
                                          image: DecorationImage(
                                            image: _profileImage != null
                                                ? FileImage(File(_profileImage!.path))
                                                : const AssetImage("assets/icons/avatar.png") as ImageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),

                                      // Icon overlays
                                      if (_profileImage != null) ...[
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Color.fromRGBO(0, 0, 0, 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.edit, color: Colors.white, size: 24),
                                      ] else ...[
                                        const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          opacity: _currentPage == 4 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            children: [
                              const SizedBox(height: 15),
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white, // Text color white to stand out on gray background
                                ),
                                cursorColor: Colors.grey, // Green cursor
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey, // Green label color
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900], // Dark gray background to match black background
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.black, // Gray border when not focused
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.black, // Gray border when enabled
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.black, // Green border when focused
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Symbols.person, // You can also try Symbols.alternate_email
                                    color: Colors.grey,
                                    weight: 700, // Optional: adjusts stroke thickness (100-700)
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscureTextPassword,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                cursorColor: Colors.green,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Symbols.key, // You can also try Symbols.alternate_email
                                    color: Colors.grey,
                                    weight: 700, // Optional: adjusts stroke thickness (100-700)
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureTextPassword ? Symbols.visibility : Symbols.visibility_off,
                                      color: Colors.grey,
                                      weight: 700,
                                    ), onPressed: () { 
                                      setState(() {
                                        _obscureTextPassword = !_obscureTextPassword;
                                      });
                                     },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureTextConfirmPassword,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                cursorColor: Colors.green,
                                decoration: InputDecoration(
                                  labelText: "Confirm Password",
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Symbols.security, // You can also try Symbols.alternate_email
                                    color: Colors.grey,
                                    weight: 700, // Optional: adjusts stroke thickness (100-700)
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureTextConfirmPassword ? Symbols.visibility : Symbols.visibility_off,
                                      color: Colors.grey,
                                      weight: 700,
                                    ), onPressed: () { 
                                      setState(() {
                                        _obscureTextConfirmPassword = !_obscureTextConfirmPassword;
                                      });
                                     },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              IntlPhoneField(
                                initialCountryCode: 'PH',
                                controller: _contactNumberController, 
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                cursorColor: Colors.white,
                                decoration: InputDecoration(
                                  labelText: "Cell No.",
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[900],
                                  counterStyle: TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                dropdownDecoration: const BoxDecoration(
                                  color: Color.fromRGBO(0, 0, 0, 0.0),
                                ),
                                dropdownTextStyle: const TextStyle(color: Colors.grey),
                                flagsButtonPadding: const EdgeInsets.only(left: 8, right: 8),
                                dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                pickerDialogStyle: PickerDialogStyle(
                                  backgroundColor: Colors.black,
                                  searchFieldCursorColor: Colors.green,
                                  searchFieldInputDecoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'Search Country',
                                    hintStyle: TextStyle(color: Colors.black),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.green),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.green),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.green),
                                    ),
                                  ),
                                  countryCodeStyle: TextStyle(fontSize: 16, color: Colors.green),
                                  countryNameStyle: TextStyle(fontSize: 16, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _submitData,
                      child: AnimatedScale(
                        scale: _isButtonClicked ? 1.2 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.0),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          // Back Button
          if (_currentPage > 0)
            Positioned(
              top: 40,
              left: 10,
              child: GestureDetector(
                onTap: _goToPreviousPage,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.0),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),

          // Page Indicator
          Positioned(
            bottom: 15,
            left: 15,
            child: Row(
              children: List.generate(
                5,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _currentPage == index ? 12 : 8,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.green
                        : Color.fromRGBO(255, 255, 255, 0.4),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      );
    }
}