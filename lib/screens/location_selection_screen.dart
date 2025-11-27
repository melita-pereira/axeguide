import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'home/dynamic_home_screen.dart';

class LocationSelectionScreen extends StatelessWidget {
  final String? title;
  final List<LocationOption> locations;

  const LocationSelectionScreen({
    super.key,
    this.title,
    required this.locations,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF013A6E);
    final accentColor = const Color(0xFFC6FF00);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 10),
            Text(
              title ?? 'Select Your Location',
              style: const TextStyle(
                color: Color(0xFF013A6E),
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where are you?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF013A6E),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your location to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: locations.map((location) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 64) / 2,
                    child: _LocationCard(
                      location: location,
                      onTap: () => _handleLocationTap(context, location),
                      accentColor: accentColor,
                      primaryColor: primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLocationTap(BuildContext context, LocationOption location) {
    if (location.hasSubLocations) {
      // Navigate to sub-location selection
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationSelectionScreen(
            title: location.name,
            locations: location.subLocations!,
          ),
        ),
      );
    } else {
      // Save location and navigate to home
      // ...existing code...
      UserBoxHelper.setUserLocation(location.name);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DynamicHomeScreen()),
        (route) => false,
      );
    }
  }
}

class _LocationCard extends StatelessWidget {
  final LocationOption location;
  final VoidCallback onTap;
  final Color accentColor;
  final Color primaryColor;

  const _LocationCard({
    required this.location,
    required this.onTap,
    required this.accentColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: accentColor,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  location.icon,
                  size: 34,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                location.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              if (location.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  location.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LocationOption {
  final String name;
  final String value;
  final IconData icon;
  final String? description;
  final List<LocationOption>? subLocations;

  const LocationOption({
    required this.name,
    required this.value,
    required this.icon,
    this.description,
    this.subLocations,
  });

  bool get hasSubLocations => subLocations != null && subLocations!.isNotEmpty;

  // Predefined location options
  static final List<LocationOption> mainLocations = [
    LocationOption(
      name: 'Airport',
      value: 'Halifax Stanfield International Airport',
      icon: Icons.flight,
      description: 'Halifax Stanfield',
    ),
    LocationOption(
      name: 'Acadia University',
      value: 'Acadia University',
      icon: Icons.school,
      description: 'Wolfville Campus',
    ),
    LocationOption(
      name: 'Annapolis Valley',
      value: 'Annapolis Valley',
      icon: Icons.landscape,
      description: 'Select your town',
      subLocations: [
        LocationOption(
          name: 'New Minas',
          value: 'New Minas',
          icon: Icons.location_city,
        ),
        LocationOption(
          name: 'Wolfville',
          value: 'Wolfville',
          icon: Icons.location_city,
        ),
        LocationOption(
          name: 'Kentville',
          value: 'Kentville',
          icon: Icons.location_city,
        ),
      ],
    ),
    LocationOption(
      name: 'Halifax',
      value: 'Halifax',
      icon: Icons.location_city,
      description: 'Downtown & Metro',
    ),
  ];
}
