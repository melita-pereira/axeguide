import 'package:hive_flutter/hive_flutter.dart';
class HiveService {
  static final prefs = Hive.box('userPreferences');
  static final cache = Hive.box('locationCache');

  static Future<void> savePrefs(Map<String, dynamic> prefsMap) async {
    await prefs.put('prefs', prefsMap);
  }

  static Map<String, dynamic>? getPrefs() {
    return (prefs.get('prefs') as Map?)?.cast<String, dynamic>();
  }

  static Future<void> saveLocations(List<dynamic> locations) async {
    await cache.put('data', locations);
    await cache.put('fetchedAt', DateTime.now().toIso8601String());
  }

  static List<dynamic>? getCachedLocations() {
    return cache.get('data') as List<dynamic>?;
  }

  static bool isCacheStale({Duration maxAge = const Duration(hours: 1)}) {
    final fetchedAtStr = cache.get('fetchedAt');
    if (fetchedAtStr == null) return true;
    final dt = DateTime.tryParse(fetchedAtStr);
    if (dt == null) return true;
    return DateTime.now().difference(dt) > maxAge;
  }
}