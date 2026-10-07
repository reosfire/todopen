import 'dart:typed_data';

import 'package:todopen/sync/engine/remote_store.dart';

/// In-memory [RemoteStore] with real CAS semantics.
///
/// Lets tests run two engines against one "server" and exercise the paths
/// that only appear under concurrency: lost CAS races, orphaned segments,
/// and files disappearing mid-sync because another device compacted.
class FakeStore implements RemoteStore {
  final Map<String, Uint8List> files = {};
  final Map<String, int> _revs = {};
  int _revCounter = 0;

  /// Per-path counters, so tests can assert on request volume.
  int reads = 0;
  int writes = 0;
  int deletes = 0;
  int bytesRead = 0;
  int bytesWritten = 0;

  /// When set, invoked before each CAS. A test can mutate the store from
  /// here to simulate another device committing at the worst moment.
  Future<void> Function(String path)? beforeCas;

  /// Paths whose next read should fail, simulating a flaky network.
  final Set<String> failNextRead = {};

  /// When set, invoked before each overwrite (chunk upload), so a test can
  /// let another device run between two uploads.
  Future<void> Function(String path)? beforeOverwrite;

  /// When true, the next CAS commits and then reports a conflict anyway, as
  /// happens when the response to a committed write is lost and the retry
  /// finds the rev already moved.
  bool commitThenConflictNextCas = false;

  void resetCounters() {
    reads = writes = deletes = bytesRead = bytesWritten = 0;
  }

  @override
  Future<RemoteFile?> read(String path) async {
    reads++;
    if (failNextRead.remove(path)) {
      throw Exception('simulated network failure reading $path');
    }
    final b = files[path];
    if (b == null) return null;
    bytesRead += b.length;
    return RemoteFile(b, _revs[path]!.toString());
  }

  @override
  Future<List<Uint8List?>> readMany(List<String> paths) async {
    final out = <Uint8List?>[];
    for (final p in paths) {
      reads++;
      if (failNextRead.remove(p)) {
        throw Exception('simulated network failure reading $p');
      }
      final b = files[p];
      if (b != null) bytesRead += b.length;
      out.add(b);
    }
    return out;
  }

  @override
  Future<void> writeNew(String path, Uint8List bytes) async {
    if (files.containsKey(path)) {
      throw StateError('writeNew on existing path $path');
    }
    writes++;
    bytesWritten += bytes.length;
    files[path] = bytes;
    _revs[path] = ++_revCounter;
  }

  @override
  Future<void> overwrite(String path, Uint8List bytes) async {
    await beforeOverwrite?.call(path);
    writes++;
    bytesWritten += bytes.length;
    files[path] = bytes;
    _revs[path] = ++_revCounter;
  }

  @override
  Future<String> compareAndSwap(
    String path,
    Uint8List bytes,
    String? expectedRev,
  ) async {
    await beforeCas?.call(path);
    final currentRev = _revs[path]?.toString();
    if (currentRev != expectedRev) {
      throw CasConflict(path);
    }
    writes++;
    bytesWritten += bytes.length;
    files[path] = bytes;
    final rev = ++_revCounter;
    _revs[path] = rev;
    if (commitThenConflictNextCas) {
      commitThenConflictNextCas = false;
      throw CasConflict(path);
    }
    return rev.toString();
  }

  @override
  Future<void> delete(String path) async {
    deletes++;
    files.remove(path);
    _revs.remove(path);
  }

  @override
  Future<void> deleteMany(List<String> paths) async {
    for (final p in paths) {
      await delete(p);
    }
  }

  int get fileCount => files.length;
  int get totalBytes => files.values.fold(0, (a, b) => a + b.length);

  List<String> pathsUnder(String prefix) =>
      files.keys.where((k) => k.startsWith(prefix)).toList()..sort();
}
