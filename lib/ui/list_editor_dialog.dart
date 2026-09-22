import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_list.dart';
import '../state/app_state.dart';
import '../utils/uuid128.dart';
import 'color_picker.dart';

class ListEditorDialog extends StatefulWidget {
  final TaskList? taskList;
  const ListEditorDialog({super.key, this.taskList});

  @override
  State<ListEditorDialog> createState() => _ListEditorDialogState();
}

class _ListEditorDialogState extends State<ListEditorDialog> {
  late final TextEditingController _nameCtrl;
  Uuid128? _folderId;
  int? _colorValue;

  bool get _isEditing => widget.taskList != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.taskList?.name ?? '');
    _folderId = widget.taskList?.folderId;
    _colorValue = widget.taskList?.colorValue;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return AlertDialog(
      title: Text(_isEditing ? 'Edit List' : 'New List'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Uuid128?>(
              initialValue: _folderId,
              decoration: const InputDecoration(
                labelText: 'Folder',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<Uuid128?>(
                  value: null,
                  child: Text('None'),
                ),
                ...state.folders.map(
                  (f) => DropdownMenuItem<Uuid128?>(
                    value: f.id,
                    child: Text(f.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _folderId = v),
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            const SizedBox(height: 8),
            ColorPickerField(
              value: _colorValue,
              allowNoColor: true,
              onChanged: (c) => setState(() => _colorValue = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final state = context.read<AppState>();
            if (_isEditing) {
              final list = widget.taskList!;
              list.name = name;
              list.folderId = _folderId;
              list.colorValue = _colorValue;
              state.updateList(list);
            } else {
              state.addList(
                TaskList(
                  id: state.newId(),
                  name: name,
                  folderId: _folderId,
                  colorValue: _colorValue,
                ),
              );
            }
            Navigator.pop(context);
          },
          child: Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
