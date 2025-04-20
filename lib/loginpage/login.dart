import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_symbols_icons/symbols.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isButtonClicked = false;
  XFile? _profileImage;

  //Password visibility
  bool _obscureTextPassword = true;
  bool _obscureTextConfirmPassword = true;

  // Controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late final SupabaseClient supabase;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

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

  Future<void> _submitData() async {
    if (!_validateInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields correctly.")),
      );
      return;
    }

    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String contactNumber = _contactNumberController.text;

    try {
      // Firebase signup
      UserCredential firebaseUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //Send email verification::Firebase
      await firebaseUserCredential.user?.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification email sent. Please check your inbox.")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firebase signup failed: ${e.message}")),
      );
      return;
    }

    // Sign up user
    final _ = await supabase.auth.signUp(
      email: email,
      password: password,
        data: {
        'contact_number': contactNumber, // Store it in metadata
      },
    );

    // Upload image once here
    if (_profileImage != null) {
      await _uploadProfileImage(_profileImage!.path);
    }
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
                          opacity: _currentPage == 3 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "Sign in to your\nAccount!",
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
                          opacity: _currentPage == 3 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            "The body achieves\nwhat the mind believes.",
                            textAlign: TextAlign.end,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                       // Google Sign Up Button with Custom Image Icon
                       const SizedBox(height: 25),
                       GestureDetector(
                         // onTap: _signUpWithGoogle,
                         child: Container(
                           width: double.infinity, // Makes the button stretch across the width
                           padding: EdgeInsets.symmetric(vertical: 12),
                           decoration: BoxDecoration(
                             color: Colors.white, // White background for the button
                             borderRadius: BorderRadius.circular(30), // Rounded corners
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.grey.withOpacity(0.3),
                                 spreadRadius: 2,
                                 blurRadius: 5,
                                 offset: Offset(0, 3), // Changes position of shadow
                               ),
                             ],
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.center, // Centers the content horizontally
                             children: [
                               // Google Icon as Custom Image with custom size and padding
                               Image.asset(
                                 "assets/icons/google.png", // Path to your custom Google icon
                                 width: 20, // Width of the image
                                 height: 20, // Height of the image
                               ),
                               const SizedBox(width: 10), // Space between the image and text
                               Text(
                                 "Sign Up with Google", // Text on the button
                                 style: TextStyle(
                                   fontSize: 16,
                                   color: Colors.black, // Text color
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                       // Divider with text
                       const SizedBox(height: 25),
                       Padding(
                         padding: const EdgeInsets.symmetric(vertical: 20.0),
                         child: Row(
                           children: <Widget>[
                             Expanded(
                               child: Divider(
                                 thickness: 2,
                                 color: Colors.green, // Green divider color
                               ),
                             ),
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 8.0),
                               child: Text(
                                 "Or continue with",
                                 style: TextStyle(
                                   color: Colors.green,
                                   fontSize: 15), // Green text color
                               ),
                             ),
                             Expanded(
                               child: Divider(
                                 thickness: 2,
                                 color: Colors.green, // Green divider color
                               ),
                             ),
                           ],
                         ),
                       ),
                      ],
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
                            "Sign Up Now!",
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
                        // Image Picker
                        AnimatedOpacity(
                          opacity: _currentPage == 4 ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Align(
                            alignment: Alignment.centerRight, // Align the container to the right side
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Margin for left, right, top, bottom
                                padding: const EdgeInsets.all(20), // Padding inside the container
                                decoration: BoxDecoration(
                                  color: Colors.grey[900], // Grey background color
                                  borderRadius: BorderRadius.circular(12), // Optional: rounded corners for the box
                                ),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: double.infinity, // Make sure it stretches to the parent's width
                                    maxHeight: double.infinity, // Adjust height automatically based on content
                                  ),
                                  child: Center( // Center the circle inside the container
                                    child: Container(
                                      width: 120, // Fixed width for the image circle
                                      height: 120, // Fixed height for the image circle
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green,
                                        border: Border.all(color: Colors.white, width: 4),
                                        image: _profileImage != null
                                            ? DecorationImage(
                                                image: FileImage(File(_profileImage!.path)),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _profileImage == null
                                          ? Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 40,
                                            )
                                          : null,
                                    ),
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