import 'package:flutter/material.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'home_screen.dart';
import 'package:axeguide/assets/scrollable_scaffold.dart';

class PersonalizationNavScreen extends StatefulWidget {
  const PersonalizationNavScreen({super.key});

  @override
  State<PersonalizationNavScreen> createState() =>
      _PersonalizationNavScreenState();
}

class _PersonalizationNavScreenState extends State<PersonalizationNavScreen> {
  String? selectedMode;
  bool saving = false;

  Future<void> _savePreference() async {
    if (selectedMode == null) return;
    setState(() => saving = true);
    await UserBoxHelper.setNavPreference(selectedMode);
    await UserBoxHelper.updateLastActive();
    setState(() => saving = false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableScaffold(
      appBar: AppBar(
        title: const Text('Navigation Preference'),
        centerTitle: true,
      ),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How do you want your guidance?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildOption(
              title: 'In-depth Guidance',
              description: 'Step-by-step details, visuals, and explanations.',
              value: 'inDepth',
            ),
            _buildOption(
              title: 'Basic Guidance',
              description: 'Quick essentials and checkpoints only.',
              value: 'basic',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _savePreference,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF013A6E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Continue',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String description,
    required String value,
  }) {
    final selected = selectedMode == value;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF013A6E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: selected ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
