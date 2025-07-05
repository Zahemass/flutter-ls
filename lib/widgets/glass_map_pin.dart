import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassMapPin extends StatelessWidget {
  final String emoji;
  final String label;
  final double? distanceInKm;

  const GlassMapPin({
    Key? key,
    required this.emoji,
    required this.label,
    this.distanceInKm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showDistance = distanceInKm != null && distanceInKm! > 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 📏 Distance badge
        if (showDistance)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${distanceInKm!.toStringAsFixed(1)} km",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const SizedBox(height: 5),

        // 📍 Glassmorphic emoji circle
        GlassmorphicContainer(
          width: 50,
          height: 50,
          borderRadius: 25,
          blur: 20,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderGradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.white.withOpacity(0.1),
            ],
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),

        const SizedBox(height: 4),

        // 🏷️ Label
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
