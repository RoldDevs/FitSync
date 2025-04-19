import 'package:flutter/material.dart';

class Boxes extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final String? imagePath;
  final double? opacity; 

  const Boxes({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.imagePath,
    this.opacity = 1.0, // Default to fully visible, adjust if needed
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        shadowColor: Colors.black45,
        child: ClipRRect( // Ensures rounded corners apply to the image
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath != null)
                Opacity(
                  opacity: opacity!,
                  child: Image.asset(
                    imagePath!,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
