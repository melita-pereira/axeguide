import 'dart:io';

import 'package:axeguide/services/hive_service.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

// HomeScreen Integration Tests
// 
// NOTE: Full widget tests for HomeScreen are not included because HomeScreen
// makes direct Supabase.instance.client calls that hang in test environments
// without proper mocking infrastructure.
//
// These tests verify the core business logic that HomeScreen depends on:
// - User data persistence (UserBoxHelper)
// - Location caching (HiveService)
// - Cache staleness detection
//
// This ensures HomeScreen's data layer works correctly even though we can't
// test the UI rendering without mocking Supabase.

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tmpDir = await Directory.systemTemp.createTemp('hive_test_home_integration');
    Hive.init(tmpDir.path);
    await Hive.openBox('userPreferences');
    await Hive.openBox('locationCache');
    await Hive.openBox('userBox');
  });

  tearDownAll(() async {
    try {
      if (Hive.isBoxOpen('locationCache')) {
        await Hive.box('locationCache').clear();
        await Hive.box('locationCache').close();
      }
      if (Hive.isBoxOpen('userPreferences')) {
        await Hive.box('userPreferences').clear();
        await Hive.box('userPreferences').close();
      }
      if (Hive.isBoxOpen('userBox')) {
        await Hive.box('userBox').clear();
        await Hive.box('userBox').close();
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

  group('HomeScreen Data Layer - User Information', () {
    setUp(() async {
      if (!Hive.isBoxOpen('userBox')) {
        await Hive.openBox('userBox');
      }
      await Hive.box('userBox').clear();
    });

    test('UserBoxHelper stores and retrieves user location', () async {
      await UserBoxHelper.setUserLocation('Halifax');
      expect(UserBoxHelper.userLocation, 'Halifax');
    });

    test('UserBoxHelper stores and retrieves user mode', () async {
      await UserBoxHelper.setUserMode('Guide');
      expect(UserBoxHelper.userMode, 'Guide');
    });

    test('UserBoxHelper returns null for unset location', () async {
      expect(UserBoxHelper.userLocation, isNull);
    });

    test('UserBoxHelper returns null for unset mode', () async {
      expect(UserBoxHelper.userMode, isNull);
    });

    test('HomeScreen would show "Unknown" location when UserBoxHelper returns null', () async {
      final location = UserBoxHelper.userLocation ?? 'Unknown';
      expect(location, 'Unknown');
    });

    test('HomeScreen would show "Guest" mode when UserBoxHelper returns null', () async {
      final mode = UserBoxHelper.userMode ?? 'Guest';
      expect(mode, 'Guest');
    });
  });

  group('HomeScreen Data Layer - Location Caching', () {
    setUp(() async {
      if (!Hive.isBoxOpen('locationCache')) {
        await Hive.openBox('locationCache');
      }
      await Hive.box('locationCache').clear();
    });

    test('HiveService stores and retrieves locations for a town', () async {
      final locations = [
        {
          'name': 'Test Location',
          'description': 'A test place',
          'town': 'Halifax',
          'hours': '9 AM - 5 PM',
          'map_link': '',
          'latitude': 44.64,
          'longitude': -63.57,
        },
      ];

      await HiveService.saveLocations(locations, 'Halifax');
      final cached = HiveService.getCachedLocationsFor('Halifax');

      expect(cached, isNotNull);
      expect(cached!.length, 1);
      expect(cached[0]['name'], 'Test Location');
    });

    test('HiveService returns null when no cache exists for location', () {
      final cached = HiveService.getCachedLocationsFor('NonExistent');
      expect(cached, isNull);
    });

    test('HiveService returns null when cached location does not match requested location', () async {
      final locations = [
        {'name': 'Place', 'town': 'Halifax'},
      ];
      await HiveService.saveLocations(locations, 'Halifax');

      final cached = HiveService.getCachedLocationsFor('Wolfville');
      expect(cached, isNull);
    });

    test('HomeScreen can use fresh cache to avoid Supabase call', () async {
      final locations = [
        {
          'name': 'Cached Place',
          'description': 'From cache',
          'town': 'Acadia',
        },
      ];
      await HiveService.saveLocations(locations, 'Acadia');

      final isStale = HiveService.isCacheStale('Acadia');
      final cached = HiveService.getCachedLocationsFor('Acadia');

      // This is what HomeScreen._initialize() checks
      expect(isStale, isFalse);
      expect(cached, isNotNull);
      expect(cached!.isNotEmpty, isTrue);
      
      // In this case, HomeScreen would use cache and skip _loadLocations()
      if (!isStale && cached.isNotEmpty) {
        expect(cached[0]['name'], 'Cached Place');
      }
    });

    test('HomeScreen would call Supabase when cache is stale', () async {
      final locations = [{'name': 'Old Data'}];
      await HiveService.saveLocations(locations, 'Halifax');

      // Simulate stale cache
      final oldTime = DateTime.now().subtract(const Duration(hours: 2));
      await Hive.box('locationCache').put('fetchedAt', oldTime.toIso8601String());

      final isStale = HiveService.isCacheStale('Halifax');
      expect(isStale, isTrue);
      
      // In this case, HomeScreen would call _loadLocations() (which we can't test)
    });

    test('HomeScreen would call Supabase when cache is empty', () async {
      await HiveService.saveLocations([], 'EmptyTown');

      final isStale = HiveService.isCacheStale('EmptyTown');
      final cached = HiveService.getCachedLocationsFor('EmptyTown');

      // Fresh but empty cache
      expect(isStale, isFalse);
      expect(cached, isNotNull);
      expect(cached!.isEmpty, isTrue);
      
      // HomeScreen._initialize() would still call _loadLocations() because cache is empty
    });
  });

  group('HomeScreen Data Layer - Cache Staleness Logic', () {
    setUp(() async {
      if (!Hive.isBoxOpen('locationCache')) {
        await Hive.openBox('locationCache');
      }
      await Hive.box('locationCache').clear();
    });

    test('Fresh cache prevents Supabase call in HomeScreen', () async {
      await HiveService.saveLocations([{'name': 'Test'}], 'Halifax');
      
      final isStale = HiveService.isCacheStale('Halifax', maxAge: const Duration(hours: 1));
      expect(isStale, isFalse);
    });

    test('Stale cache triggers Supabase call in HomeScreen', () async {
      await HiveService.saveLocations([{'name': 'Test'}], 'Halifax');
      
      final oldTime = DateTime.now().subtract(const Duration(hours: 2));
      await Hive.box('locationCache').put('fetchedAt', oldTime.toIso8601String());

      final isStale = HiveService.isCacheStale('Halifax', maxAge: const Duration(hours: 1));
      expect(isStale, isTrue);
    });

    test('No cache triggers Supabase call in HomeScreen', () {
      final isStale = HiveService.isCacheStale('NewTown');
      expect(isStale, isTrue);
    });
  });

  group('HomeScreen Data Layer - Multiple Locations', () {
    setUp(() async {
      if (!Hive.isBoxOpen('locationCache')) {
        await Hive.openBox('locationCache');
      }
      await Hive.box('locationCache').clear();
    });

    test('HiveService handles multiple locations correctly', () async {
      final locations = [
        {'name': 'Location 1', 'town': 'Halifax'},
        {'name': 'Location 2', 'town': 'Halifax'},
        {'name': 'Location 3', 'town': 'Halifax'},
      ];

      await HiveService.saveLocations(locations, 'Halifax');
      final cached = HiveService.getCachedLocationsFor('Halifax');

      expect(cached, isNotNull);
      expect(cached!.length, 3);
      expect(cached[0]['name'], 'Location 1');
      expect(cached[1]['name'], 'Location 2');
      expect(cached[2]['name'], 'Location 3');
    });

    test('HomeScreen would display all cached locations', () async {
      final locations = [
        {
          'name': 'Place A',
          'description': 'Description A',
          'town': 'Wolfville',
          'hours': '9-5',
        },
        {
          'name': 'Place B',
          'description': 'Description B',
          'town': 'Wolfville',
          'hours': '10-6',
        },
      ];

      await HiveService.saveLocations(locations, 'Wolfville');
      final cached = HiveService.getCachedLocationsFor('Wolfville');

      expect(cached, isNotNull);
      expect(cached!.length, 2);
      
      // HomeScreen would map over these locations to create cards
      for (var loc in cached) {
        expect(loc['name'], isIn(['Place A', 'Place B']));
        expect(loc['description'], isIn(['Description A', 'Description B']));
      }
    });
  });
}
