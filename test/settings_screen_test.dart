import 'dart:io';

import 'package:axeguide/utils/user_box_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_test_settings');
    Hive.init(tmpDir.path);
    await Hive.openBox('userBox');
  });

  tearDownAll(() async {
    await Hive.box('userBox').clear();
    await Hive.box('userBox').close();
    try {
      await tmpDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Settings Screen - Clear Personalization Data', () {
    test('Can set user personalization data', () async {
      await UserBoxHelper.setUserLocation('Halifax');
      await UserBoxHelper.setNavPreference('in-depth');
      await UserBoxHelper.setHasSeenWelcome(true);

      expect(UserBoxHelper.userLocation, 'Halifax');
      expect(UserBoxHelper.navPreference, 'in-depth');
      expect(UserBoxHelper.hasSeenWelcome, isTrue);
    });

    test('UserBoxHelper.clear() removes all personalization data', () async {
      // Setup
      await UserBoxHelper.setUserLocation('Acadia');
      await UserBoxHelper.setNavPreference('basic');
      await UserBoxHelper.setHasSeenWelcome(true);

      expect(UserBoxHelper.userLocation, 'Acadia');
      expect(UserBoxHelper.navPreference, 'basic');

      // Execute clear
      await UserBoxHelper.clear();

      // Verify all data is cleared
      expect(UserBoxHelper.userLocation, isNull);
      expect(UserBoxHelper.navPreference, isNull);
      expect(UserBoxHelper.hasSeenWelcome, isFalse);
    });

    test('Clear does not affect Hive box integrity', () async {
      // Setup
      await UserBoxHelper.setUserLocation('Wolfville');

      // Verify data exists
      expect(UserBoxHelper.userLocation, 'Wolfville');

      // Clear
      await UserBoxHelper.clear();

      // Verify box is still accessible and empty
      expect(UserBoxHelper.userLocation, isNull);

      // Verify we can set data again
      await UserBoxHelper.setUserLocation('New Halifax');
      expect(UserBoxHelper.userLocation, 'New Halifax');
    });

    test('Multiple clears work correctly', () async {
      await UserBoxHelper.setUserLocation('Location 1');
      await UserBoxHelper.clear();
      expect(UserBoxHelper.userLocation, isNull);

      await UserBoxHelper.setUserLocation('Location 2');
      await UserBoxHelper.clear();
      expect(UserBoxHelper.userLocation, isNull);
    });
  });
}
