import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'settings_screen.dart';
import 'package:axeguide/services/hive_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userLocation;
  String? userMode;
  bool loading = true;
  List<Map<String, dynamic>> locations = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserData();
    if (HiveService.isCacheStale()) {
      await _loadLocations();
    } else {
      final cached = HiveService.getCachedLocations();
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          locations = List<Map<String, dynamic>>.from(cached);
          loading = false;
        });
      } else {
        await _loadLocations();
      }
    }
  }

  Future<void> _loadUserData() async {
    final location = UserBoxHelper.userLocation;
    final mode = UserBoxHelper.userMode;
    setState(() {
      userLocation = location ?? 'Unknown';
      userMode = mode ?? 'Guest';
    });
  }

  Future<void> _loadLocations() async {
    String normalizeLocation(String location) {
      final lower = location.toLowerCase();
      if (lower.contains('acadia')) return 'acadia';
      if (lower.contains('airport')) return 'halifax_airport';
      return lower;
    }

    final normalized = normalizeLocation(userLocation ?? '');
    try {
      final response = await Supabase.instance.client
          .from('locations')
          .select(
            'name, description, town, hours, map_link, area_tag, latitude, longitude',
          )
          .ilike('area_tag', '%$normalized%')
          .limit(10);
      if (response.isNotEmpty) {
        await HiveService.saveLocations(response);
        setState(() {
        locations = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
      return;
      }

      final cached = HiveService.getCachedLocations();
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          locations = List<Map<String, dynamic>>.from(cached);
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loaded locations from cache.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No locations available at the moment.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Supabase fetch failed: $e');

      final cached = HiveService.getCachedLocations();
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          locations = List<Map<String, dynamic>>.from(cached);
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loaded locations from cache due to network error.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load locations. Please check your connection.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
        debugPrint('Error launching map: $e');
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
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('The AxeGuide Home'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 90, color: Color(0xFF013A6E)),
            const SizedBox(height: 24),
            Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 16),
            Text('Location: ${userLocation ?? "Loading..."}', style: const TextStyle(fontSize: 18)),
            Text('Mode: ${userMode ?? "Loading..."}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            const Divider(height: 40, thickness: 1),
            Text('Explore', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 16),
            if (loading) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Fetching data...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ] else if (locations.isEmpty) ...[
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: const Center(
                  child: Text(
                    'No locations available at the moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ] else ...[
              Column(
                children: locations.map((loc) {
                  final title = loc['name'] ?? 'Unknown';
                  final description = loc['description'] ?? 'No description available.';
                  final town = loc['town'] ?? 'Unknown town';
                  final hours = loc['hours'] ?? 'Hours not available';
                  final mapLink = loc['map_link'] ?? '';
                  final lat = loc['latitude'];
                  final lng = loc['longitude'];
                  final mapData = (lat != null && lng != null) ? {'lat': lat, 'lng': lng} : mapLink;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF013A6E))),
                          const SizedBox(height: 8),
                          Text(description, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(town, style: const TextStyle(color: Colors.grey)),
                              Text(hours.isNotEmpty ? 'Hours: $hours' : 'Hours not available', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _openMap(mapData),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('View on Map'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF013A6E), foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
