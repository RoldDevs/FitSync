import 'package:fitsync/loginpage/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://jkirfownrjtaqydbxcgx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpraXJmb3ducmp0YXF5ZGJ4Y2d4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1Mzc3OTMsImV4cCI6MjA2MDExMzc5M30.X1yVFSpTmkv9hZyh28SfmB3nJYg6mubPg6-kJNqYiKU',
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
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.green,
            selectionColor: Color.fromARGB(150, 0, 255, 0), // optional highlight color
            selectionHandleColor: Colors.green,
        ),
      ),
      home: const Scaffold(
        body: Login(),
      ),
    );
  }
}