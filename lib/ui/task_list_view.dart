import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/smart_list.dart';
import '../state/app_state.dart';
import '../utils/uuid128.dart';
import 'sectioned_task_list.dart';

class TaskListView extends StatelessWidget {
  final Uuid128 listId;
  final String? selectedTaskId;
  final void Function(Task task)? onTaskSelected;
  const TaskListView({super.key, required this.listId, this.selectedTaskId, this.onTaskSelected});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pending = state.tasksForListOrdered(listId, completedSection: false);
    final completed = state.tasksForListOrdered(listId, completedSection: true);

    return SectionedTaskList(
      sections: [
        TaskSection(tasks: pending),
        if (completed.isNotEmpty)
          TaskSection(header: 'Completed', tasks: completed),
      ],
      inputHint: 'Add a task...',
      onAddTask: (title) => _addTask(state, title),
      onReorder: (sectionIndex, oldIndex, newIndex) {
        final section = sectionIndex == 0 ? pending : completed;
        _reorderTasksInSection(state, section, oldIndex, newIndex);
      },
      selectedTaskId: selectedTaskId,
      onTaskSelected: onTaskSelected,
    );
  }

  Future<void> _addTask(AppState state, String title) async {
    final pendingTasks = state.tasksForListOrdered(
      listId,
      completedSection: false,
    );
    final currentHead = pendingTasks.isNotEmpty ? pendingTasks.first : null;

    final newTask = Task(
      id: state.newId(),
      title: title,
      createdAt: DateTime.now(),
      listId: listId,
      previousTaskId: null,
      nextTaskId: currentHead?.id,
    );

    await state.addTaskAsHead(newTask);
  }

  void _reorderTasksInSection(
    AppState state,
    List<Task> section,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < newIndex) newIndex--;

    final reordered = List<Task>.from(section);
    final task = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, task);

    state.rebuildLinkedListForTasks(reordered);
  }
}
