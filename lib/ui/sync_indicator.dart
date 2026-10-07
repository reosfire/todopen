import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../sync/activity_store.dart';

/// App bar status for sync: an arrow in a spinning ring while data is going
/// up or coming down, otherwise a button to sync now.
///
/// Background pushes and pulls show here too, not just a sync started by
/// hand, so it is visible when an edit has actually left the device.
class SyncIndicator extends StatelessWidget {
  final AppState state;

  const SyncIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.isSignedIn) return const SizedBox.shrink();
    return ValueListenableBuilder<SyncActivity>(
      valueListenable: state.syncActivity,
      builder: (context, activity, _) => switch (activity) {
        SyncActivity.uploading => const _Transfer(
          icon: Icons.arrow_upward,
          tooltip: 'Uploading changes…',
        ),
        SyncActivity.downloading => const _Transfer(
          icon: Icons.arrow_downward,
          tooltip: 'Downloading changes…',
        ),
        SyncActivity.idle => _idle(context),
      },
    );
  }

  Widget _idle(BuildContext context) {
    // Edits waiting to go up, e.g. while offline or signed out of Dropbox.
    final pending = state.pendingChanges;
    if (pending > 0) {
      return IconButton(
        icon: const Icon(Icons.cloud_upload_outlined),
        color: Theme.of(context).colorScheme.tertiary,
        onPressed: () => state.sync(),
        tooltip:
            '$pending unsynced change${pending == 1 ? '' : 's'} — sync now',
      );
    }
    return IconButton(
      icon: const Icon(Icons.sync),
      onPressed: () => state.sync(),
      tooltip: 'Sync',
    );
  }
}

class _Transfer extends StatelessWidget {
  final IconData icon;
  final String tooltip;

  const _Transfer({required this.icon, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    // Same footprint as an IconButton, so the app bar does not jump.
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 2, color: color),
                Icon(icon, size: 14, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
