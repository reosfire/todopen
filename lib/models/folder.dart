import '../utils/uuid128.dart';

class Folder {
  Uuid128 id;
  String name;
  int order;

  Folder({required this.id, required this.name, this.order = 0});
}
