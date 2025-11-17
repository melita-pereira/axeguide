import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static final prefs = Hive.box('userPreferences');
  static final cache = Hive.box('locationCache');

  static const String keyPrefs = 'prefs';
  static const String keyData = 'data';
  static const String keyFetchedAt = 'fetchedAt';
  static const String keyLocation = 'cachedLocation';

  static Future<void> savePrefs(Map<String, dynamic> prefsMap) async {
    await prefs.put(keyPrefs, prefsMap);
  }

  static Map<String, dynamic>? getPrefs() {
    return (prefs.get(keyPrefs) as Map?)?.cast<String, dynamic>();
  }

  static Future<void> saveLocations(List<dynamic> locations, String location) async {
    await cache.put(keyData, locations);
    await cache.put(keyFetchedAt, DateTime.now().toIso8601String());
    await cache.put(keyLocation, location);
  }

  static List<dynamic>? getCachedLocationsFor(String currentLocation) {
    final cachedLocation = cache.get(keyLocation);

    if (cachedLocation == null) {
      return null;
    }
    if (cachedLocation != currentLocation) {
      return null;
    }

    return cache.get(keyData) as List<dynamic>?;
  }

  static bool isCacheStale(String currentLocation, {Duration maxAge = const Duration(hours: 1)}) {
    final cachedLocation = cache.get(keyLocation);
    if (cachedLocation == null) {
      return true;
    }
    if (cachedLocation != currentLocation) {
      return true;
    }
    final fetchedAtStr = cache.get(keyFetchedAt);
    if (fetchedAtStr == null) {
      return true;
    }
    try {
      final dt = DateTime.parse(fetchedAtStr);
      return DateTime.now().difference(dt) > maxAge;
    } catch (e) {
      return true;
    }
  }
  static Future<void> clearCache() async {
    await cache.clear();
  }
}
