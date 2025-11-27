import 'package:axeguide/screens/walkthrough/walkthrough_screen.dart';
import 'package:axeguide/screens/location_selection_screen.dart';
import 'package:flutter/material.dart';

import 'package:axeguide/utils/hive_boxes.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:axeguide/utils/scrollable_scaffold.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool hasProgress = false;
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    hasProgress = userBox.get('hasProgress', defaultValue: false);
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
    final parentContext = context;
    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () async {
              // Fire-and-forget the persistence, then navigate.
              Navigator.pop(dialogContext);
              await UserBoxHelper.clear();
              await UserBoxHelper.setHasSeenWelcome(true);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                parentContext,
                MaterialPageRoute(
                  builder: (context) => const WalkthroughScreen(),
                ),
              );
            },
            child: const Text('Start New Journey'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToPersonalization(resume: true);
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

  Future<void> _goToPersonalization({bool resume = false}) async {
    await UserBoxHelper.setHasSeenWelcome(true);
    // User chose walkthrough, clear skip flag
    await UserBoxHelper.setSkippedPersonalization(false);
    if (!resume) {
      userBox.put('hasProgress', false);
      userBox.put('progressData', {});
      userBox.delete('walkthrough_checkpoint');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WalkthroughScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF013A6E);
    final accentColor = const Color(0xFFC6FF00);
    return ScrollableScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, const Color(0xFFE8EEF4)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.18),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/logo.png', height: 160),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Welcome to The AxeGuide',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Discover locations, learn about local places, and personalize your journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () {
                      if (hasProgress) {
                        _showContinueDialog();
                      } else {
                        _goToPersonalization(resume: false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: BorderSide(color: accentColor, width: 2),
                      ),
                      elevation: 7,
                      shadowColor: accentColor.withValues(alpha: 0.22),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 19,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () async {
                      await UserBoxHelper.setHasSeenWelcome(true);
                      await UserBoxHelper.setSkippedPersonalization(true);
                      await UserBoxHelper.clearWalkthroughCheckpoint();
                      await UserBoxHelper.setHasProgress(false);
                      await UserBoxHelper.setUserLocation(null);
                      await UserBoxHelper.setNavPreference('basic');
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationSelectionScreen(
                            locations: LocationOption.mainLocations,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward, color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        const Text('Skip Personalization'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
