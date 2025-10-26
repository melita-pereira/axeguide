import 'hive_boxes.dart';

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
    return userBox.get(key, defaultValue: defaultValue) as T;
  }

  static Future<void> remove(String key) async {
    await userBox.delete(key);
  }

  static Future<void> clear() async {
    await userBox.clear();
  }

  static bool get hasProgress => read<bool>(keyHasProgress, defaultValue: false) ?? false;
  static set hasProgress(bool value) => write(keyHasProgress, value);

  static String? get userMode => read<String>(keyUserMode);
  static set userMode(String? value) => write(keyUserMode, value);

  static String? get userLocation => read<String>(keyUserLocation);
  static set userLocation(String? value) => write(keyUserLocation, value);

  static String? get navPreference => read<String>(keyNavPreference);
  static set navPreference(String? value) => write(keyNavPreference, value);

  static dynamic get progressData => read<dynamic>(keyProgressData);
  static set progressData(dynamic value) => write(keyProgressData, value);
}