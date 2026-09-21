import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../services/dropbox_service.dart';
import 'engine/remote_store.dart';

/// [RemoteStore] backed by the Dropbox HTTP API.
///
/// The interesting part is [compareAndSwap]: Dropbox's
/// `mode: {".tag": "update", "update": "<rev>"}` writes only if the file's
/// rev still matches, and returns a `conflict` error otherwise. That gives a
/// genuine compare-and-swap, which is what lets two devices share one
/// manifest without a server of our own.
class DropboxStore implements RemoteStore {
  final DropboxService _dropbox;

  /// Bounded concurrency: Dropbox rate-limits aggressively, and a burst of
  /// parallel reads on a cold start is the fastest way to earn a 429.
  static const _maxConcurrentReads = 8;

  DropboxStore(this._dropbox);

  @override
  Future<RemoteFile?> read(String path) async {
    final result = await _dropbox.downloadWithRev(path);
    if (result == null) return null;
    return RemoteFile(result.bytes, result.rev);
  }

  @override
  Future<List<Uint8List?>> readMany(List<String> paths) async {
    if (paths.isEmpty) return const [];
    final out = List<Uint8List?>.filled(paths.length, null);
    var next = 0;

    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= paths.length) return;
        try {
          out[i] = await _dropbox.downloadBinaryFile(paths[i]);
        } catch (e) {
          // A missing or unreadable file is reported as null; the caller
          // decides whether that is fatal. Segments can legitimately vanish
          // when another device compacts mid-read.
          debugPrint('readMany: ${paths[i]} failed: $e');
        }
      }
    }

    final workers = List.generate(
      paths.length < _maxConcurrentReads ? paths.length : _maxConcurrentReads,
      (_) => worker(),
    );
    await Future.wait(workers);
    return out;
  }

  @override
  Future<void> writeNew(String path, Uint8List bytes) =>
      _dropbox.uploadBinaryFile(path, bytes);

  @override
  Future<void> overwrite(String path, Uint8List bytes) =>
      _dropbox.uploadBinaryFile(path, bytes);

  @override
  Future<String> compareAndSwap(
    String path,
    Uint8List bytes,
    String? expectedRev,
  ) async {
    final rev = await _dropbox.uploadConditional(path, bytes, expectedRev);
    if (rev == null) throw CasConflict(path);
    return rev;
  }

  @override
  Future<void> delete(String path) => _dropbox.deleteFile(path);

  @override
  Future<void> deleteMany(List<String> paths) async {
    if (paths.isEmpty) return;
    await _dropbox.deleteBatch(paths);
  }
}

/// Bytes plus the Dropbox rev that identifies this exact version.
class RevisionedBytes {
  final Uint8List bytes;
  final String rev;
  const RevisionedBytes(this.bytes, this.rev);
}

/// Dropbox API calls the sync engine needs beyond what [DropboxService]
/// already offered.
extension DropboxSyncApi on DropboxService {
  /// Download a file along with its rev, so a later write can CAS on it.
  ///
  /// The rev arrives in the `Dropbox-API-Result` response header rather than
  /// the body.
  Future<RevisionedBytes?> downloadWithRev(String remotePath) async {
    final response = await sendAuthorized(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      extraHeaders: {
        'Dropbox-API-Arg': jsonEncode({'path': remotePath}),
      },
    );

    if (response.statusCode == 409) return null; // not found
    if (response.statusCode != 200) {
      throw Exception(
        'Dropbox download failed (${response.statusCode}): ${response.body}',
      );
    }

    final meta = response.headers['dropbox-api-result'];
    final rev = meta != null
        ? (jsonDecode(meta) as Map<String, dynamic>)['rev'] as String?
        : null;
    if (rev == null) {
      throw Exception('Dropbox download returned no rev for $remotePath');
    }
    return RevisionedBytes(response.bodyBytes, rev);
  }

  /// Conditional upload. Returns the new rev, or null when the CAS failed.
  ///
  /// [expectedRev] of null means "the file must not exist yet", expressed as
  /// `mode: add` with `autorename: false`, which errors if it does.
  Future<String?> uploadConditional(
    String remotePath,
    Uint8List bytes,
    String? expectedRev,
  ) async {
    final mode = expectedRev == null
        ? {'.tag': 'add'}
        : {'.tag': 'update', 'update': expectedRev};

    final response = await sendAuthorized(
      Uri.parse('https://content.dropboxapi.com/2/files/upload'),
      extraHeaders: {
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': jsonEncode({
          'path': remotePath,
          'mode': mode,
          'autorename': false,
          'mute': true,
        }),
      },
      body: bytes,
      // A CAS failure is an expected outcome, not a transient fault, so it
      // must not be retried with the same stale rev.
      retryOn409: false,
    );

    if (response.statusCode == 409) {
      // Either a rev mismatch or the file already existed. Both mean the
      // caller must re-read and rebase.
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Dropbox conditional upload failed '
        '(${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rev = body['rev'] as String?;
    if (rev == null) {
      throw Exception('Dropbox upload returned no rev for $remotePath');
    }
    return rev;
  }

  /// Delete several paths in one request.
  ///
  /// Dropbox runs this asynchronously and returns a job id; we do not wait
  /// for it, because this is only garbage collection.
  Future<void> deleteBatch(List<String> paths) async {
    final response = await sendAuthorized(
      Uri.parse('https://api.dropboxapi.com/2/files/delete_batch'),
      extraHeaders: {'Content-Type': 'application/json'},
      body: utf8.encode(
        jsonEncode({
          'entries': [
            for (final p in paths) {'path': p},
          ],
        }),
      ),
    );
    if (response.statusCode != 200) {
      debugPrint(
        'delete_batch failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
