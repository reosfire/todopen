/// Index that tracks per-entity modification timestamps and deletions.
///
/// Stored both remotely (on Dropbox as `/index.bin`) and locally to enable
/// efficient diffing during sync.
class SyncIndex {
  /// Entity key (e.g. `"tasks/abc-123"`) → last modified timestamp.
  Map<String, DateTime> entities;

  /// Entity key → deletion timestamp.
  Map<String, DateTime> deletions;

  SyncIndex({Map<String, DateTime>? entities, Map<String, DateTime>? deletions})
    : entities = entities ?? {},
      deletions = deletions ?? {};
}
