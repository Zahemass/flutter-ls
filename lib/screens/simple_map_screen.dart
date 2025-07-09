import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:sample_proj/components/app_bar.dart';
import 'package:sample_proj/components/category_chips.dart';
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/components/GlassDetailBottomSheet.dart';

class SimpleMapScreen extends StatefulWidget {
  const SimpleMapScreen({super.key});

  @override
  State<SimpleMapScreen> createState() => _SimpleMapScreenState();
}

class _SimpleMapScreenState extends State<SimpleMapScreen> {
  GoogleMapController? _googleMapController;
  LatLng? _liveLocation;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];

  int selectedCategoryIndex = 0;
  int _selectedIndex = 0;

  String? _selectedTitle;
  String? _selectedDescription;
  int? _selectedViews;
  LatLng? _selectedCoordinates;

  final List<String> categories = [
    "Food", "Fun", "History", "Hidden spots", "Art & Culture"
  ];

  final Map<String, List<Map<String, dynamic>>> categoryMarkers = {
    "Food": [
      {"name": "Burger Place 🍔", "lat": 13.0724, "lng": 80.2611, "description": "Tasty burgers", "views": 120},
      {"name": "Taco Spot 🌮", "lat": 13.0732, "lng": 80.2634, "description": "Spicy tacos", "views": 95},
      {"name": "Pizza Corner 🍕", "lat": 13.0717, "lng": 80.2592, "description": "Cheesy pizza", "views": 105},
    ],
    "Fun": [
      {"name": "Arcade 🎮", "lat": 13.0739, "lng": 80.2645, "description": "Retro arcade games", "views": 88},
      {"name": "Park 🎢", "lat": 13.0702, "lng": 80.2581, "description": "Relaxing park", "views": 140},
      {"name": "Bowling 🎳", "lat": 13.0751, "lng": 80.2607, "description": "Modern bowling alley", "views": 102},
    ],
    "History": [
      {"name": "Old Fort 🏰", "lat": 13.0720, "lng": 80.2650},
      {"name": "Museum 🖼️", "lat": 13.0735, "lng": 80.2575},
      {"name": "Historic Street 🛤️", "lat": 13.0705, "lng": 80.2620},
    ],
    "Hidden spots": [
      {"name": "Secret Cafe ☕", "lat": 13.0710, "lng": 80.2600},
      {"name": "Rooftop View 🌇", "lat": 13.0744, "lng": 80.2599},
      {"name": "Hidden Library 📚", "lat": 13.0728, "lng": 80.2630},
    ],
    "Art & Culture": [
      {"name": "Gallery 🎨", "lat": 13.0737, "lng": 80.2588},
      {"name": "Street Art 🖌️", "lat": 13.0708, "lng": 80.2641},
      {"name": "Cultural Hall 🎭", "lat": 13.0722, "lng": 80.2615},
    ]
  };

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await Geolocator.requestPermission();
    final position = await Geolocator.getCurrentPosition();
    final currentLoc = LatLng(position.latitude, position.longitude);
    setState(() => _liveLocation = currentLoc);
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) return;
    final url =
        "https://nominatim.openstreetmap.org/search?q=$input&format=json&limit=5&addressdetails=1";
    final response = await http.get(Uri.parse(url), headers: {
      "User-Agent": "FlutterMapApp"
    });
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() => _suggestions = List<Map<String, dynamic>>.from(data));
    }
  }

  Future<void> _onSuggestionTap(Map<String, dynamic> suggestion) async {
    final lat = double.parse(suggestion['lat']);
    final lon = double.parse(suggestion['lon']);
    final selected = LatLng(lat, lon);
    setState(() {
      _searchController.text = suggestion['display_name'];
      _suggestions = [];
    });
    _googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(selected, 15),
    );
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  Future<Set<Marker>> _buildMarkers() async {
    final selectedCategory = categories[selectedCategoryIndex];
    final markerData = categoryMarkers[selectedCategory] ?? [];

    final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(60, 60)),
      'assets/images/pin_1.png',
    );

    return markerData.map((place) {
      final lat = place['lat'] as double;
      final lng = place['lng'] as double;

      return Marker(
        markerId: MarkerId(place['name']),
        position: LatLng(lat, lng),
        icon: customIcon,
        onTap: () {
          setState(() {
            _selectedTitle = place['name'];
            _selectedDescription = place['description'] ?? 'No details available';
            _selectedViews = place['views'] ?? 0;
            _selectedCoordinates = LatLng(lat, lng);
          });
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_selectedTitle != null) {
            setState(() {
              _selectedTitle = null;
            });
          }
        },
        child: Stack(
          children: [
            if (_liveLocation == null)
              const Center(child: CircularProgressIndicator())
            else
              FutureBuilder<Set<Marker>>(
                future: _buildMarkers(),
                builder: (context, snapshot) {
                  final markers = snapshot.data ?? {};
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _liveLocation!,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) => _googleMapController = controller,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: {
                      Marker(
                        markerId: const MarkerId("live"),
                        position: _liveLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
                        infoWindow: const InfoWindow(title: "Your Location"),
                      ),
                      ...markers,
                    },
                  );
                },
              ),

            const GlassAppBar(),


            // ✅ BOTTOM Gradient overlay



            Positioned(
              top: 110,
              left: 15,
              right: 15,
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 55,
                borderRadius: 12,
                blur: 15,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white38.withOpacity(0.2)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white24.withOpacity(0.2),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.search, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _fetchSuggestions,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: "Search places...",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 175,
              left: 16,
              right: 0,
              child: CategoryChips(
                categories: categories,
                selectedIndex: selectedCategoryIndex,
                onSelected: (index) {
                  setState(() {
                    selectedCategoryIndex = index;
                    final selectedCategory = categories[index];
                    final newMarkers = categoryMarkers[selectedCategory];
                    if (newMarkers != null && newMarkers.isNotEmpty) {
                      final firstMarker = newMarkers.first;
                      _googleMapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(firstMarker['lat'], firstMarker['lng']),
                          15,
                        ),
                      );
                    }
                  });
                },
              ),
            ),

            if (_suggestions.isNotEmpty)
              Positioned(
                top: 230,
                left: 15,
                right: 15,
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: _suggestions.length * 55.0,
                  borderRadius: 12,
                  blur: 20,
                  alignment: Alignment.topCenter,
                  border: 1,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white38.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white24.withOpacity(0.2),
                    ],
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, color: Colors.black),
                        title: Text(
                          suggestion['display_name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black),
                        ),
                        onTap: () => _onSuggestionTap(suggestion),
                      );
                    },
                  ),
                ),
              ),

            if (_selectedTitle != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 95,
                child: GestureDetector(
                  onTap: () {}, // prevent tap propagation
                  child: GlassDetailBottomSheet(
                    title: _selectedTitle!,
                    description: _selectedDescription ?? '',
                    views: _selectedViews ?? 0,
                    onDirectionTap: () {
                      if (_selectedCoordinates != null) {
                        _openInGoogleMaps(
                          _selectedCoordinates!.latitude,
                          _selectedCoordinates!.longitude,
                        );
                      }
                    },
                    onPlayTap: () {
                      // TODO: Add play screen
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
