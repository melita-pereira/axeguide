import 'package:axeguide/utils/hive_boxes.dart';

class UserBoxHelper {
  static const String keyHasProgress = 'hasProgress';
  static const String keyUserMode = 'userMode';
  static const String keyUserLocation = 'userLocation';
  static const String keyNavPreference = 'navPreference';
  static const String keyProgressData = 'progressData';
  static const String keyLastStep = 'lastStep';
  static const String keyLastActive = 'lastActive';
  static const String keyHasSeenWelcome = 'hasSeenWelcome';

  static Future<void> write(String key, dynamic value) async {
    await userBox.put(key, value);
  }

  static T? read<T>(String key, {T? defaultValue}) {
    final val = userBox.get(key, defaultValue: defaultValue);
    if (val == null) {
      return defaultValue;
    }
    if (val is T) {
      return val;
    }
    return defaultValue;
  }

  static Future<void> remove(String key) async {
    await userBox.delete(key);
  }

  static Future<void> clear() async {
    await userBox.clear();
  }

  static Future<String?> setCheckpoint(String stepId) async {
    await userBox.put(keyLastStep, stepId);
    await userBox.put(keyHasProgress, true);
    // Read back the persisted value to ensure correct stored type/value.
    return read<String>(keyLastStep);
  }

  static String? getCheckpoint() {
    return read<String>(keyLastStep);
  }

  static Future<bool> clearCheckpoint() async {
    final hasCheckpoint = userBox.containsKey(keyLastStep);
    await userBox.delete(keyLastStep);
    return hasCheckpoint;
  }

  static Future<void> updateLastActive() async {
    await write(keyLastActive, DateTime.now().toIso8601String());
  }

  static DateTime? get lastActive {
    final str = read<String>(keyLastActive);
    return str != null ? DateTime.tryParse(str) : null;
  }

  static bool get needsReconfirm {
    // Use the parsed `lastActive` value (stored as ISO string) instead of
    // incorrectly casting the `keyLastActive` constant.
    final lastActive = UserBoxHelper.lastActive;
    if (lastActive == null) return false;
    final diff = DateTime.now().difference(lastActive).inDays;
    return diff >= 30;
  }

  static bool get needsPersonalization {
    final location = userLocation;
    return location == null || needsReconfirm;
  }

  static bool get hasSeenWelcome =>
      read<bool>(keyHasSeenWelcome, defaultValue: false) ?? false;

  static Future<void> setHasSeenWelcome(bool value) =>
      write(keyHasSeenWelcome, value);

  static bool get hasProgress =>
      read<bool>(keyHasProgress, defaultValue: false) ?? false;

  // Async setters: prefer awaiting these so callers know when writes complete.
  static Future<void> setHasProgress(bool value) async {
    await write(keyHasProgress, value);
  }

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

  static String? get walkthroughCheckpoint =>
      read<String>('walkthrough_checkpoint');

  static bool get hasWalkthroughCheckpoint =>
      walkthroughCheckpoint != null;

  static Future<void> setWalkthroughCheckpoint(String id) =>
      write('walkthrough_checkpoint', id);

  static Future<void> clearWalkthroughCheckpoint() =>
      remove('walkthrough_checkpoint');
}