import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'welcome_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userLocation;
  String? userMode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final location = UserBoxHelper.userLocation;
    final mode = UserBoxHelper.userMode;
    setState(() {
      userLocation = location ?? 'Unknown';
      userMode = mode ?? 'Guest';
    });
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
              // Navigate to settings screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }
}
