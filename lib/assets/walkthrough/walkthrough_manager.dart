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
    final String jsonString = await rootBundle.loadString(
      'lib/assets/data/walkthrough.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    final List<dynamic> rawSteps = jsonMap['walkthrough'] as List<dynamic>;
    _steps = {
      for (final raw in rawSteps) 
        (raw as Map<String, dynamic>)['id'] as String:
          Map<String, dynamic>.from(raw)
      };

    final checkpoint = box.get('walkthrough_checkpoint') as String?;
    _currentStepId = checkpoint ?? (_steps.containsKey('welcome') ? 'welcome' : (_steps.isNotEmpty ? _steps.keys.first : null));

    if (_currentStepId != null && !_steps.containsKey(_currentStepId)) {
      _currentStepId = _steps.containsKey('welcome') ? 'welcome' : (_steps.isNotEmpty ? _steps.keys.first : null);
    }

    _notifyStepChanged();
  }

  Map<String, dynamic>? get currentStep =>
      _currentStepId != null ? _steps[_currentStepId!] : null;

  void goToNextStep(String? nextStepId, {String? elseNextStepId}) {
    if (nextStepId != null) {
      _currentStepId = nextStepId;
    } else if (elseNextStepId != null) {
      _currentStepId = elseNextStepId;
    } else {
      _currentStepId = null;
    }
    _persistCheckpoint();
    _notifyStepChanged();
  }

  void goToStepId (String? id) {
    if (id == null || !_steps.containsKey(id)) return;
    _currentStepId = id;
    _persistCheckpoint();
    _notifyStepChanged();
  }

  void resetWalkthrough(){
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
    if (condition == null){
      goToNextStep(step['nextStepId'] as String?, elseNextStepId: step['elseNextStepId'] as String?);
      return;
    }

    final result = evaluateCondition(condition);
    final chosenNext = result ? (step['nextStepId'] as String?) : (step['elseNextStepId'] as String?);
    goToNextStep(chosenNext);
  }

  bool evaluateCondition(String condition) {
    final Map<String, bool Function()> conditionMap = {
      "hive.hasKey('walkthrough_checkpoint')": () =>
          box.containsKey('walkthrough_checkpoint'),

      "user.hasSelectedLocation": () =>
          box.containsKey('selectedLocation'),
    };

    // Exact match first
    if (conditionMap.containsKey(condition)) {
      return conditionMap[condition]!();
    }

    // Basic pattern handling
    final equalsMatch = RegExp(r"user\.selectedLocation\s*==\s*'(.*?)'").firstMatch(condition);
    if (equalsMatch != null) {
      final expected = equalsMatch.group(1);
      return box.get('selectedLocation') == expected;
    }

    final containsMatch = RegExp(r"\[\s*'([^']*)'(?:\s*,\s*'([^']*)')*\s*\].contains\(\s*user\.selectedLocation\s*\)").firstMatch(condition);
    if (containsMatch != null){
      final listMatch = RegExp(r"'(.*?)'").allMatches(condition).map((m) => m.group(1)).whereType<String>().toList();
      final userLoc = box.get('selectedLocation');
      return listMatch.contains(userLoc);
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

    actionMap[actionName]?.call(params);
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
      final chosen = options.firstWhere((opt)=> opt['label'] == selectedOptionLabel || opt['id'] == selectedOptionLabel, orElse: () => {});
      if ((chosen as Map).isEmpty) return;

      if (chosen.containsKey('action')){
        final actionName = chosen['action'] as String?;
        final params = chosen['params'] as Map<String, dynamic>?;
        performAction(actionName, params);
      }

      if (chosen.containsKey('condition')){
        final cond = chosen['condition'] as String?;
        if (cond != null){
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
