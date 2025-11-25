import 'package:flutter/material.dart';
import 'package:axeguide/services/hive_service.dart';

final ValueNotifier<String> userModeNotifier = ValueNotifier<String>(HiveService.userMode);