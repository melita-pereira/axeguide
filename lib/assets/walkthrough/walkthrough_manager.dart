import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

class WalkthroughManager {
  late Map<String, dynamic> _steps;
  String? _currentStepId;

  void Function(Map<String, dynamic> step)? onStepChanged;

  WalkthroughManager();

  Future<void> loadWalkthrough() async {
    final String jsonString = await rootBundle.loadString(
      'lib/assets/data/walkthrough.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _steps = {for (var step in jsonMap['walkthrough']) step['id']: step};
    _currentStepId = _steps.keys.first;
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
  }

  bool evaluateCondition(String condition){
    final Map<String, bool Function()> conditionMap ={
      "hive.has('walkthrough_checkpoint)": () =>
      Hive.box('userBox').containsKey(walkthrough_checkpoint),
    };
  }

  void performAction(String actionName, [Map<String, dynamic>? params]){
    final actionMap = <String, void Function()> {
      "importHiveCheckpoint": () => importHiveCheckpoint(),
      "showSIMKioskInfo": () => showSIMKioskInfo(params),
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
        final chosen = options.firstWhere((opt)=> opt['label'] == selectedOptionId, orElse: () => null);
        if (chosen != null) {
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

  void importHiveCheckpoint() {
    print("Importing Hive checkpoint...");
  }

  void showSIMKioskInfo([Map<String, dynamic>? params]){
    print("Showing SIM Kiosk info: $params");
  }
}
