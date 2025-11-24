import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static final prefs = Hive.box('userPreferences');
  static final cache = Hive.box('locationCache');

  static const String keyPrefs = 'prefs';
  static const String keyData = 'data';
  static const String keyFetchedAt = 'fetchedAt';
  static const String keyLocation = 'cachedLocation';

  static String _dataKey(String loc) => "${loc.toLowerCase()}_data";
  static String _timestampKey(String loc) => "${loc.toLowerCase()}_timestamp";

  static Future<void> savePrefs(Map<String, dynamic> prefsMap) async {
    await prefs.put(keyPrefs, prefsMap);
  }

  static Map<String, dynamic>? getPrefs() {
    final raw = prefs.get(keyPrefs);
    if (raw == null) {
      return null;
    }
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> saveLocations(List<dynamic> locations, String location) async {
    final key = location.toLowerCase();
    await cache.put(_dataKey(key), locations);
    await cache.put(_timestampKey(key), DateTime.now().toIso8601String());
  }

  static List<dynamic>? getCachedLocationsFor(String location) {
    final key = location.toLowerCase();

    final data = cache.get(_dataKey(key));
    if (data is! List) {
      return null;
    }
    return data.cast();
  }

  static bool isCacheStale(String location, {Duration maxAge = const Duration(hours: 1)}) {
    final key = location.toLowerCase();
    final tsString = cache.get(_timestampKey(key));
    if (tsString == null) {
      return true;
    }
    try {
      final ts = DateTime.parse(tsString);
      return DateTime.now().difference(ts) > maxAge;
    } catch (_) {
      return true;
    }
  }

  static Future<void> clearCacheForLocation(String location) async {
    final key = location.toLowerCase();
    await cache.delete(_dataKey(key));
    await cache.delete(_timestampKey(key));
  }

  static Future<void> clearCache() async {
    await cache.clear();
  }
}