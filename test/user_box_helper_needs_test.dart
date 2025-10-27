import 'dart:io';

import 'package:axeguide/utils/user_box_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_test_needs');
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

  test('needsReconfirm true when lastActive > 30 days ago', () async {
    await UserBoxHelper.clear();
    final past = DateTime.now()
        .subtract(const Duration(days: 31))
        .toIso8601String();
    await UserBoxHelper.write(UserBoxHelper.keyLastActive, past);
    expect(UserBoxHelper.lastActive, isNotNull);
    expect(UserBoxHelper.needsReconfirm, isTrue);
  });

  test('needsReconfirm false when lastActive recent', () async {
    await UserBoxHelper.clear();
    final recent = DateTime.now()
        .subtract(const Duration(days: 2))
        .toIso8601String();
    await UserBoxHelper.write(UserBoxHelper.keyLastActive, recent);
    expect(UserBoxHelper.lastActive, isNotNull);
    expect(UserBoxHelper.needsReconfirm, isFalse);
  });

  test('needsPersonalization true when no userLocation', () async {
    await UserBoxHelper.clear();
    await UserBoxHelper.write(
      UserBoxHelper.keyLastActive,
      DateTime.now().toIso8601String(),
    );
    await UserBoxHelper.remove(UserBoxHelper.keyUserLocation);
    expect(UserBoxHelper.userLocation, isNull);
    expect(UserBoxHelper.needsPersonalization, isTrue);
  });

  test(
    'needsPersonalization false when userLocation present and recent',
    () async {
      await UserBoxHelper.clear();
      await UserBoxHelper.write(
        UserBoxHelper.keyLastActive,
        DateTime.now().toIso8601String(),
      );
      await UserBoxHelper.setUserLocation('Halifax');
      expect(UserBoxHelper.userLocation, 'Halifax');
      expect(UserBoxHelper.needsPersonalization, isFalse);
    },
  );
}
