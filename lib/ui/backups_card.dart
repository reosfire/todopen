import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../sync/backup.dart';

/// Sync settings section listing local full backups, with restore, pin and
/// delete for each and the retention count.
class BackupsCard extends StatelessWidget {
  const BackupsCard({super.key});

  static const _keepChoices = [3, 5, 10, 20, 50];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final backups = state.backups;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Local backups',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _backupNow(context, state),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Back up now'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'A full copy of your data is saved on this device when it '
                'syncs, at most once an hour. Pinned backups are never '
                'removed automatically.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('Backups to keep'),
              trailing: DropdownButton<int>(
                value: _keepChoices.contains(state.backupKeep)
                    ? state.backupKeep
                    : null,
                hint: Text('${state.backupKeep}'),
                underline: const SizedBox.shrink(),
                items: [
                  for (final n in _keepChoices)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) {
                  if (n != null) state.setBackupKeep(n);
                },
              ),
            ),
            const Divider(height: 1),
            if (backups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No backups yet.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              for (final b in backups) _BackupTile(backup: b),
          ],
        ),
      ),
    );
  }

  Future<void> _backupNow(BuildContext context, AppState state) async {
    final before = state.backups.firstOrNull?.id;
    await state.backupNow();
    if (!context.mounted) return;
    final made = state.backups.firstOrNull?.id != before;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          made ? 'Backup saved' : 'Nothing changed since the last backup',
        ),
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  final BackupInfo backup;

  const _BackupTile({required this.backup});

  static final _date = DateFormat('d MMM yyyy, HH:mm');

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final b = backup;
    return ListTile(
      leading: Icon(b.pinned ? Icons.push_pin : Icons.history),
      title: Text(_date.format(b.createdAt)),
      subtitle: Text(
        '${_plural(b.taskCount, 'task')} · ${_plural(b.listCount, 'list')} · '
        '${_size(b.bytes)} · ${b.reason}',
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Backup actions',
        onSelected: (action) => switch (action) {
          'restore' => _restore(context, state),
          'pin' => state.setBackupPinned(b.id, !b.pinned),
          'delete' => _delete(context, state),
          _ => null,
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'restore',
            child: ListTile(
              leading: Icon(Icons.restore),
              title: Text('Restore…'),
            ),
          ),
          PopupMenuItem(
            value: 'pin',
            child: ListTile(
              leading: Icon(
                b.pinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(b.pinned ? 'Unpin' : 'Pin'),
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context, AppState state) async {
    final replaceAll = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup'),
        content: Text(
          'From ${_date.format(backup.createdAt)}.\n\n'
          'Bring back missing: re-adds tasks, lists, folders and tags that '
          'are in the backup but gone now. Nothing else changes.\n\n'
          'Replace everything: makes your data exactly as it was in the '
          'backup. Edits and new items since then are undone.\n\n'
          'Either way the restore syncs to your other devices, and your '
          'current data is backed up first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace everything'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bring back missing'),
          ),
        ],
      ),
    );
    if (replaceAll == null) return;

    String message;
    try {
      final changes = await state.restoreBackup(
        backup.id,
        replaceAll: replaceAll,
      );
      message = changes == 0
          ? 'Nothing to restore — your data already matches'
          : 'Backup restored';
    } catch (e) {
      message = 'Restore failed: $e';
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete backup?'),
        content: Text(
          'The backup from ${_date.format(backup.createdAt)} '
          'will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await state.deleteBackup(backup.id);
  }

  static String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

  static String _size(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
