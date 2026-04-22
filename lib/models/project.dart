import 'package:flutter/material.dart';
import '../utils/constants.dart';

class Project {
  final String id;
  final String name;
  final int colorValue; // Color.value (32-bit ARGB int)

  const Project({required this.id, required this.name, required this.colorValue});

  Color get color => Color.fromARGB(
        (colorValue >> 24) & 0xFF,
        (colorValue >> 16) & 0xFF,
        (colorValue >> 8) & 0xFF,
        colorValue & 0xFF,
      );

  Project copyWith({String? id, String? name, int? colorValue}) => Project(
        id: id ?? this.id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory Project.fromJson(Map<String, dynamic> map) => Project(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        colorValue: map['colorValue'] as int? ?? AppColors.accent.toARGB32(),
      );

  // Built-in default projects
  static const arbeit = Project(
    id: DefaultProjects.arbeitId,
    name: 'Arbeit',
    colorValue: 0xFF2563EB, // blue-600
  );

  static const privat = Project(
    id: DefaultProjects.privatId,
    name: 'Privat',
    colorValue: 0xFF16A34A, // green-600
  );
}
