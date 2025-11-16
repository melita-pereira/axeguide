import 'dart:io';

import 'package:axeguide/screens/home_screen.dart';
import 'package:axeguide/services/hive_service.dart';
import 'package:axeguide/utils/user_box_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_test_home_screen');
    Hive.init(tmpDir.path);
    await Hive.openBox('userPreferences');
    await Hive.openBox('locationCache');
    await Hive.openBox('userBox');
  });

  tearDownAll(() async {
    await Hive.box('locationCache').clear();
    await Hive.box('userPreferences').clear();
    await Hive.box('userBox').clear();
    await Hive.box('locationCache').close();
    await Hive.box('userPreferences').close();
    await Hive.box('userBox').close();
    try {
      await tmpDir.delete(recursive: true);
    } catch (_) {}
  });

  group('HomeScreen - Loading States', () {
    setUp(() async {
      await Hive.box('locationCache').clear();
      await Hive.box('userBox').clear();
    });

    testWidgets('HomeScreen displays loading indicator while fetching data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching data...'), findsOneWidget);
    });

    testWidgets('HomeScreen displays user location and mode',
        (WidgetTester tester) async {
      await UserBoxHelper.setUserLocation('Halifax');
      await UserBoxHelper.setUserMode('Guide');

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Location: Halifax'), findsOneWidget);
      expect(find.text('Mode: Guide'), findsOneWidget);
    });

    testWidgets(
        'HomeScreen displays "Unknown" location and "Guest" mode when not set',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Location: Unknown'), findsOneWidget);
      expect(find.text('Mode: Guest'), findsOneWidget);
    });
  });

  group('HomeScreen - Fallback/Cache States', () {
    setUp(() async {
      await Hive.box('locationCache').clear();
      await Hive.box('userBox').clear();
    });

    testWidgets('HomeScreen displays cached locations when cache is fresh',
        (WidgetTester tester) async {
      // Setup fresh cache
      final cachedLocations = [
        {
          'name': 'Acadia National Park',
          'description': 'Beautiful park',
          'town': 'Acadia',
          'hours': '9 AM - 5 PM',
          'map_link': '',
          'latitude': 44.35,
          'longitude': -68.23,
        },
      ];
      await HiveService.saveLocations(cachedLocations);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Acadia National Park'), findsOneWidget);
      expect(find.text('Beautiful park'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsWidgets);
    });

    testWidgets('HomeScreen displays empty state when no locations available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
        find.text('No locations available at the moment.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'HomeScreen hides loading indicator after data is loaded',
        (WidgetTester tester) async {
      final cachedLocations = [
        {
          'name': 'Test Location',
          'description': 'Test',
          'town': 'Test Town',
          'hours': '10 AM - 6 PM',
          'map_link': '',
          'latitude': 45.0,
          'longitude': -63.0,
        },
      ];
      await HiveService.saveLocations(cachedLocations);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should not show loading after data is loaded
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Fetching data...'), findsNothing);
    });
  });

  group('HomeScreen - Location Card Display', () {
    setUp(() async {
      await Hive.box('locationCache').clear();
      await Hive.box('userBox').clear();
    });

    testWidgets('HomeScreen displays location card with all information',
        (WidgetTester tester) async {
      final locations = [
        {
          'name': 'Test Attraction',
          'description': 'A great place to visit',
          'town': 'Halifax',
          'hours': '10 AM - 5 PM',
          'map_link': 'https://maps.example.com',
          'latitude': 44.6426,
          'longitude': -63.2181,
        },
      ];
      await HiveService.saveLocations(locations);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Test Attraction'), findsOneWidget);
      expect(find.text('A great place to visit'), findsOneWidget);
      expect(find.text('Halifax'), findsOneWidget);
      expect(find.text('Hours: 10 AM - 5 PM'), findsOneWidget);
      expect(find.text('View on Map'), findsOneWidget);
    });

    testWidgets('HomeScreen displays "Hours not available" when hours is null',
        (WidgetTester tester) async {
      final locations = [
        {
          'name': 'Test Place',
          'description': 'Test',
          'town': 'Test Town',
          'hours': null,
          'map_link': '',
          'latitude': 45.0,
          'longitude': -63.0,
        },
      ];
      await HiveService.saveLocations(locations);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Hours not available'), findsOneWidget);
    });

    testWidgets('HomeScreen displays multiple location cards',
        (WidgetTester tester) async {
      final locations = [
        {
          'name': 'Location 1',
          'description': 'Desc 1',
          'town': 'Town 1',
          'hours': '9 AM - 5 PM',
          'map_link': '',
          'latitude': 44.0,
          'longitude': -63.0,
        },
        {
          'name': 'Location 2',
          'description': 'Desc 2',
          'town': 'Town 2',
          'hours': '10 AM - 6 PM',
          'map_link': '',
          'latitude': 45.0,
          'longitude': -64.0,
        },
      ];
      await HiveService.saveLocations(locations);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Location 1'), findsOneWidget);
      expect(find.text('Location 2'), findsOneWidget);
      expect(find.text('Desc 1'), findsOneWidget);
      expect(find.text('Desc 2'), findsOneWidget);
    });
  });

  group('HomeScreen - Settings Navigation', () {
    testWidgets('HomeScreen has settings button in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
    });
  });

  group('HomeScreen - Welcome Message', () {
    testWidgets('HomeScreen displays welcome message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
    });
  });
}
