import 'dart:io';

import 'package:axeguide/utils/user_box_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_test');
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

  test('checkpoint lifecycle works', () async {
    // ensure clean
    await UserBoxHelper.clear();

    expect(UserBoxHelper.getCheckpoint(), isNull);
    expect(UserBoxHelper.hasProgress, isFalse);

    final id = await UserBoxHelper.setCheckpoint('step-1');
    expect(id, 'step-1');
    expect(UserBoxHelper.getCheckpoint(), 'step-1');
    expect(UserBoxHelper.hasProgress, isTrue);

    final removed = await UserBoxHelper.clearCheckpoint();
    expect(removed, isTrue);
    expect(UserBoxHelper.getCheckpoint(), isNull);

    final removedAgain = await UserBoxHelper.clearCheckpoint();
    expect(removedAgain, isFalse);
  });
}
