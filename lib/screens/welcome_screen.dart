import 'package:axeguide/screens/location_screen.dart';
import 'package:flutter/material.dart';

import '../utils/hive_boxes.dart';

class welcome_screen extends StatefulWidget {
  const welcome_screen({super.key});

  @override
  State<welcome_screen> createState() => _welcome_screenState();
}

class _welcome_screenState extends State<welcome_screen>
    with SingleTickerProviderStateMixin {
  bool hasProgress = false;
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    hasProgress = userPreferences.get('hasProgress', defaultValue: false);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showContinueDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Continue Previous Progress?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You have existing progress saved. Would you like to continue where you left off or start fresh?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToLocations(resume: false);
            },
            child: const Text('Start New Journey'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToLocations(resume: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF013A6E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _goToLocations({bool resume = false}) {
    if (!resume) {
      userPreferences.put('hasProgress', true);
      userPreferences.put('progressData', {});
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const location_screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'lib/assets/logo.png',
                  height: 200,
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome to The AxeGuide',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discover locations, learn about local places, and personalize your journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () {
                    if (hasProgress) {
                      _showContinueDialog();
                    } else {
                      _goToLocations(resume: false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _goToLocations(resume: false),
                  child: const Text(
                    'Skip Personalization',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    await userPreferences.delete( 'hasProgress');
                    await userPreferences.delete('progressData');
                    setState(() {
                      hasProgress = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Progress reset. You can start fresh now.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Reset Progress',
                    style: TextStyle(fontSize: 15, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
