import 'package:axeguide/utils/hive_boxes.dart';

class UserBoxHelper {
  static const String keyHasProgress = 'hasProgress';
  static const String keyUserMode = 'userMode';
  static const String keyUserLocation = 'userLocation';
  static const String keyNavPreference = 'navPreference';
  static const String keyProgressData = 'progressData';

  static Future<void> write(String key, dynamic value) async {
    await userBox.put(key, value);
  }

  static T? read<T>(String key, {T? defaultValue}) {
    final val = userBox.get(key, defaultValue: defaultValue);
    if (val is T) return val;
    return defaultValue;
  }

  static Future<void> remove(String key) async {
    await userBox.delete(key);
  }

  static Future<void> clear() async {
    await userBox.clear();
  }

  static bool get hasProgress =>
      read<bool>(keyHasProgress, defaultValue: false) ?? false;

  // Async setters: prefer awaiting these so callers know when writes complete.
  static Future<void> setHasProgress(bool value) =>
      write(keyHasProgress, value);

  static String? get userMode => read<String>(keyUserMode);
  static Future<void> setUserMode(String? value) => write(keyUserMode, value);

  static String? get userLocation => read<String>(keyUserLocation);
  static Future<void> setUserLocation(String? value) =>
      write(keyUserLocation, value);

  static String? get navPreference => read<String>(keyNavPreference);
  static Future<void> setNavPreference(String? value) =>
      write(keyNavPreference, value);

  static dynamic get progressData => read<dynamic>(keyProgressData);
  static Future<void> setProgressData(dynamic value) =>
      write(keyProgressData, value);
}
