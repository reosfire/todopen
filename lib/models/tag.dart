import 'package:flutter/material.dart';
import '../utils/uuid128.dart';

class Tag {
  Uuid128 id;
  String name;
  int colorValue;

  Tag({required this.id, required this.name, this.colorValue = 0xFF42A5F5});

  Color get color => Color(colorValue);
}
