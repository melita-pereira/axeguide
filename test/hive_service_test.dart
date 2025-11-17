import 'dart:io';

import 'package:axeguide/services/hive_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_test_service');
    Hive.init(tmpDir.path);
    await Hive.openBox('userPreferences');
    await Hive.openBox('locationCache');
  });

  tearDownAll(() async {
    try {
      if (Hive.isBoxOpen('locationCache')) {
        await Hive.box('locationCache').clear();
        await Hive.box('locationCache').close();
        await Hive.deleteBoxFromDisk('locationCache');
      }
      if (Hive.isBoxOpen('userPreferences')) {
        await Hive.box('userPreferences').clear();
        await Hive.box('userPreferences').close();
        await Hive.deleteBoxFromDisk('userPreferences');
      }
    } catch (_) {}
    try {
      await Hive.close();
    } catch (_) {}
    try {
      if (tmpDir.existsSync()) {
        await tmpDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('HiveService - Preferences', () {
    setUp(() async {
      if (!Hive.isBoxOpen('userPreferences')) {
        await Hive.openBox('userPreferences');
      }
      await Hive.box('userPreferences').clear();
    });
    test('savePrefs() stores preferences correctly', () async {
      final testPrefs = {'theme': 'dark', 'language': 'en'};
      await HiveService.savePrefs(testPrefs);

      final retrieved = HiveService.getPrefs();
      expect(retrieved, isNotNull);
      expect(retrieved!['theme'], 'dark');
      expect(retrieved['language'], 'en');
    });

    test('getPrefs() returns null when no preferences are saved', () async {
      await Hive.box('userPreferences').clear();
      final prefs = HiveService.getPrefs();
      expect(prefs, isNull);
    });

    test('savePrefs() overwrites existing preferences', () async {
      final prefs1 = {'theme': 'light'};
      await HiveService.savePrefs(prefs1);
      expect(HiveService.getPrefs()!['theme'], 'light');

      final prefs2 = {'theme': 'dark', 'fontSize': 16};
      await HiveService.savePrefs(prefs2);
      final retrieved = HiveService.getPrefs();
      expect(retrieved!['theme'], 'dark');
      expect(retrieved['fontSize'], 16);
    });
  });

  group('HiveService - Location Cache', () {
    setUp(() async {
      if (!Hive.isBoxOpen('locationCache')) {
        await Hive.openBox('locationCache');
      }
      await Hive.box('locationCache').clear();
    });

    test('saveLocations() stores locations with timestamp', () async {
      final locations = [
        {'name': 'Location 1', 'town': 'Halifax'},
        {'name': 'Location 2', 'town': 'Wolfville'},
      ];

      await HiveService.saveLocations(locations, 'Halifax');

      final cached = HiveService.getCachedLocationsFor('Halifax');
      expect(cached, isNotNull);
      expect(cached!.length, 2);
      expect(cached[0]['name'], 'Location 1');
      expect(cached[1]['name'], 'Location 2');
    });

    test('getCachedLocations() returns null when cache is empty', () async {
      final cached = HiveService.getCachedLocationsFor('Halifax');
      expect(cached, isNull);
    });

    test('saveLocations() updates existing cache', () async {
      final locations1 = [{'name': 'Old Location'}];
      await HiveService.saveLocations(locations1, 'Halifax');
      expect(HiveService.getCachedLocationsFor('Halifax')!.length, 1);

      final locations2 = [
        {'name': 'New Location 1'},
        {'name': 'New Location 2'},
        {'name': 'New Location 3'},
      ];
      await HiveService.saveLocations(locations2, 'Halifax');
      final cached = HiveService.getCachedLocationsFor('Halifax');
      expect(cached!.length, 3);
      expect(cached[0]['name'], 'New Location 1');
    });

    test('getCachedLocations() returns cast list as List<Map<String, dynamic>>', () async {
      final locations = [
        {'name': 'Loc1', 'id': 1, 'active': true},
        {'name': 'Loc2', 'id': 2, 'active': false},
      ];
      await HiveService.saveLocations(locations, 'Halifax');

      final cached = HiveService.getCachedLocationsFor('Halifax') as List<Map<String, dynamic>>?;
      expect(cached, isNotNull);
      expect(cached!.first['name'], 'Loc1');
      expect(cached[0]['id'], 1);
      expect(cached[1]['active'], isFalse);
    });

    test('saveLocations() stores ISO8601 timestamp', () async {
      final before = DateTime.now();
      await HiveService.saveLocations([{'name': 'Test'}], 'Halifax');
      final after = DateTime.now();

      final fetchedAtStr = Hive.box('locationCache').get('fetchedAt') as String?;
      expect(fetchedAtStr, isNotNull);

      final fetchedAt = DateTime.parse(fetchedAtStr!);
      expect(fetchedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(fetchedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('HiveService - Cache Staleness', () {
    setUp(() async {
      if (!Hive.isBoxOpen('locationCache')) {
        await Hive.openBox('locationCache');
      }
      await Hive.box('locationCache').clear();
    });

    test('isCacheStale() returns true when no fetchedAt timestamp exists', () {
      final isStale = HiveService.isCacheStale('Halifax');
      expect(isStale, isTrue);
    });

    test('isCacheStale() returns false for fresh cache (within maxAge)', () async {
      await HiveService.saveLocations([{'name': 'Test'}], 'Halifax');
      final isStale = HiveService.isCacheStale('Halifax', maxAge: const Duration(hours: 1));
      expect(isStale, isFalse);
    });

    test('isCacheStale() returns true for stale cache (older than maxAge)', () async {
      await HiveService.saveLocations([{'name': 'Test'}], 'Halifax');

      // Simulate old timestamp
      final oldTime = DateTime.now().subtract(const Duration(hours: 2));
      await Hive.box('locationCache').put('fetchedAt', oldTime.toIso8601String());

      final isStale = HiveService.isCacheStale('Halifax', maxAge: const Duration(hours: 1));
      expect(isStale, isTrue);
    });

    test('isCacheStale() with custom maxAge duration works correctly', () async {
      await HiveService.saveLocations([{'name': 'Test'}], 'Halifax');

      // Simulate an older fetchedAt so we can test different maxAge values.
      // Make the cache ~45 minutes old: stale for 30 minutes, fresh for 2 hours.
      final simulatedOldTime = DateTime.now().subtract(const Duration(minutes: 45));
      await Hive.box('locationCache').put('fetchedAt', simulatedOldTime.toIso8601String());

      final isStaleFor30Min = HiveService.isCacheStale('Halifax', maxAge: const Duration(minutes: 30));
      final isStaleFor2Hours = HiveService.isCacheStale('Halifax', maxAge: const Duration(hours: 2));

      expect(isStaleFor30Min, isTrue);
      expect(isStaleFor2Hours, isFalse);
    });

    test('isCacheStale() handles invalid timestamp gracefully', () async {
      await Hive.box('locationCache').put('fetchedAt', 'invalid-date');
      final isStale = HiveService.isCacheStale('Halifax');
      expect(isStale, isTrue);
    });

    test('isCacheStale() returns true when fetchedAt is empty string', () async {
      await Hive.box('locationCache').put('fetchedAt', '');
      final isStale = HiveService.isCacheStale('Halifax');
      expect(isStale, isTrue);
    });
  });
}
