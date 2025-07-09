import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassAppBar extends StatelessWidget {
  const GlassAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100, // Keep height same
      borderRadius: 10,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white38.withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: const LinearGradient(
        colors: [Colors.white24, Colors.white10],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 40), // 👈 Push content slightly downward
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.camera_alt, color: Colors.black),
            SizedBox(width: 5),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                      text: 'LOCAL ',
                      style: TextStyle(color: Colors.black)),
                  TextSpan(
                      text: 'LENS',
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
