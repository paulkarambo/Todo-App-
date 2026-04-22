class Subtask {
  final String id;
  final String text;
  final bool completed;

  const Subtask({required this.id, required this.text, this.completed = false});

  Subtask copyWith({String? id, String? text, bool? completed}) => Subtask(
        id: id ?? this.id,
        text: text ?? this.text,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
      };

  factory Subtask.fromJson(Map<String, dynamic> map) => Subtask(
        id: map['id'] as String? ?? '',
        text: map['text'] as String? ?? '',
        completed: map['completed'] as bool? ?? false,
      );
}
