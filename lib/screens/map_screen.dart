import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_place/google_place.dart';
import 'package:sample_proj/widgets/custom_bottom_nav.dart';
import 'package:sample_proj/widgets/glass_map_pin.dart';
import 'package:sample_proj/components/category_chips.dart';
import 'package:sample_proj/components/search_suggestion_overlay.dart';
import 'package:sample_proj/components/app_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng? _userLocation;
  int _selectedIndex = 0;
  int selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    "Food", "Fun", "History", "Hidden spots", "Art & Culture"
  ];

  final List<Map<String, dynamic>> customMarkers = [
    {
      'position': LatLng(13.0827, 80.2707),
      'category': 'Food',
      'emoji': '🍔',
      'label': 'Yummy Burger'
    },
    {
      'position': LatLng(13.0879, 80.2789),
      'category': 'Fun',
      'emoji': '🎡',
      'label': 'Amusement Park'
    },
    {
      'position': LatLng(13.0760, 80.2549),
      'category': 'History',
      'emoji': '🏛️',
      'label': 'Old Museum'
    },
  ];

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    googlePlace = GooglePlace("AIzaSyDR-x7ACgDfqQ9D1Oi38zBV_WCPCYoFCZ4");
    _searchController.addListener(() {
      autoCompleteSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double calculateDistance(LatLng start, LatLng end) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) *
            cos(end.latitude * p) *
            (1 - cos((end.longitude - start.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      final location = loc.Location();
      final current = await location.getLocation();
      setState(() {
        _userLocation = LatLng(current.latitude!, current.longitude!);
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_userLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 14),
      );
    }
  }

  void _recenterMap() {
    if (_userLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 14),
      );
    }
  }

  Future<void> _searchPlace(String placeName) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(placeName);
      if (locations.isNotEmpty) {
        final location = locations.first;
        LatLng newPosition = LatLng(location.latitude, location.longitude);
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 14.0),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Place not found")),
        );
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error searching location")),
      );
    }
  }

  void autoCompleteSearch(String value) async {
    if (value.isNotEmpty) {
      final result = await googlePlace.autocomplete.get(value);
      if (result != null && result.predictions != null) {
        setState(() => predictions = result.predictions!);
      }
    } else {
      setState(() => predictions = []);
    }
  }

  void _selectPlace(String placeId) async {
    final detail = await googlePlace.details.get(placeId);
    if (detail != null && detail.result != null) {
      final lat = detail.result!.geometry!.location!.lat;
      final lng = detail.result!.geometry!.location!.lng;
      if (lat != null && lng != null) {
        LatLng newPosition = LatLng(lat, lng);
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 14.0),
        );
        setState(() {
          _searchController.clear();
          predictions = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          /// 🌍 Google Map (no pins drawn here)
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? const LatLng(13.0827, 80.2707),
              zoom: 13.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              if (_userLocation != null)
                Marker(
                  markerId: const MarkerId("user"),
                  position: _userLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
                ),
            },
          ),

          /// 🧊 Custom Glass Pins
          ...customMarkers.where((marker) {
            return categories[selectedCategoryIndex] == marker['category'];
          }).map((marker) {
            final LatLng markerPos = marker['position'];
            double? distance;

            if (_userLocation != null) {
              distance = calculateDistance(_userLocation!, markerPos);
              if (distance < 3) return const SizedBox.shrink();
            }

            return FutureBuilder<ScreenCoordinate>(
              future: _mapController.getScreenCoordinate(markerPos),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final screen = snapshot.data!;
                return Positioned(
                  left: screen.x.toDouble() - 25,
                  top: screen.y.toDouble() - 80,
                  child: GlassMapPin(
                    emoji: marker['emoji'],
                    label: marker['label'],
                    distanceInKm: distance,
                  ),
                );
              },
            );
          }),

          /// 🔝 App Bar
          const GlassAppBar(),

          /// 🔍 Search Bar
          Positioned(
            top: 110,
            left: 16,
            right: 16,
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 50,
              borderRadius: 15,
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
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black87),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search places",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.black87),
                        onSubmitted: (value) async {
                          await _searchPlace(value);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.black87),
                      onPressed: () {},
                    )
                  ],
                ),
              ),
            ),
          ),

          /// 🔍 Suggestions
          SearchSuggestionsOverlay(
            searchController: _searchController,
            predictions: predictions,
            onSuggestionTap: _selectPlace,
            onUseLocationTap: () {
              _recenterMap();
              setState(() {
                _searchController.clear();
                predictions = [];
              });
            },
          ),

          /// 🔘 Category Chips
          Positioned(
            top: 170,
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

          /// 🎯 Recenter FAB
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: const Icon(Icons.my_location, color: Colors.blueAccent),
              onPressed: _recenterMap,
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
