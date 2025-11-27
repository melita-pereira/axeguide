import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:axeguide/utils/hive_boxes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef WTActionHandler = Future<void> Function(
  String actionName,
  Map<String, dynamic>? params,
);

class WalkthroughManager {
  final box = userBox;
  final cache = locationCache;

  final Map<String, dynamic> _steps = {};
  void Function(Map<String, dynamic> step)? onStepChanged;

  String? _currentStepId;

  final WTActionHandler actionHandler;
  final List<String> _history = [];

  WalkthroughManager({required this.actionHandler});

  Future<void> loadAll() async {
    final files = [
      'assets/walkthrough/core/intro.json',
      'assets/walkthrough/places/airport.json',
      'assets/walkthrough/places/acadia.json',
      'assets/walkthrough/places/valley.json',
      'assets/walkthrough/places/halifax.json',
    ];

    if (_currentStepId != null) {
      _saveCheckpoint();
    }

    for (final path in files) {
      await _loadAndMerge(path);
    }

    final cp = box.get('walkthrough_checkpoint') as String?;
    if (cp != null && _steps.containsKey(cp)) {
      _currentStepId = cp;
      // Load saved history
      final savedHistory = box.get('walkthrough_history');
      if (savedHistory is List) {
        _history.clear();
        _history.addAll(savedHistory.cast<String>());
      }
    } else if (_steps.containsKey('decide_welcome')) {
      _currentStepId = 'decide_welcome';
    } else if (_steps.isNotEmpty) {
      _currentStepId = _steps.keys.first;
    } else {
      _currentStepId = null;
    }

    _notify();
  }

  Future<void> _loadAndMerge(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        // Collect all step lists
        List stepsList = [];
        if (decoded.containsKey('steps')) {
          stepsList.addAll(decoded['steps']);
        }
        for (final section in decoded.values) {
          if (section is List) {
            stepsList.addAll(section);
          }
        }
        for (final s in stepsList) {
          _steps[s['id']] = s;
        }
      }
    } catch (e) {
      // ...existing code...
    }
  }

  Map<String, dynamic>? get currentStep =>
      (_currentStepId == null) ? null : _steps[_currentStepId];
  String? get currentStepId => _currentStepId;
  bool get canGoBack => _history.isNotEmpty;

  /// Get number of completed steps based on history
  int get completedSteps => _history.length;

  /// Get estimated total steps remaining by simulating forward navigation
  /// This is dynamic and updates based on user choices
  int get estimatedTotalSteps {
    // Count completed steps from history
    final completed = _history.length;
    
    // Estimate remaining steps by doing a shallow traversal from current step
    final remaining = _estimateRemainingSteps(_currentStepId, {});
    
    return completed + remaining;
  }

  int _estimateRemainingSteps(String? stepId, Set<String> visited) {
    if (stepId == null || !_steps.containsKey(stepId) || visited.contains(stepId)) {
      return 0;
    }

    visited.add(stepId);
    final step = _steps[stepId];
    final type = step?['type'] as String?;
    
    // Count this step if it's user-facing
    int count = (type == 'question' || type == 'info' || type == 'dropdown') ? 1 : 0;

    // Find next step(s)
    List<String?> nextSteps = [];
    
    switch (type) {
      case 'question':
        final options = step?['options'] as List?;
        if (options != null && options.isNotEmpty) {
          // For questions, take the average path (use first option as estimate)
          nextSteps.add(options[0]['nextStepId']);
        }
        break;
        
      case 'info':
        final options = step?['options'] as List?;
        if (options != null && options.isNotEmpty) {
          nextSteps.add(options[0]['nextStepId']);
        }
        break;
        
      case 'dropdown':
        nextSteps.add(step?['nextStepId']);
        break;
        
      case 'conditional':
        // Try to evaluate condition, or take both paths as worst case
        final cond = step?['condition'];
        if (cond != null) {
          try {
            final result = _eval(cond);
            if (result) {
              nextSteps.add(step?['nextStepId']);
            } else {
              nextSteps.add(step?['elseNextStepId']);
            }
          } catch (_) {
            // If can't evaluate, assume the path that exists
            nextSteps.add(step?['nextStepId']);
            nextSteps.add(step?['elseNextStepId']);
          }
        }
        break;
        
      case 'action':
        nextSteps.add(step?['nextStepId']);
        break;
    }

    // Recursively count remaining steps (take max of possible paths)
    int maxRemaining = 0;
    for (final next in nextSteps) {
      if (next != null) {
        final remaining = _estimateRemainingSteps(next, Set.from(visited));
        if (remaining > maxRemaining) {
          maxRemaining = remaining;
        }
      }
    }

    return count + maxRemaining;
  }

  /// Get progress as a percentage (0.0 to 1.0)
  double get progress {
    final total = estimatedTotalSteps;
    if (total == 0) return 0.0;
    return (completedSteps / total).clamp(0.0, 1.0);
  }

  
  void goTo(String? id, {bool addToHistory = true}) {
  if (id != null && _steps.containsKey(id)) {
    // ...existing code...
    if (_currentStepId != null && _currentStepId != id && addToHistory) {
      _history.add(_currentStepId!);
      // Save history to Hive
      box.put('walkthrough_history', _history);
    }
    _currentStepId = id;
    // ...existing code...
    _saveCheckpoint();
    _notify();
  } else {
    // ...existing code...
  }
}

  void goBack() {
  if (_history.isEmpty) return;

  final last = _history.removeLast();
  // Save updated history to Hive
  box.put('walkthrough_history', _history);
  if (_steps.containsKey(last)) {
    _currentStepId = last;
    _saveCheckpoint();
    _notify();
  }
}


  void nextFromUI(String? optionLabel) {
    final step = currentStep;
    if (step == null) return;

    switch (step['type']) {
      case 'info':
        _handleInfo(step);
        break;

      case 'action':
        _handleAction(step);
        break;

      case 'conditional':
        _handleConditional(step);
        break;

      case 'question':
        _handleQuestion(step, optionLabel);
        break;

      case 'dropdown':
        _handleDropdown(step, optionLabel);
        break;

      default:
        // Unknown step type
    }
  }

  void _handleInfo(Map<String, dynamic> step) {
    final opts = step['options'];
    if (opts != null && opts.isNotEmpty) {
      goTo(opts[0]['nextStepId']);
    }
  }

  void _handleAction(Map<String, dynamic> step) async {
    // ...existing code...
    await actionHandler(step['action'], step['params']);
    goTo(step['nextStepId'], addToHistory: false);
  }

  void _handleConditional(Map<String, dynamic> step) {
    final cond = _eval(step['condition']);
    final id = cond ? step['nextStepId'] : step['elseNextStepId'];
    
    // Don't add conditional steps to history since they auto-execute
    goTo(id, addToHistory: false);
  }

  void _handleDropdown(Map<String, dynamic> step, String? selectedValue) {
    if (selectedValue == null) return;
    
    // The value is already stored by the UI via setValue
    // Just navigate to the next step
    goTo(step['nextStepId']);
  }

  Future<void> _handleQuestion(
    Map<String, dynamic> step,
    String? chosenLabel,
  ) async {
    if (chosenLabel == null) return;

    final opts = (step['options'] as List).cast<Map<String, dynamic>>();
    final selected =
        opts.firstWhere((o) => o['label'] == chosenLabel, orElse: () => {});

    if (selected.isEmpty) return;

    if (selected.containsKey('set')) {
      await _applySet(selected['set']);
    }

    if (selected['action'] != null) {
      await actionHandler(selected['action'], selected['params']);
    }

    if (selected.containsKey('condition')) {
      final cond = _eval(selected['condition']);
      final id = cond ? selected['nextStepId'] : selected['elseNextStepId'];
      goTo(id);
      return;
    }

    goTo(selected['nextStepId']);
  }

  /// Maps walkthrough JSON field names to Hive storage keys
  String _mapFieldNameToHiveKey(String fieldName) {
    switch (fieldName) {
      case 'selectedLocation':
        return 'userLocation';
      case 'selectedResidence':
        return 'userResidence';
      case 'currentCampusLocation':
        return 'currentCampusLocation';
      case 'destinationLocation':
        return 'destinationLocation';
      case 'transportPref':
      case 'showSIM':
      case 'showGroceries':
      case 'showBanking':
      case 'hasSIM':
        return fieldName;
      default:
        return fieldName;
    }
  }

  Future<void> _applySet(Map<String, dynamic> map) async {
    for (final key in map.keys) {
      if (key.startsWith("user.")) {
        final fieldName = key.substring(5);
        final hiveKey = _mapFieldNameToHiveKey(fieldName);
        await box.put(hiveKey, map[key]);
      }
    }
  }

  bool _eval(String cond) {
    cond = cond.trim();

    if (cond.startsWith("has.")) {
      final key = cond.substring(4);
      return box.containsKey(key);
    }

    if (cond.startsWith("!has.")) {
      final key = cond.substring(5);
      return !box.containsKey(key);
    }

    if (cond.startsWith("eq.user.")) {
      final parts = cond.split(".");
      final fieldName = parts[2];
      final expected = parts.sublist(3).join(".");
      final hiveKey = _mapFieldNameToHiveKey(fieldName);
      return box.get(hiveKey) == expected;
    }

    if (cond.startsWith("in.user.")) {
      final afterPrefix = cond.substring(8); 
      final dotIndex = afterPrefix.indexOf(".");
      final fieldName = afterPrefix.substring(0, dotIndex);
      final hiveKey = _mapFieldNameToHiveKey(fieldName);

      final listStr =
          cond.substring(cond.indexOf("[") + 1, cond.indexOf("]"));
      final items = listStr.split(",").map((e) => e.trim()).toList();

      return items.contains(box.get(hiveKey));
    }

    final legacy =
        RegExp(r"\[(.*?)\]\.contains\(user\.([\w]+)\)").firstMatch(cond);
    if (legacy != null) {
      final list = legacy.group(1)!;
      final fieldName = legacy.group(2)!;
      final items = list.split(",").map((e) => e.replaceAll("'", "").trim()).toList();
      final hiveKey = _mapFieldNameToHiveKey(fieldName);
      final userValue = box.get(hiveKey);
      return items.contains(userValue);
    }

    // Unknown condition format
    return false;
  }

  void _saveCheckpoint() {
    if (_currentStepId == null) {
      box.delete('walkthrough_checkpoint');
    } else {
      box.put('walkthrough_checkpoint', _currentStepId);
    }
  }

  void reset() {
    _currentStepId = null;
    _history.clear();
    box.delete('walkthrough_checkpoint');
    box.delete('walkthrough_history');
  }

  void setValue(String key, dynamic value) {
    if (key.startsWith("user.")) {
      final fieldName = key.substring(5);
      final hiveKey = _mapFieldNameToHiveKey(fieldName);
      box.put(hiveKey, value);
    }
  }

  dynamic getValue(String key) {
    if (key.startsWith("user.")) {
      final fieldName = key.substring(5);
      final hiveKey = _mapFieldNameToHiveKey(fieldName);
      return box.get(hiveKey);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchDropdownData(Map<String, dynamic> config) async {
    final source = config['source'] as String?;
    
    if (source == 'supabase') {
      return await _fetchFromSupabase(config['query']);
    }
    
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchFromSupabase(Map<String, dynamic> query) async {
    try {
      final supabase = Supabase.instance.client;
      
      final table = query['table'] as String;
      final select = query['select'] as String;
      final categoryName = query['category_name'] as String?;
      final areaTagContains = query['area_tag_contains'] as String?;
      
      // If filtering by category, we need to join through location_categories
      if (categoryName != null) {
        // First, get the category ID
        final categoryResponse = await supabase
            .from('categories')
            .select('id')
            .eq('name', categoryName)
            .single();
        final categoryId = categoryResponse['id'] as int;
        
        // Get location IDs that have this category from the join table
        final locationCategoriesResponse = await supabase
            .from('location_categories')
            .select('location_id')
            .eq('category_id', categoryId);
        
        final locationIds = locationCategoriesResponse
            .map((item) => item['location_id'] as int)
            .toList();
        
        if (locationIds.isEmpty) {
          return [];
        }
        
        // Now query locations with these IDs
        var queryBuilder = supabase
            .from(table)
            .select(select)
            .inFilter('id', locationIds);
        
        if (areaTagContains != null) {
          queryBuilder = queryBuilder.ilike('area_tag', '%$areaTagContains%');
        }
        
        final response = await queryBuilder;
        return List<Map<String, dynamic>>.from(response);
      } else {
        // No category filter, just query locations directly
        var queryBuilder = supabase.from(table).select(select);
        
        if (areaTagContains != null) {
          queryBuilder = queryBuilder.ilike('area_tag', '%$areaTagContains%');
        }
        
        final response = await queryBuilder;
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      return [];
    }
  }

  void _notify() {
    if (onStepChanged != null && currentStep != null) {
      onStepChanged!(currentStep!);
    }
  }
}
