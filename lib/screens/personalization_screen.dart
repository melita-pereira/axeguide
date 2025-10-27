import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'home_screen.dart';

class personalization_screen extends StatefulWidget {
  const personalization_screen({super.key});

  @override
  State<personalization_screen> createState() => _personalization_screenState();
}

class _personalization_screenState extends State<personalization_screen> {
  String? selectedLocation;
  bool saving = false;

  final List<String> locations = [
    'Halifax Airport',
    'Acadia University',
    'Wolfville',
    'New Minas',
    'Kentville',
    'Halifax',
  ];

  Future<void> _saveLocation() async {
    if (selectedLocation == null) return;
    setState(() => saving = true);
    await UserBoxHelper.setUserLocation(selectedLocation);
    await UserBoxHelper.setHasProgress(true);
    await UserBoxHelper.setHasSeenWelcome(true);
    await UserBoxHelper.updateLastActive();
    // Save to Hive or any persistent storage here
    setState(() => saving = false);
    if (!mounted) return;
    // Navigate to the welcome screen after saving
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const home_screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Personalize Your Experience'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where are you starting from?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...locations.map((loc) {
              final isSelected = loc == selectedLocation;
              return GestureDetector(
                onTap: () => setState(() => selectedLocation = loc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF013A6E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    loc,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF013A6E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
