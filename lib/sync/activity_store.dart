import 'dart:async';

import 'package:flutter/foundation.dart';

import 'engine/remote_store.dart';

/// What the network is doing right now, for the UI.
enum SyncActivity { idle, downloading, uploading }

/// A [RemoteStore] that reports whether any request is in flight.
///
/// Wraps the real store rather than instrumenting the engine, so every
/// transfer is seen — background pushes and pulls included, not just the
/// syncs a user started by hand.
class ActivityStore implements RemoteStore {
  final RemoteStore _inner;

  ActivityStore(this._inner);

  /// Uploading wins when both directions are busy: unsent edits are what a
  /// user wants to see leave the device.
  final ValueNotifier<SyncActivity> activity = ValueNotifier(SyncActivity.idle);

  int _reads = 0;
  int _writes = 0;

  /// A sync is several requests back to back. Without a short grace period
  /// the indicator would flicker off between them.
  static const _linger = Duration(milliseconds: 400);
  Timer? _idleTimer;

  void _update() {
    final next = _writes > 0
        ? SyncActivity.uploading
        : _reads > 0
        ? SyncActivity.downloading
        : SyncActivity.idle;
    if (next == SyncActivity.idle) {
      _idleTimer ??= Timer(_linger, () {
        _idleTimer = null;
        activity.value = SyncActivity.idle;
      });
      return;
    }
    _idleTimer?.cancel();
    _idleTimer = null;
    activity.value = next;
  }

  Future<T> _read<T>(Future<T> Function() op) async {
    _reads++;
    _update();
    try {
      return await op();
    } finally {
      _reads--;
      _update();
    }
  }

  Future<T> _write<T>(Future<T> Function() op) async {
    _writes++;
    _update();
    try {
      return await op();
    } finally {
      _writes--;
      _update();
    }
  }

  @override
  Future<RemoteFile?> read(String path) => _read(() => _inner.read(path));

  @override
  Future<List<Uint8List?>> readMany(List<String> paths) =>
      _read(() => _inner.readMany(paths));

  @override
  Future<void> writeNew(String path, Uint8List bytes) =>
      _write(() => _inner.writeNew(path, bytes));

  @override
  Future<void> overwrite(String path, Uint8List bytes) =>
      _write(() => _inner.overwrite(path, bytes));

  @override
  Future<String> compareAndSwap(
    String path,
    Uint8List bytes,
    String? expectedRev,
  ) => _write(() => _inner.compareAndSwap(path, bytes, expectedRev));

  @override
  Future<void> delete(String path) => _write(() => _inner.delete(path));

  @override
  Future<void> deleteMany(List<String> paths) =>
      _write(() => _inner.deleteMany(paths));

  void dispose() {
    _idleTimer?.cancel();
    activity.dispose();
  }
}
