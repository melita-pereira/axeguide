import 'dart:io';

import 'package:axeguide/utils/user_box_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_test_nav');
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

  test(
    'shouldShowNavSetup true when navPreference is null and recent lastActive',
    () async {
      await UserBoxHelper.clear();
      // recent lastActive
      await UserBoxHelper.updateLastActive();
      await UserBoxHelper.remove(UserBoxHelper.keyNavPreference);

      final shouldShowNavSetup =
          UserBoxHelper.navPreference == null || UserBoxHelper.needsReconfirm;
      expect(shouldShowNavSetup, isTrue);
    },
  );

  test(
    'shouldShowNavSetup false when navPreference set and recent lastActive',
    () async {
      await UserBoxHelper.clear();
      await UserBoxHelper.updateLastActive();
      await UserBoxHelper.setNavPreference('basic');

      final shouldShowNavSetup =
          UserBoxHelper.navPreference == null || UserBoxHelper.needsReconfirm;
      expect(shouldShowNavSetup, isFalse);
    },
  );

  test(
    'shouldShowNavSetup true when navPreference set but needsReconfirm true',
    () async {
      await UserBoxHelper.clear();
      // old lastActive to force reconfirm
      final past = DateTime.now()
          .subtract(const Duration(days: 31))
          .toIso8601String();
      await UserBoxHelper.write(UserBoxHelper.keyLastActive, past);
      await UserBoxHelper.setNavPreference('basic');

      final shouldShowNavSetup =
          UserBoxHelper.navPreference == null || UserBoxHelper.needsReconfirm;
      expect(shouldShowNavSetup, isTrue);
    },
  );
}
