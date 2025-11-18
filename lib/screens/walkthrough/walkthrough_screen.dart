import 'package:axeguide/utils/scrollable_scaffold.dart';
import 'package:axeguide/walkthrough/action_handlers.dart';
import 'package:flutter/material.dart';
import 'package:axeguide/walkthrough/walkthrough_manager.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  late WalkthroughManager manager;
  Map<String, dynamic>? step;
  bool showTips = false;

  @override
  void initState() {
    super.initState();

    manager = WalkthroughManager(
      actionHandler: (action, params) async {
        await WalkthroughActions.handle(context, action, params);
      },
    );
    manager.onStepChanged = (s) {
      setState(() => step = s);
    };

    manager.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (step == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ScrollableScaffold(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 12),

          _buildTipsButton(),
          if (showTips) _buildTipsBox(),
          const SizedBox(height: 20),

          _buildContent(),
          const Spacer(),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final text = step?['text'] ?? step?['question'] ?? "";
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTipsButton() {
    if (step?['tips'] is! Map) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => showTips = !showTips),
        icon: Icon(
          showTips ? Icons.lightbulb : Icons.lightbulb_outline,
          color: Colors.orange,
        ),
        label: Text(
          showTips ? "Hide tips" : "Show tips",
          style: const TextStyle(color: Colors.orange),
        ),
      ),
    );
  }

  Widget _buildTipsBox() {
    final tips = step?['tips']?['text'] ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade700),
      ),
      child: Text(
        tips,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildContent() {
  final type = step?['type'];
  final options = step?['options'];

  // If a conditional step ALSO has options → treat it like a question
  if (options != null && options is List && options.isNotEmpty) {
    return _buildOptions();
  }

  // Otherwise behave normally
  switch (type) {
    case "question":
      return _buildOptions();

    case "info":
      return Center(
        child: ElevatedButton(
          onPressed: () => manager.nextFromUI(null),
          child: const Text("Continue"),
        ),
      );

    case "action":
      return Center(
        child: ElevatedButton(
          onPressed: () => manager.nextFromUI(null),
          child: const Text("Continue"),
        ),
      );

    case "conditional":
      Future.microtask(() => manager.nextFromUI(null));
      return const Center(child: CircularProgressIndicator());

    default:
      return const SizedBox.shrink();
  }
}

  Widget _buildOptions() {
    final List options = step?['options'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final opt in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton(
              onPressed: () => manager.nextFromUI(opt['label']),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(opt['label']),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final type = step?['type'];
    return Row(
      children: [
        if (manager.currentStepId != "welcome")
          TextButton(
            onPressed: () => setState(() => manager.goBack()),
            child: const Text("Back"),
          ),
        const Spacer(),
        if (type != "question" && type != "conditional")
          ElevatedButton(
            onPressed: () => manager.nextFromUI(null),
            child: const Text("Continue"),
          ),
      ],
    );
  }
}