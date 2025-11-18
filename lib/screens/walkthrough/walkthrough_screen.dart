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
  List<Map<String, dynamic>> dropdownItems = [];
  String? selectedDropdownValue;
  bool loadingDropdown = false;
  String? lastLoadedDropdownStepId;

  @override
  void initState() {
    super.initState();

    manager = WalkthroughManager(
      actionHandler: (action, params) async {
        await WalkthroughActions.handle(context, action, params);
      },
    );
    manager.onStepChanged = (s) {
      setState(() {
        step = s;
        // Reset dropdown state when step changes
        dropdownItems = [];
        selectedDropdownValue = null;
        loadingDropdown = false;
      });
    };

    // Load walkthrough data including checkpoint and history
    _loadWalkthrough();
  }

  Future<void> _loadWalkthrough() async {
    await manager.loadAll();
    // Force rebuild after history is loaded
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (step == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF013A6E),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 16),
                    _buildTipsButton(),
                    if (showTips) _buildTipsBox(),
                    const SizedBox(height: 24),
                    _buildContent(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final text = step?['text'] ?? step?['question'] ?? "";
    return Text(
      text,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A202C),
        height: 1.3,
      ),
    );
  }

  Widget _buildTipsButton() {
    final tip = step?['tip'];
    if (tip == null || tip.toString().isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => showTips = !showTips),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  showTips ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  showTips ? "Hide tip" : "Show tip",
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  showTips ? Icons.expand_less : Icons.expand_more,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsBox() {
    final tips = step?['tip']?.toString() ?? "";
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.amber.shade100.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tips,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
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

    case "dropdown":
      return _buildDropdown();

    case "info":
      return Center(
        child: ElevatedButton(
          onPressed: () => manager.nextFromUI(null),
          child: const Text("Continue"),
        ),
      );

    case "action":
      // Auto-execute action steps immediately, don't show UI
      Future.microtask(() => manager.nextFromUI(null));
      return const Center(child: CircularProgressIndicator());

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
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: InkWell(
                onTap: () => manager.nextFromUI(opt['label']),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF013A6E).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt['label'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A202C),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF013A6E),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown() {
    final currentStepId = step?['id'] as String?;
    
    // Load dropdown data if we haven't loaded it for this step yet
    if (currentStepId != null && 
        currentStepId != lastLoadedDropdownStepId && 
        !loadingDropdown) {
      lastLoadedDropdownStepId = currentStepId;
      setState(() {
        loadingDropdown = true;
      });
      _loadDropdownData();
    }

    if (loadingDropdown) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            color: Color(0xFF013A6E),
          ),
        ),
      );
    }

    if (dropdownItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF013A6E).withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedDropdownValue,
              hint: const Text(
                'Select an option',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF013A6E),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A202C),
              ),
              items: dropdownItems.map((item) {
                final config = step?['dropdownConfig'] ?? {};
                final displayField = config['displayField'] ?? 'name';
                final valueField = config['valueField'] ?? 'id';
                
                return DropdownMenuItem<String>(
                  value: item[valueField]?.toString(),
                  child: Text(item[displayField]?.toString() ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDropdownValue = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (selectedDropdownValue != null)
          ElevatedButton(
            onPressed: () {
              // Validate if needed
              final config = step?['dropdownConfig'] ?? {};
              final validateDifferentFrom = config['validateDifferentFrom'] as String?;
              
              if (validateDifferentFrom != null) {
                // Get the value to compare against
                final compareValue = manager.getValue(validateDifferentFrom);
                if (compareValue == selectedDropdownValue) {
                  // Show validation message
                  final validationMessage = config['validationMessage'] as String? ?? 
                      "Please select a different option";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(validationMessage),
                      backgroundColor: Colors.amber.shade700,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
              }
              
              // Store the selected value
              final storeAs = config['storeAs'] as String?;
              if (storeAs != null) {
                manager.setValue(storeAs, selectedDropdownValue);
              }
              
              // Call nextFromUI which will trigger navigation
              manager.nextFromUI(selectedDropdownValue);
              
              // Reset dropdown state AFTER navigation is initiated
              // The onStepChanged callback will also reset these
              Future.microtask(() {
                setState(() {
                  dropdownItems = [];
                  selectedDropdownValue = null;
                  loadingDropdown = false;
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF013A6E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _loadDropdownData() async {
    final config = step?['dropdownConfig'];
    if (config == null) {
      setState(() {
        loadingDropdown = false;
      });
      return;
    }

    try {
      final items = await manager.fetchDropdownData(config);
      setState(() {
        dropdownItems = items;
        loadingDropdown = false;
      });
    } catch (e) {
      setState(() {
        loadingDropdown = false;
      });
    }
  }

  Widget _buildBottomButtons() {
    final type = step?['type'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (manager.canGoBack)
              TextButton.icon(
                onPressed: () => setState(() => manager.goBack()),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF013A6E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            const Spacer(),
            if (type == "info")
              ElevatedButton(
                onPressed: () => manager.nextFromUI(null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF013A6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}