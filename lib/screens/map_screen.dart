import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/components/category_chips.dart';
import 'package:sample_proj/components/app_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedIndex = 0;
  int selectedCategoryIndex = 0;

  final List<String> categories = [
    "Food", "Fun", "History", "Hidden spots", "Art & Culture"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 🔝 AppBar
          const GlassAppBar(),

          // 🔘 Category Chips
          Positioned(
            top: 50,
            left: 16,
            right: 0,
            child: CategoryChips(
              categories: categories,
              selectedIndex: selectedCategoryIndex,
              onSelected: (index) {
                setState(() {
                  selectedCategoryIndex = index;
                });
              },
            ),
          ),

          /// 🎯 Optional FAB (you can remove if not needed)
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: const Icon(Icons.my_location, color: Colors.blueAccent),
              onPressed: () {
                // Currently does nothing
              },
            ),
          ),
        ],
      ),

      /// ⬇️ Bottom Navigation
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
