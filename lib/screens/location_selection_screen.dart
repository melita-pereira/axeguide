import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'dynamic_home_screen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(title ?? 'Select Your Location'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where are you?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF013A6E),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your location to get started',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
      UserBoxHelper.setUserLocation(location.value);
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

  const _LocationCard({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF013A6E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  location.icon,
                  size: 32,
                  color: const Color(0xFF013A6E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                location.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF013A6E),
                ),
              ),
              if (location.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  location.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
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
