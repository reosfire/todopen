import 'dart:ui';

import 'package:todopen/utils/uuid128.dart';

class TaskList {
  Uuid128 id;
  List<Uuid128> taskIds;

  String name;
  int? colorValue;
  String? folderId;

  TaskList({
    required this.id,
    required this.taskIds,
    required this.name,
    this.colorValue,
    this.folderId,
  });

  Color? get color => colorValue != null ? Color(colorValue!) : null;
}
