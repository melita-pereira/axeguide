import 'package:axeguide/screens/personalization_loc_screen.dart';
import 'package:flutter/material.dart';

import 'package:axeguide/utils/hive_boxes.dart';
import 'package:axeguide/utils/user_box_helper.dart';

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
            onPressed: () {
              // Fire-and-forget the persistence, then navigate.
              Navigator.pop(dialogContext);
              UserBoxHelper.setHasSeenWelcome(true);
              if (!mounted) return;
              Navigator.pushReplacement(
                parentContext,
                MaterialPageRoute(
                  builder: (context) => const PersonalizationScreen(),
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
    if (!resume) {
      userBox.put('hasProgress', true);
      userBox.put('progressData', {});
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PersonalizationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF101820), const Color(0xFF1E2A38)]
                : [const Color(0xFFF9FAFB), const Color(0xFFE8EEF4)],
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
                    child: Image.asset('lib/assets/logo.png', height: 200),
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
                        _goToPersonalization(resume: false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: primaryColor.withOpacity(0.3),
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
                    onPressed: () => _goToPersonalization(resume: false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                    child: const Text(
                      'Skip Personalization',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await UserBoxHelper.clearCheckpoint();
                        await UserBoxHelper.setHasProgress(false);
                        // Also clear any stored progress data to avoid stale state.
                        await UserBoxHelper.setProgressData({});
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to reset progress: $e'),
                          ),
                        );
                        return;
                      }
                      if (!mounted) return;
                      setState(() {
                        hasProgress = false;
                      });
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Progress reset. You can start fresh now.',
                          ),
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
      ),
    );
  }
}
