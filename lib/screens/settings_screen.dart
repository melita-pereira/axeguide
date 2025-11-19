import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'welcome_screen.dart';
import 'package:axeguide/utils/hive_boxes.dart';
import 'package:axeguide/screens/location_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

Future<void> _clearPersonalizationData(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reset AxeGuide?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This will erase all your data including your profile, walkthrough progress, and preferences. You\'ll start fresh from the welcome screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirm != true) return;

  bool resetSucceeded = false;
  
  try {
    // 1. Clear walkthrough progression
    await userBox.delete('walkthrough_checkpoint');

    // 2. Clear all personalization + progress keys
    await UserBoxHelper.clear();              // clears userBox entirely
    await locationCache.clear();              // clears cached location results

    // 3. Ensure app restarts onboarding
    await userBox.put('hasSeenWelcome', false);
    
    resetSucceeded = true;

  } catch (e) {
    // Reset failed - show error to user
    resetSucceeded = false;
  }

  if (!context.mounted) return;
  
  // Only navigate and show success if reset actually succeeded
  if (resetSucceeded) {
    // 4. Restart app at welcome
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );

    // 5. Feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('AxeGuide has been reset'),
            ],
          ),
          backgroundColor: const Color(0xFF013A6E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } else {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Failed to reset. Please try again or restart the app.'),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

  Future<void> _resetLocation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Reset Location?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will clear your selected location. You can choose a new one.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF013A6E),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserBoxHelper.setUserLocation(null);
      await UserBoxHelper.setCurrentCampusLocation(null);
      
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LocationSelectionScreen(
            locations: LocationOption.mainLocations,
          ),
        ),
      );
    }
  }

  Future<void> _resetAccessibility(BuildContext context) async {
    final navPref = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Guidance Preference',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'What type of guidance would you like?\n\n'
          '\u2022 In-depth: Detailed step-by-step instructions\n'
          '\u2022 Basic: Quick summaries and essentials',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'basic'),
            child: const Text('Basic'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'in-depth'),
            child: const Text('In-depth'),
          ),
        ],
      ),
    );

    if (navPref != null) {
      await UserBoxHelper.setNavPreference(navPref);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Guidance preference updated'),
            ],
          ),
          backgroundColor: const Color(0xFF013A6E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetWalkthrough(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Restart Walkthrough?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will restart the personalization walkthrough. Your saved location and preferences will be kept.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF013A6E),
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Only clear walkthrough-specific flags, keep user data
      await UserBoxHelper.clearWalkthroughCheckpoint();
      await UserBoxHelper.setSkippedPersonalization(false);
      await UserBoxHelper.setHasSeenWelcome(false);
      
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your preferences',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // User Info Section
              const Text(
                'Your Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: UserBoxHelper.userLocation ?? 'Not set',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: Icons.explore_outlined,
                      label: 'Navigation',
                      value: _capitalizeFirst(UserBoxHelper.navPreference ?? 'Not set'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Actions Section
              const Text(
                'Reset Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildResetOption(
                      context,
                      icon: Icons.location_off_outlined,
                      title: 'Reset Location',
                      description: 'Choose a different location',
                      color: const Color(0xFF013A6E),
                      onTap: () => _resetLocation(context),
                    ),
                    const Divider(height: 1),
                    _buildResetOption(
                      context,
                      icon: Icons.accessibility_new_outlined,
                      title: 'Change Guidance Preference',
                      description: 'Switch between in-depth and basic guides',
                      color: Colors.orange.shade700,
                      onTap: () => _resetAccessibility(context),
                    ),
                    const Divider(height: 1),
                    _buildResetOption(
                      context,
                      icon: Icons.replay_outlined,
                      title: 'Restart Walkthrough',
                      description: 'Start personalization from scratch',
                      color: Colors.purple.shade700,
                      onTap: () => _resetWalkthrough(context),
                    ),
                    const Divider(height: 1),
                    _buildResetOption(
                      context,
                      icon: Icons.delete_forever_outlined,
                      title: 'Reset Everything',
                      description: 'Clear all data and start fresh',
                      color: Colors.red.shade600,
                      onTap: () => _clearPersonalizationData(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF718096),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF013A6E),
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
