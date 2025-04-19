import 'package:flutter/material.dart';
import 'package:fitsync/mainscreen/boxes.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FitSync',
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: screenWidth * 0.07,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMainContent(screenWidth, screenHeight),
          const Center(child: Text("Train Page", style: TextStyle(fontSize: 24))),
          const Center(child: Text("Thrive Page", style: TextStyle(fontSize: 24))),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green[400],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Train',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Thrive',
            
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.05),
              child: Text(
                "Discover your fitness goals",
                style: TextStyle(
                  fontFamily: GoogleFonts.cedarvilleCursive().fontFamily,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            buildBox(screenWidth, screenHeight, 'assets/frontpage/fooddiet.jpg', "Track"),
            SizedBox(height: screenHeight * 0.03),
            buildBox(screenWidth, screenHeight, 'assets/frontpage/pump.jpg', "Train"),
            SizedBox(height: screenHeight * 0.03),
            buildBox(screenWidth, screenHeight, 'assets/frontpage/community.jpg', "Thrive"),
          ],
        ),
      ),
    );
  }

  Widget buildBox(double screenWidth, double screenHeight, String imagePath, String label) {
    return Align(
      alignment: Alignment.topCenter,
      child: Boxes(
        width: screenWidth * 0.9,
        height: screenHeight * 0.20,
        imagePath: imagePath,
        opacity: 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {},
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
