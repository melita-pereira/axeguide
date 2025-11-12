import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:axeguide/utils/hive_boxes.dart';

class WalkthroughManager {
  final box = userBox;
  final cache = locationCache;
  late Map<String, dynamic> _steps = {};
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
        raw['id'] as String: Map<String, dynamic>.from(raw as Map<String, dynamic>)
      };
    _currentStepId = _steps.containsKey('welcome')
    ? 'welcome'
    : (_steps.isNotEmpty ? _steps.keys.first : null);
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
    _notifyStepChanged();
    userBox.put('walkthrough_checkpoint', _currentStepId);
  }

  void processConditionalStep(Map<String, dynamic> step) {
    final condition = step['condition'] as String?;
    if (condition == null){
      goToNextStep(step['nextStepId'], elseNextStepId: step['elseNextStepId']);
      return;
    }

    final result = evaluateCondition(condition);
    _currentStepId = result ? step['nextStepId']:step['elseNextStepId'];
    _notifyStepChanged();
    userBox.put('walkthrough_checkpoint', _currentStepId);
  }

  bool evaluateCondition(String condition) {

    final Map<String, bool Function()> conditionMap = {
      "hive.hasKey('walkthrough_checkpoint')": () =>
          userBox.containsKey('walkthrough_checkpoint'),

      "user.hasSelectedLocation": () =>
          userBox.containsKey('selectedLocation'),
    };

    // Exact match first
    if (conditionMap.containsKey(condition)) {
      return conditionMap[condition]!();
    }

    // Basic pattern handling
    if (condition.startsWith("user.selectedLocation ==")) {
      final match = RegExp(r"'(.*?)'").firstMatch(condition);
      final value = match?.group(1);
      return userBox.get('selectedLocation') == value;
    }

    return false;
  }

  void performAction(String actionName, [Map<String, dynamic>? params]){
    final actionMap = <String, void Function()> {
      "importHiveCheckpoint": () => importHiveCheckpoint(),
      "setNavigationPreference" : () => setNavigationPreference(params),
      "showSIMKioskInfo": () => showSIMKioskInfo(),
      "showImmigrationBaggageHelp": () => showImmigrationBaggageHelp(),
      "showShuttleGuidance": () => showShuttleGuidance(),
      "showFriendFamilyGuidance": () => showFriendFamilyGuidance(),
      "showBusGuidance": () => showBusGuidance(),
      "showTaxiGuidance": () => showTaxiGuidance(),
      "showAirportHelp": () => showAirportHelp(),
      "displayAirportHelpInfo": () => displayAirportHelpInfo(),
      "navigateToAirportHomeScreen": () => navigateToAirportHomeScreen(),
      "showShuttlePointers": () => showShuttlePointers(),
      "showFriendFamilyPointers": () => showFriendFamilyPointers(),
      "showBusPointers": () => showBusPointers(),
      "showTaxiPointers": () => showTaxiPointers(),
      "showCampusDirections": () => showCampusDirections(),
      "enterOffCampusAddress": () => enterOffCampusAddress(),
      "showSIMDirections": () => showSIMDirections(),
      "navigateToAcadiaHomeScreen": () => navigateToAcadiaHomeScreen(),
      "showWolfvilleEssentials": () => showWolfvilleEssentials(),
      "navigateToWolfvilleHomeScreen": () => navigateToWolfvilleHomeScreen(),
      "showNewMinasEssentials": () => showNewMinasEssentials(),
      "navigateToNewMinasHomeScreen": () => navigateToNewMinasHomeScreen(),
      "showKentvilleEssentials": () => showKentvilleEssentials(),
      "navigateToKentvilleHomeScreen": () => navigateToKentvilleHomeScreen(),
      "showHalifaxTransitGuide": () => showHalifaxTransitGuide(),
      "showHalifaxTaxiGuide": () => showHalifaxTaxiGuide(),
      "showHalifaxCarRentalGuide": () => showHalifaxCarRentalGuide(),
      "showHalifaxSIMLocations": () => showHalifaxSIMLocations(),
      "showHalifaxGroceriesPharmacy": () => showHalifaxGroceriesPharmacy(),
      "showHalifaxBankingOptions": () => showHalifaxBankingOptions(),
      "showHalifaxAttractions": () => showHalifaxAttractions(),
      "navigateToHalifaxHomeScreen": () => navigateToHalifaxHomeScreen(),
    };

    actionMap[actionName]?.call();
  }

  void next({String? selectedOptionId}){
    final step = currentStep;
    if (step == null) return;

    switch (step['type']) {
      case 'conditional':
      processConditionalStep(step);
      break;

      case 'action':
      performAction(step['action'], step['params']);
      goToNextStep(step['nextStepId']);
      break;

      case 'question':
      if (selectedOptionId != null){
        final options = step['options'] as List<dynamic>;
        final chosen = options.cast<Map<String,dynamic>>().firstWhere((opt)=> opt['label'] == selectedOptionId || opt['id'] == selectedOptionId, orElse: () => <String, dynamic>{});
        if (chosen.isNotEmpty) {
          if (chosen['action'] != null) performAction(chosen['action'], chosen['params']);
          goToNextStep(chosen['nextStepId'], elseNextStepId: chosen['elseNextStepId']);
        }
      }
      break;

      case 'info':
      final options = step['options'] as List<dynamic>?;
      if (options != null && options.isNotEmpty){
        goToNextStep(options.first['nextStepId']);
      } else {
        _currentStepId = null;
      }
      _notifyStepChanged();
      break;

      default:
      _currentStepId = null;
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
  
  void setNavigationPreference(Map<String, dynamic>? params) {}
  
  void showImmigrationBaggageHelp() {}
  
  void showShuttleGuidance() {}
  
  void showFriendFamilyGuidance() {}
  
  void showSIMKioskInfo() {}
  
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
