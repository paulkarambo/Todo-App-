import '../utils/constants.dart';
import 'subtask.dart';

enum ItemType { task, note }

class PlannerItem {
  final String id;
  final ItemType type;
  final String text; // task title
  final String content; // note markdown
  final bool completed;
  final Priority priority;
  final String? projectId;
  final String notes;
  final List<Subtask> subtasks;
  final int sortOrder;
  final String dateKey; // 'yyyy-MM-dd'

  const PlannerItem({
    required this.id,
    required this.type,
    this.text = '',
    this.content = '',
    this.completed = false,
    this.priority = Priority.low,
    this.projectId,
    this.notes = '',
    this.subtasks = const [],
    this.sortOrder = 0,
    required this.dateKey,
  });

  bool get isTask => type == ItemType.task;
  bool get isNote => type == ItemType.note;

  PlannerItem copyWith({
    String? id,
    ItemType? type,
    String? text,
    String? content,
    bool? completed,
    Priority? priority,
    Object? projectId = _sentinel,
    String? notes,
    List<Subtask>? subtasks,
    int? sortOrder,
    String? dateKey,
  }) =>
      PlannerItem(
        id: id ?? this.id,
        type: type ?? this.type,
        text: text ?? this.text,
        content: content ?? this.content,
        completed: completed ?? this.completed,
        priority: priority ?? this.priority,
        projectId: projectId == _sentinel ? this.projectId : projectId as String?,
        notes: notes ?? this.notes,
        subtasks: subtasks ?? this.subtasks,
        sortOrder: sortOrder ?? this.sortOrder,
        dateKey: dateKey ?? this.dateKey,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type == ItemType.task ? 'task' : 'note',
        'text': text,
        'content': content,
        'completed': completed,
        'priority': priority.name,
        'projectId': projectId,
        'notes': notes,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'sortOrder': sortOrder,
        'dateKey': dateKey,
      };

  factory PlannerItem.fromJson(Map<String, dynamic> map) => PlannerItem(
        id: map['id'] as String? ?? '',
        type: map['type'] == 'note' ? ItemType.note : ItemType.task,
        text: map['text'] as String? ?? '',
        content: map['content'] as String? ?? '',
        completed: map['completed'] as bool? ?? false,
        priority: PriorityExt.fromString(map['priority'] as String?),
        projectId: map['projectId'] as String?,
        notes: map['notes'] as String? ?? '',
        subtasks: (map['subtasks'] as List<dynamic>?)
                ?.map((e) => Subtask.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        sortOrder: map['sortOrder'] as int? ?? 0,
        dateKey: map['dateKey'] as String? ?? '',
      );
}

// Sentinel for nullable copyWith fields
const _sentinel = Object();
