// Profiling entrypoint (not shipped). Seeds a large dataset and exposes
// scripted scenarios to a browser driver via `window.perf*`.
import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:todopen/main.dart';
import 'package:todopen/models/folder.dart';
import 'package:todopen/models/tag.dart';
import 'package:todopen/models/task.dart';
import 'package:todopen/models/task_list.dart';
import 'package:todopen/state/app_state.dart';

@JS('globalThis')
external JSObject get _global;

extension on JSObject {
  external set perfSeed(JSFunction f);
  external set perfRun(JSFunction f);
  external set perfFrames(JSFunction f);
}

final _timings = <FrameTiming>[];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
  final state = AppState();
  unawaited(state.init());
  runApp(ChangeNotifierProvider.value(value: state, child: const TodopenApp()));

  _global.perfSeed = ((JSNumber n) => _seed(
    state,
    n.toDartInt,
  ).then((v) => v.toJS).toJS).toJS;
  _global.perfRun = ((JSString s) => _run(
    state,
    s.toDart,
  ).then((v) => v.toJS).toJS).toJS;
  // Start/stop a frame recording window; returns stats as JSON string.
  _global.perfFrames = ((JSBoolean start) {
    if (start.toDart) {
      _timings.clear();
      return ''.toJS;
    }
    return _frameStats().toJS;
  }).toJS;
}

String _frameStats() {
  if (_timings.isEmpty) return '{"frames":0}';
  final b = _timings.map((t) => t.buildDuration.inMicroseconds / 1000).toList()
    ..sort();
  final r = _timings.map((t) => t.rasterDuration.inMicroseconds / 1000).toList()
    ..sort();
  double p(List<double> l, double q) =>
      l[min(l.length - 1, (l.length * q).floor())];
  double avg(List<double> l) => l.reduce((a, b) => a + b) / l.length;
  String f(double v) => v.toStringAsFixed(2);
  return '{"frames":${b.length},'
      '"buildAvg":${f(avg(b))},"buildP95":${f(p(b, .95))},"buildMax":${f(b.last)},'
      '"rasterAvg":${f(avg(r))},"rasterP95":${f(p(r, .95))},"rasterMax":${f(r.last)}}';
}

Future<void> _waitLoaded(AppState s) async {
  while (s.loading) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<String> _seed(AppState s, int taskCount) async {
  await _waitLoaded(s);
  if (s.tasks.length >= taskCount) return 'already ${s.tasks.length}';
  final rnd = Random(42);
  final sw = Stopwatch()..start();
  final folders = <Folder>[];
  for (var i = 0; i < 3; i++) {
    final f = Folder(id: s.newId(), name: 'Folder $i');
    await s.addFolder(f);
    folders.add(f);
  }
  final lists = [s.lists.first];
  for (var i = 0; i < 14; i++) {
    final l = TaskList(
      id: s.newId(),
      name: 'List $i',
      colorValue: 0xFF000000 | rnd.nextInt(0xFFFFFF),
      folderId: i < 6 ? folders[i % 3].id : null,
    );
    await s.addList(l);
    lists.add(l);
  }
  final tags = <Tag>[];
  for (var i = 0; i < 12; i++) {
    final t = Tag(
      id: s.newId(),
      name: 'tag$i',
      colorValue: 0xFF000000 | rnd.nextInt(0xFFFFFF),
    );
    await s.addTag(t);
    tags.add(t);
  }
  final now = DateTime.now();
  const words = [
    'buy',
    'call',
    'write',
    'review',
    'fix',
    'plan',
    'email',
    'read',
    'milk',
    'report',
    'docs',
    'bug',
    'meeting',
    'garden',
    'car',
    'tax',
  ];
  for (var i = 0; i < taskCount; i++) {
    // Half of everything lands in the first list, which is what opens.
    final list = i.isEven
        ? lists.first
        : lists[1 + rnd.nextInt(lists.length - 1)];
    final title = List.generate(
      2 + rnd.nextInt(4),
      (_) => words[rnd.nextInt(words.length)],
    ).join(' ');
    await s.addTask(
      Task(
        id: s.newId(),
        title: '$title #$i',
        notes: rnd.nextInt(5) == 0 ? 'Some notes about $title' : '',
        createdAt: now,
        listId: list.id,
        isCompleted: rnd.nextInt(5) == 0,
        scheduledDate: rnd.nextInt(4) == 0
            ? DateTime(now.year, now.month, now.day + rnd.nextInt(14) - 4)
            : null,
        tagIds: {
          if (rnd.nextInt(3) == 0) tags[rnd.nextInt(tags.length)].id,
          if (rnd.nextInt(6) == 0) tags[rnd.nextInt(tags.length)].id,
        },
      ),
    );
    if (i % 100 == 0) await Future<void>.delayed(Duration.zero);
  }
  return 'seeded ${s.tasks.length} in ${sw.elapsedMilliseconds}ms';
}

/// Runs one scripted scenario, awaiting a frame after every mutation, and
/// returns the mean synchronous cost of the mutation call itself.
Future<String> _run(AppState s, String name) async {
  await _waitLoaded(s);
  final inbox = s.lists.first.id;
  const n = 40;
  final sync = Stopwatch();
  Future<void> step(FutureOr<void> Function() f) async {
    sync.start();
    final r = f();
    sync.stop();
    await r;
    await WidgetsBinding.instance.endOfFrame;
  }

  switch (name) {
    case 'toggle':
      for (var i = 0; i < n; i++) {
        final t = s.tasksForListOrdered(inbox, completedSection: false)[i % 5];
        await step(() => s.toggleTask(t));
        final back = s.taskById(t.id)!;
        await step(() => s.toggleTask(back));
      }
    case 'rename':
      for (var i = 0; i < n; i++) {
        final t = s.tasksForListOrdered(inbox, completedSection: false)[i % 7];
        t.title = '${t.title}x';
        await step(() => s.updateTask(t));
      }
    case 'reorder':
      for (var i = 0; i < n; i++) {
        final pending = s.tasksForListOrdered(inbox, completedSection: false);
        await step(() => s.reorderTask(pending[0], pending[3], pending[4]));
      }
    case 'add':
      for (var i = 0; i < n; i++) {
        await step(
          () => s.addTask(
            Task(
              id: s.newId(),
              title: 'new $i',
              createdAt: DateTime.now(),
              listId: inbox,
            ),
          ),
        );
      }
    case 'idle':
      // Rebuild with no data change: what a sync that pulls nothing, or an
      // auth notify, costs.
      for (var i = 0; i < n; i++) {
        await step(() {
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          s.notifyListeners();
        });
      }
  }
  final perOp =
      sync.elapsedMicroseconds / 1000 / (name == 'toggle' ? 2 * n : n);
  return '{"syncMsPerOp":${perOp.toStringAsFixed(2)}}';
}
