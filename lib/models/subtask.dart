import '../utils/constants.dart';

class Subtask {
  final String id;
  final String text;
  final bool completed;
  final Priority priority;
  final String notes;

  const Subtask({
    required this.id,
    required this.text,
    this.completed = false,
    this.priority = Priority.low,
    this.notes = '',
  });

  Subtask copyWith({
    String? id,
    String? text,
    bool? completed,
    Priority? priority,
    String? notes,
  }) =>
      Subtask(
        id: id ?? this.id,
        text: text ?? this.text,
        completed: completed ?? this.completed,
        priority: priority ?? this.priority,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
        'priority': priority.name,
        'notes': notes,
      };

  factory Subtask.fromJson(Map<String, dynamic> map) => Subtask(
        id: map['id'] as String? ?? '',
        text: map['text'] as String? ?? '',
        completed: map['completed'] as bool? ?? false,
        priority: PriorityExt.fromString(map['priority'] as String?),
        notes: map['notes'] as String? ?? '',
      );
}
