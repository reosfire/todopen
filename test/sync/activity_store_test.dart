import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todopen/sync/activity_store.dart';

import 'fake_store.dart';

void main() {
  test(
    'reports uploading while a write is in flight, then goes idle',
    () async {
      final inner = FakeStore();
      final store = ActivityStore(inner);
      SyncActivity? during;
      inner.beforeCas = (_) async => during = store.activity.value;

      await store.compareAndSwap('/manifest', Uint8List(1), null);

      expect(during, SyncActivity.uploading);
      // Lingers briefly so back-to-back requests do not flicker the indicator.
      expect(store.activity.value, SyncActivity.uploading);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(store.activity.value, SyncActivity.idle);
      store.dispose();
    },
  );

  test('a failed request still clears the indicator', () async {
    final inner = FakeStore()..failNextRead.add('/x');
    final store = ActivityStore(inner);

    await expectLater(store.read('/x'), throwsA(anything));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(store.activity.value, SyncActivity.idle);
    store.dispose();
  });
}
