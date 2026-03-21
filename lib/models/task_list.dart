import 'dart:ui';
import '../utils/uuid128.dart';

class TaskList {
  Uuid128 id;
  String name;
  int? colorValue;
  Uuid128? folderId;
  int order;

  TaskList({
    required this.id,
    required this.name,
    this.colorValue,
    this.folderId,
    this.order = 0,
  });

  Color? get color => colorValue != null ? Color(colorValue!) : null;
}
