import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'welcome_screen.dart';

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
    await _loadLocations();
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
    // Simulate loading locations from a data source
    try {
      final response = await Supabase.instance.client
          .from('locations')
          .select('name, map_link')
          .limit(10);
      setState(() {
        locations = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint('Error loading locations: $e');
    }
  }

  Future<void> _resetApp() async {
    await UserBoxHelper.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User data cleared. Restart the app to begin fresh.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openMap(String mapLink) async {
    if (mapLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No map link available for this location.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(mapLink);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid map link.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the map link.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Home'), centerTitle: true),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 90,
                color: Color(0xFF013A6E),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Location: ${userLocation ?? "Loading..."}',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'Mode: ${userMode ?? "Loading..."}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              const Divider(height: 40, thickness: 1),
              Text(
                'Explore',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              if (loading) ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              ] else ...[
                Column(
                  children: locations.map((loc) {
                    final title = loc['name'] ?? 'Unknown';
                    final mapLink = loc['map_link'] ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          title, 
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.map_outlined, 
                        color: Color(0xFF013A6E)),
                          onTap: () => _openMap(mapLink),
                        ),
                      );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _resetApp,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
