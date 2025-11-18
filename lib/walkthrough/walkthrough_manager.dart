import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:axeguide/utils/hive_boxes.dart';

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
    } else if (_steps.containsKey('decide_welcome')) {
      _currentStepId = 'welcome';
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
        if (decoded.containsKey('steps')) {
          for (final s in decoded['steps']) {
            _steps[s['id']] = s;
          }
        }

        else {
          for (final section in decoded.values) {
            if (section is List) {
              for (final s in section) {
                _steps[s['id']] = s;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[Walkthrough] Failed to load $path → $e");
    }
  }

  Map<String, dynamic>? get currentStep =>
      (_currentStepId == null) ? null : _steps[_currentStepId];
  String? get currentStepId => _currentStepId;

  
  void goTo(String? id) {
  if (id != null && _steps.containsKey(id)) {
    if (_currentStepId != null && _currentStepId != id) {
      _history.add(_currentStepId!);
    }
    _currentStepId = id;
    _saveCheckpoint();
    _notify();
  }
}

  void goBack() {
  if (_history.isEmpty) return;

  final last = _history.removeLast();
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

      default:
        debugPrint("[Walkthrough] UNKNOWN STEP TYPE: ${step['type']}");
    }
  }

  void _handleInfo(Map<String, dynamic> step) {
    final opts = step['options'];
    if (opts != null && opts.isNotEmpty) {
      goTo(opts[0]['nextStepId']);
    }
  }

  void _handleAction(Map<String, dynamic> step) async {
    await actionHandler(step['action'], step['params']);
    goTo(step['nextStepId']);
  }

  void _handleConditional(Map<String, dynamic> step) {
    final cond = _eval(step['condition']);
    final id = cond ? step['nextStepId'] : step['elseNextStepId'];
    goTo(id);
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

  Future<void> _applySet(Map<String, dynamic> map) async {
    for (final key in map.keys) {
      if (key.startsWith("user.")) {
        final hiveKey = key.substring(5);
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
      final hiveKey = parts[2];
      final expected = parts.sublist(3).join(".");
      return box.get(hiveKey) == expected;
    }

    if (cond.startsWith("in.user.")) {
      final afterPrefix = cond.substring(8); 
      final dotIndex = afterPrefix.indexOf(".");
      final hiveKey = afterPrefix.substring(0, dotIndex);

      final listStr =
          cond.substring(cond.indexOf("[") + 1, cond.indexOf("]"));
      final items = listStr.split(",").map((e) => e.trim()).toList();

      return items.contains(box.get(hiveKey));
    }

    final legacy =
        RegExp(r"\[(.*?)\]\.contains\(user\.([\w]+)\)").firstMatch(cond);
    if (legacy != null) {
      final list = legacy.group(1)!;
      final key = legacy.group(2)!;
      final items = list.split(",").map((e) => e.replaceAll("'", "").trim());
      return items.contains(box.get(key));
    }

    debugPrint("⚠ [Walkthrough] UNKNOWN CONDITION: $cond");
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
    box.delete('walkthrough_checkpoint');
  }

  void _notify() {
    if (onStepChanged != null && currentStep != null) {
      onStepChanged!(currentStep!);
    }
  }
}
