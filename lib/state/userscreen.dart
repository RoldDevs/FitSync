import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool isDarkMode = false; 
  XFile? _profileImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 50,
              left: 30,
              child: Container(
                width: 80,
                height: 80,
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
            ),
            Positioned(
              top: 50,
              right: 30,
              child: LiteRollingSwitch(
                value: isDarkMode,
                textOn: 'Dark',
                textOff: 'Light',
                colorOn: Colors.black,
                colorOff: Colors.yellow,
                iconOn: Icons.dark_mode,
                iconOff: Icons.light_mode,
                textOnColor: Colors.white,
                textOffColor: Colors.black,
                onChanged: (bool position) {
                  setState(() {
                    isDarkMode = position;
                  });
                },
                onTap: () {},
                onDoubleTap: () {},
                onSwipe: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
