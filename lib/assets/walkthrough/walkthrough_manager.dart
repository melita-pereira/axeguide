import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:axeguide/utils/hive_boxes.dart';

class WalkthroughManager {
  final box = userBox;
  final cache = locationCache;
  Map<String, dynamic> _steps = {};
  String? _currentStepId;

  void Function(Map<String, dynamic> step)? onStepChanged;

  WalkthroughManager();

  Future<void> loadWalkthrough() async {
    try {
      _steps = {};
      
      // Load all walkthrough JSON files
      final files = [
        'assets/walkthrough/core/intro.json',
        'assets/walkthrough/places/airport.json',
        'assets/walkthrough/places/acadia.json',
        'assets/walkthrough/places/valley.json',
        'assets/walkthrough/places/halifax.json',
      ];

      for (final file in files) {
        final String jsonString = await rootBundle.loadString(file);
        final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        
        // Handle both "steps" (intro.json) and location-specific keys
        List<dynamic> rawSteps = [];
        if (jsonMap.containsKey('steps')) {
          rawSteps = jsonMap['steps'] as List<dynamic>;
        } else {
          // For files like airport.json with "halifax_airport" key
          final firstKey = jsonMap.keys.first;
          rawSteps = jsonMap[firstKey] as List<dynamic>;
        }

        // Merge steps into the main dictionary
        for (final raw in rawSteps) {
          final step = raw as Map<String, dynamic>;
          final id = step['id'] as String;
          _steps[id] = Map<String, dynamic>.from(step);
        }
      }

      final checkpoint = box.get('walkthrough_checkpoint') as String?;
      _currentStepId = checkpoint ?? (_steps.containsKey('decide_welcome') ? 'decide_welcome' : (_steps.isNotEmpty ? _steps.keys.first : null));

      if (_currentStepId != null && !_steps.containsKey(_currentStepId)) {
        _currentStepId = _steps.containsKey('decide_welcome') ? 'decide_welcome' : (_steps.isNotEmpty ? _steps.keys.first : null);
      }

      _notifyStepChanged();
    } catch (e) {
      // Handle error appropriately (log, show error to user, use defaults, etc.)
      _steps = {};
      _currentStepId = null;
    }
  }

  Map<String, dynamic>? get currentStep =>
      _currentStepId != null ? _steps[_currentStepId!] : null;

  void goToNextStep(String? nextStepId, {String? elseNextStepId}) {
    if (nextStepId != null && _steps.containsKey(nextStepId)) {
      _currentStepId = nextStepId;
    } else if (elseNextStepId != null && _steps.containsKey(elseNextStepId)) {
      _currentStepId = elseNextStepId;
    } else {
      _currentStepId = null;
    }
    _persistCheckpoint();
    _notifyStepChanged();
  }

  void goToStepId(String? id) {
    if (id == null || !_steps.containsKey(id)) return;
    _currentStepId = id;
    _persistCheckpoint();
    _notifyStepChanged();
  }

  void resetWalkthrough() {
    _currentStepId = null;
    box.delete('walkthrough_checkpoint');
    _notifyStepChanged();
  }

  void _persistCheckpoint() {
    if (_currentStepId == null) {
      box.delete('walkthrough_checkpoint');
    } else {
      box.put('walkthrough_checkpoint', _currentStepId);
    }
  }

  void processConditionalStep(Map<String, dynamic> step) {
    final condition = step['condition'] as String?;
    if (condition == null) {
      goToNextStep(step['nextStepId'] as String?, elseNextStepId: step['elseNextStepId'] as String?);
      return;
    }

    final result = evaluateCondition(condition);
    final chosenNext = result ? (step['nextStepId'] as String?) : (step['elseNextStepId'] as String?);
    goToNextStep(chosenNext);
  }

  bool evaluateCondition(String condition) {
    // New format handlers
    // has.key_name -> checks if Hive has the key
    if (condition.startsWith('has.')) {
      final key = condition.substring(4);
      return box.containsKey(key);
    }

    // !has.key_name -> checks if Hive does NOT have the key
    if (condition.startsWith('!has.')) {
      final key = condition.substring(5);
      return !box.containsKey(key);
    }

    // eq.key.value -> checks if box[key] == value
    if (condition.startsWith('eq.')) {
      final parts = condition.substring(3).split('.');
      if (parts.length >= 2) {
        final key = parts[0];
        final value = parts.sublist(1).join('.'); // Handle values with dots
        return box.get(key) == value;
      }
    }

    // in.key.[val1,val2,val3] -> checks if box[key] is in the list
    final inMatch = RegExp(r'^in\.([^.]+)\.\[([^\]]+)\]$').firstMatch(condition);
    if (inMatch != null) {
      final key = inMatch.group(1)!;
      final valuesStr = inMatch.group(2)!;
      final values = valuesStr.split(',').map((s) => s.trim()).toList();
      final userValue = box.get(key);
      return values.contains(userValue);
    }

    // Legacy format handlers for backward compatibility
    final Map<String, bool Function()> conditionMap = {
      "hive.hasKey('walkthrough_checkpoint')": () =>
          box.containsKey('walkthrough_checkpoint'),
      "user.hasSelectedLocation": () =>
          box.containsKey('selectedLocation'),
    };

    if (conditionMap.containsKey(condition)) {
      return conditionMap[condition]!();
    }

    final equalsMatch = RegExp(r"user\.selectedLocation\s*==\s*'([^']+)'").firstMatch(condition);
    if (equalsMatch != null) {
      final expected = equalsMatch.group(1);
      return box.get('selectedLocation') == expected;
    }

    final listContainsMatch = RegExp(r"\[(.*?)\]\.contains\(\s*user\.selectedLocation\s*\)").firstMatch(condition);
    if (listContainsMatch != null) {
      final listContent = listContainsMatch.group(1)!;
      final items = listContent
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.startsWith("'") && s.endsWith("'"))
          .map((s) => s.substring(1, s.length - 1))
          .toList();
      final userLoc = box.get('selectedLocation');
      return items.contains(userLoc);
    }

    return false;
  }

  void performAction(String? actionName, [Map<String, dynamic>? params]){
    if (actionName == null) return;
    final Map<String, void Function(Map<String, dynamic>? params)> actionMap = {
      "importHiveCheckpoint": (_) => importHiveCheckpoint(),
      "setNavigationPreference" : (p) => setNavigationPreference(p),
      "showSIMKioskInfo": (p) => showSIMKioskInfo(p),
      "showImmigrationBaggageHelp": (_) => showImmigrationBaggageHelp(),
      "showShuttleGuidance": (_) => showShuttleGuidance(),
      "showFriendFamilyGuidance": (_) => showFriendFamilyGuidance(),
      "showBusGuidance": (_) => showBusGuidance(),
      "showTaxiGuidance": (_) => showTaxiGuidance(),
      "showAirportHelp": (_) => showAirportHelp(),
      "displayAirportHelpInfo": (_) => displayAirportHelpInfo(),
      "navigateToAirportHomeScreen": (_) => navigateToAirportHomeScreen(),
      "showShuttlePointers": (_) => showShuttlePointers(),
      "showFriendFamilyPointers": (_) => showFriendFamilyPointers(),
      "showBusPointers": (_) => showBusPointers(),
      "showTaxiPointers": (_) => showTaxiPointers(),
      "showCampusDirections": (_) => showCampusDirections(),
      "enterOffCampusAddress": (_) => enterOffCampusAddress(),
      "showSIMDirections": (_) => showSIMDirections(),
      "navigateToAcadiaHomeScreen": (_) => navigateToAcadiaHomeScreen(),
      "showWolfvilleEssentials": (_) => showWolfvilleEssentials(),
      "navigateToWolfvilleHomeScreen": (_) => navigateToWolfvilleHomeScreen(),
      "showNewMinasEssentials": (_) => showNewMinasEssentials(),
      "navigateToNewMinasHomeScreen": (_) => navigateToNewMinasHomeScreen(),
      "showKentvilleEssentials": (_) => showKentvilleEssentials(),
      "navigateToKentvilleHomeScreen": (_) => navigateToKentvilleHomeScreen(),
      "showHalifaxTransitGuide": (_) => showHalifaxTransitGuide(),
      "showHalifaxTaxiGuide": (_) => showHalifaxTaxiGuide(),
      "showHalifaxCarRentalGuide": (_) => showHalifaxCarRentalGuide(),
      "showHalifaxSIMLocations": (_) => showHalifaxSIMLocations(),
      "showHalifaxGroceriesPharmacy": (_) => showHalifaxGroceriesPharmacy(),
      "showHalifaxBankingOptions": (_) => showHalifaxBankingOptions(),
      "showHalifaxAttractions": (_) => showHalifaxAttractions(),
      "navigateToHalifaxHomeScreen": (_) => navigateToHalifaxHomeScreen(),
    };

    // Parse actionName if it contains parameters, e.g. setNavigationPreference('in-depth')
    String extractedActionName = actionName;
    Map<String, dynamic>? extractedParams = params;
    final regExp = RegExp(r"^(\w+)\((.*)\)$");
    final match = regExp.firstMatch(actionName);
    if (match != null) {
      extractedActionName = match.group(1)!;
      String paramString = match.group(2)!.trim();
      // Only handle single string literal parameter for now
      if (paramString.isNotEmpty) {
        // Remove surrounding quotes if present
        if ((paramString.startsWith("'") && paramString.endsWith("'")) ||
            (paramString.startsWith('"') && paramString.endsWith('"'))) {
          paramString = paramString.substring(1, paramString.length - 1);
        }
        extractedParams = {"value": paramString};
      }
    }

    actionMap[extractedActionName]?.call(extractedParams);
  }

  void next({String? selectedOptionLabel}){
    final step = currentStep;
    if (step == null) return;

    final type = step['type'] as String? ?? '';

    switch (type) {
      case 'conditional':
        processConditionalStep(step);
        break;

      case 'action':
        performAction(step['action'] as String?, (step['params'] as Map<String, dynamic>?));
        goToNextStep(step['nextStepId'] as String?);
        break;

      case 'question':
        if (selectedOptionLabel == null) return;
        final options = (step['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        final chosen = options.firstWhere(
          (opt) => opt['label'] == selectedOptionLabel || opt['id'] == selectedOptionLabel,
          orElse: () => <String, dynamic>{}
        );
        if (chosen.isEmpty) return;

        // Handle "set" property - store values in Hive
        if (chosen.containsKey('set')) {
          final setMap = chosen['set'] as Map<String, dynamic>;
          for (final entry in setMap.entries) {
            box.put(entry.key, entry.value);
          }
        }

        // Handle action
        final actionName = chosen['action'] as String?;
        if (actionName != null) {
          final params = chosen['params'] as Map<String, dynamic>?;
          performAction(actionName, params);
        }

        // Handle conditional routing
        if (chosen.containsKey('condition')){
          final cond = chosen['condition'] as String?;
          if (cond != null) {
            final condResult = evaluateCondition(cond);
            final nextIfTrue = condResult ? (chosen['nextStepId'] as String?) : (chosen['elseNextStepId'] as String?);
            goToNextStep(nextIfTrue);
            return;
          }
        }

        goToNextStep(chosen['nextStepId'] as String?, elseNextStepId: chosen['elseNextStepId'] as String?);
        break;

      case 'info':
        final options = (step['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
        if (options != null && options.isNotEmpty) {
          goToNextStep(options.first['nextStepId'] as String?);
        } else {
          _currentStepId = null;
          _persistCheckpoint();
          _notifyStepChanged();
        }
        break;

      default:
        _currentStepId = null;
        _persistCheckpoint();
        _notifyStepChanged();
    }
  }

  void _notifyStepChanged() {
    final step = currentStep;
    if (onStepChanged != null && step != null) {
      onStepChanged!(step);
    }
  }

  void importHiveCheckpoint() {}
  
  void setNavigationPreference(Map<String, dynamic>? p) {}
  
  void showImmigrationBaggageHelp() {}
  
  void showShuttleGuidance() {}
  
  void showFriendFamilyGuidance() {}
  
  void showSIMKioskInfo(Map<String, dynamic>? p) {}
  
  void showBusGuidance() {}
  
  void showTaxiGuidance() {}
  
  void showAirportHelp() {}
  
  void displayAirportHelpInfo() {}
  
  void navigateToAirportHomeScreen() {}
  
  void showShuttlePointers() {}
  
  void showFriendFamilyPointers() {}
  
  void showBusPointers() {}
  
  void showTaxiPointers() {}
  
  void showCampusDirections() {}
  
  void enterOffCampusAddress() {}
  
  void showSIMDirections() {}
  
  void navigateToAcadiaHomeScreen() {}
  
  void showWolfvilleEssentials() {}
  
  void navigateToWolfvilleHomeScreen() {}
  
  void showNewMinasEssentials() {}
  
  void navigateToNewMinasHomeScreen() {}
  
  void showKentvilleEssentials() {}
  
  void navigateToKentvilleHomeScreen() {}
  
  void showHalifaxTransitGuide() {}
  
  void showHalifaxTaxiGuide() {}
  
  void showHalifaxCarRentalGuide() {}
  
  void showHalifaxSIMLocations() {}
  
  void showHalifaxGroceriesPharmacy() {}
  
  void showHalifaxBankingOptions() {}
  
  void showHalifaxAttractions() {}
  
  void navigateToHalifaxHomeScreen() {}
}
