import 'dart:typed_data';

/// A file plus the revision token needed to compare-and-swap it.
class RemoteFile {
  final Uint8List bytes;

  /// Opaque server revision. Passing it back on write asserts "only if
  /// unchanged since I read this".
  final String rev;

  const RemoteFile(this.bytes, this.rev);
}

/// Raised when a conditional write loses the race.
///
/// The caller is expected to re-read, rebase its work on the new state and
/// retry — never to force the write.
class CasConflict implements Exception {
  final String path;
  const CasConflict(this.path);
  @override
  String toString() => 'CasConflict on $path';
}

/// The storage operations the sync engine needs.
///
/// Kept deliberately small so it can be backed by Dropbox in production and
/// by an in-memory fake in tests, including tests that simulate two devices
/// racing on the same manifest.
abstract class RemoteStore {
  /// Read a file, or null when absent.
  Future<RemoteFile?> read(String path);

  /// Read several files concurrently. Missing entries come back null.
  Future<List<Uint8List?>> readMany(List<String> paths);

  /// Create a file that must not already exist.
  ///
  /// Used for immutable segments and chunks, where overwriting would mean
  /// two devices had picked the same sequence number.
  Future<void> writeNew(String path, Uint8List bytes);

  /// Overwrite unconditionally. Only valid for content addressed by a name
  /// that already encodes its version (base chunks).
  Future<void> overwrite(String path, Uint8List bytes);

  /// Compare-and-swap. [expectedRev] of null means "must not exist".
  ///
  /// Throws [CasConflict] if the file moved on. This single conditional
  /// write is the serialisation point that makes concurrent devices safe.
  Future<String> compareAndSwap(
    String path,
    Uint8List bytes,
    String? expectedRev,
  );

  Future<void> delete(String path);

  /// Best-effort bulk delete; failures are ignored by callers doing GC.
  Future<void> deleteMany(List<String> paths);
}
