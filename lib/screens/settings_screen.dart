import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'welcome_screen.dart';
import 'package:axeguide/utils/hive_boxes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

Future<void> _clearPersonalizationData(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset AxeGuide?'),
      content: const Text(
        'This will erase your walkthrough progress, location, navigation '
        'preferences, and cached data. You will restart the app like a new user.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Reset Everything'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    // 1. Clear walkthrough progression
    await userBox.delete('walkthrough_checkpoint');

    // 2. Clear all personalization + progress keys
    await UserBoxHelper.clear();              // clears userBox entirely
    await locationCache.clear();              // clears cached location results

    // 3. Ensure app restarts onboarding
    await userBox.put('hasSeenWelcome', false);

  } catch (e) {
    debugPrint("Reset failed: $e");
  }

  if (!context.mounted) return;

  // 4. Restart app at welcome
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    (route) => false,
  );

  // 5. Feedback
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('AxeGuide has been reset.'),
      duration: Duration(seconds: 2),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.tune, color: Colors.blueAccent, size: 40),
            title: Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Clear Personalization Data'),
            subtitle: const Text('Start the onboarding process again.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _clearPersonalizationData(context),
          ),
        ],
      ),
    );
  }
}
