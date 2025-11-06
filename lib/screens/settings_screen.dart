import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearPersonalizationData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear personalization data?'),
        content: const Text(
            'This will erase your location, mode preferences, and progress. Are you sure you want to proceed?'
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
          child: const Text('Clear Data'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );

    if (confirm == true) {
      await UserBoxHelper.clear();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personalization data cleared. Restart the app to begin fresh.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.tune, color: Colors.blueAccent, size:40),
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