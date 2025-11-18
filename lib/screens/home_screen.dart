import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'settings_screen.dart';
import 'location_selection_screen.dart';
import 'package:axeguide/services/hive_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userLocation;
  bool loading = true;
  List<Map<String, dynamic>> locations = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
  await _loadUserData();
  
  // If no location is set, redirect to location selection
  if (userLocation == null) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LocationSelectionScreen(
            locations: LocationOption.mainLocations,
          ),
        ),
      );
    });
    return;
  }
  
  final loc = userLocation ?? '';
  final isStale = HiveService.isCacheStale(loc);
  final cached = HiveService.getCachedLocationsFor(loc);

  if (!isStale && cached != null && cached.isNotEmpty) {
    final safeList = cached
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    setState(() {
      locations = safeList;
      loading = false;
    });
    return;
  }

  await _loadLocations();
}


  Future<void> _loadUserData() async {
    final location = UserBoxHelper.userLocation;
    setState(() {
      userLocation = location; // Keep as null if not set
    });
  }

  String _getLocationGreeting() {
    if (userLocation == null) return 'Loading...';
    
    // Return friendly greeting based on location
    if (userLocation!.toLowerCase().contains('acadia')) {
      return 'Acadia University';
    } else if (userLocation!.toLowerCase().contains('airport')) {
      return 'Halifax Airport';
    } else if (userLocation!.toLowerCase().contains('wolfville')) {
      return 'Wolfville';
    } else if (userLocation!.toLowerCase().contains('new minas')) {
      return 'New Minas';
    } else if (userLocation!.toLowerCase().contains('kentville')) {
      return 'Kentville';
    } else if (userLocation!.toLowerCase().contains('halifax')) {
      return 'Halifax';
    }
    return userLocation!;
  }

  void _handleCacheFallback(String currentLoc, {required String cacheMessage, required String noDataMessage}) {
    final cached = HiveService.getCachedLocationsFor(currentLoc);
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        locations = List<Map<String, dynamic>>.from(cached);
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cacheMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(noDataMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadLocations() async {
    String normalizeLocation(String location) {
      final lower = location.toLowerCase();
      if (lower.contains('acadia')) return 'acadia';
      if (lower.contains('airport')) return 'halifax_airport';
      return lower;
    }
    final currentLoc = userLocation ?? '';
    final normalized = normalizeLocation(currentLoc);
    try {
      final response = await Supabase.instance.client
          .from('locations')
          .select(
            'name, description, town, hours, map_link, area_tag, latitude, longitude',
          )
          .ilike('area_tag', '%$normalized%')
          .limit(10);
      if (response.isNotEmpty) {
        await HiveService.saveLocations(response, currentLoc);
        setState(() {
          locations = List<Map<String, dynamic>>.from(response);
          loading = false;
      });
      return;
      }

      // Empty response - try cache or show error
      _handleCacheFallback(
        currentLoc,
        cacheMessage: 'Loaded locations from cache.',
        noDataMessage: 'No locations available at the moment.',
      );
    } catch (e) {
      // Network error - try cache or show error
      _handleCacheFallback(
        currentLoc,
        cacheMessage: 'Loaded locations from cache due to network error.',
        noDataMessage: 'Failed to load locations. Please check your connection.',
      );
    }
  }

  Future<void> _openMap(dynamic mapData) async {
    String? mapLink;
    double? lat;
    double? lng;

    if (mapData is Map<String, dynamic>) {
      lat = mapData['lat']?.toDouble();
      lng = mapData['lng']?.toDouble();
    } else if (mapData is String && mapData.isNotEmpty) {
      mapLink = mapData;
    }

    if (lat != null && lng != null) {
      final googleUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      final appleUri = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
      final geoUri = Uri.parse('geo:$lat,$lng');

      if (kIsWeb) {
        if (!await launchUrl(googleUri, mode: LaunchMode.externalApplication)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the map.'), duration: Duration(seconds: 2)),
          );
          return;
        }
      }

      try {
        if (await canLaunchUrl(geoUri)) {
          await launchUrl(geoUri, mode: LaunchMode.externalApplication);
          return;
        } else if (await canLaunchUrl(googleUri)) {
          await launchUrl(googleUri, mode: LaunchMode.externalApplication);
          return;
        } else if (await canLaunchUrl(appleUri)) {
          await launchUrl(appleUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        // Failed to launch map
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map.'), duration: Duration(seconds: 2)),
      );
      return;
    }

    if (mapLink != null) {
      final uri = Uri.tryParse(mapLink);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No valid map information available.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('The AxeGuide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF013A6E), Color(0xFF025A9E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF013A6E).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getLocationGreeting(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userLocation ?? 'Loading...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Explore section
              const Text(
                'Explore Nearby',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (loading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(
                      color: Color(0xFF013A6E),
                    ),
                  ),
                ),
              ] else if (locations.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.explore_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No locations available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for updates',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...locations.map((loc) {
                    final title = loc['name'] ?? 'Unknown';
                    final description = loc['description'] ?? 'No description available.';
                    final town = loc['town'] ?? 'Unknown town';
                    final hours = loc['hours'] ?? 'Hours not available';
                    final mapLink = loc['map_link'] ?? '';
                    final lat = loc['latitude'];
                    final lng = loc['longitude'];
                    final mapData = (lat != null && lng != null) ? {'lat': lat, 'lng': lng} : mapLink;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF013A6E).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.place,
                                    color: Color(0xFF013A6E),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A202C),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        town,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.amber.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    hours.isNotEmpty ? hours : 'Hours not available',
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openMap(mapData),
                                icon: const Icon(Icons.map_outlined, size: 20),
                                label: const Text('View on Map'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                }),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
