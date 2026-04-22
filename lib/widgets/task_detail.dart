import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/planner_item.dart';
import '../models/subtask.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';

const _uuid = Uuid();

class TaskDetail extends StatefulWidget {
  final PlannerItem item;

  const TaskDetail({super.key, required this.item});

  @override
  State<TaskDetail> createState() => _TaskDetailState();
}

class _TaskDetailState extends State<TaskDetail> {
  late PlannerItem _item;
  late TextEditingController _titleCtrl;
  late TextEditingController _notesCtrl;
  late List<TextEditingController> _subtaskCtrls;
  bool _notePreview = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _titleCtrl = TextEditingController(
        text: _item.isTask ? _item.text : _item.content);
    _notesCtrl = TextEditingController(text: _item.notes);
    _subtaskCtrls = _item.subtasks
        .map((s) => TextEditingController(text: s.text))
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _subtaskCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateTitle(String v) {
    setState(() {
      _item = _item.isTask
          ? _item.copyWith(text: v)
          : _item.copyWith(content: v);
    });
  }

  void _save() {
    final provider = context.read<PlannerProvider>();
    final updated = _item.isTask
        ? _item.copyWith(text: _titleCtrl.text, notes: _notesCtrl.text)
        : _item.copyWith(content: _titleCtrl.text);
    provider.updateItem(updated);
    Navigator.of(context).pop();
  }

  void _delete() {
    final provider = context.read<PlannerProvider>();
    provider.deleteItem(_item.id, _item.dateKey);
    Navigator.of(context).pop();
  }

  void _addSubtask() {
    final newSub = Subtask(id: _uuid.v4(), text: '');
    setState(() {
      _item = _item.copyWith(subtasks: [..._item.subtasks, newSub]);
      _subtaskCtrls.add(TextEditingController());
    });
    final provider = context.read<PlannerProvider>();
    provider.addSubtask(_item.id, _item.dateKey, newSub);
  }

  void _updateSubtask(int index, String text) {
    final updated = _item.subtasks[index].copyWith(text: text);
    setState(() {
      _item = _item.copyWith(
        subtasks: [..._item.subtasks]..[index] = updated,
      );
    });
    final provider = context.read<PlannerProvider>();
    provider.updateSubtask(_item.id, _item.dateKey, updated);
  }

  void _deleteSubtask(int index) {
    final subId = _item.subtasks[index].id;
    setState(() {
      _item = _item.copyWith(
        subtasks: [..._item.subtasks]..removeAt(index),
      );
      _subtaskCtrls.removeAt(index).dispose();
    });
    final provider = context.read<PlannerProvider>();
    provider.deleteSubtask(_item.id, _item.dateKey, subId);
  }

  void _toggleSubtask(int index) {
    final sub = _item.subtasks[index];
    final updated = sub.copyWith(completed: !sub.completed);
    setState(() {
      _item = _item.copyWith(
        subtasks: [..._item.subtasks]..[index] = updated,
      );
    });
    final provider = context.read<PlannerProvider>();
    provider.toggleSubtask(_item.id, _item.dateKey, sub.id);
  }

  void _setPriority(Priority p) {
    setState(() => _item = _item.copyWith(priority: p));
    final provider = context.read<PlannerProvider>();
    provider.updateItem(_item.copyWith(priority: p));
  }

  void _setProject(String? id) {
    setState(() => _item = _item.copyWith(projectId: id));
    final provider = context.read<PlannerProvider>();
    provider.updateItem(_item.copyWith(projectId: id));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Text(
                'KONFIGURATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textDim,
                iconSize: 22,
              ),
            ],
          ),
        ),

        // Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                _Label('Bezeichnung'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _titleCtrl,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(hintText: 'Bezeichnung...'),
                    onChanged: _updateTitle,
                  ),
                ),
                const SizedBox(height: 24),

                if (_item.isTask) ...[
                  // Priority + Project row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Priorität'),
                            const SizedBox(height: 8),
                            Row(
                              children: Priority.values.map((p) {
                                final meta = priorityMeta[p.name]!;
                                final isActive = _item.priority == p;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: GestureDetector(
                                      onTap: () => _setPriority(p),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? AppColors.accent
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isActive
                                                ? Colors.transparent
                                                : AppColors.borderSubtle,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            meta.label[0],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: isActive
                                                  ? Colors.white
                                                  : AppColors.textDim,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Projekt'),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _item.projectId,
                                  isExpanded: true,
                                  dropdownColor: AppColors.card,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Kein Projekt',
                                          style: TextStyle(
                                              color: AppColors.textMuted)),
                                    ),
                                    ...provider.projects.map((p) =>
                                        DropdownMenuItem<String?>(
                                          value: p.id,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: p.color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(p.name),
                                            ],
                                          ),
                                        )),
                                  ],
                                  onChanged: _setProject,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Subtasks
                  Row(
                    children: [
                      _Label('Unteraufgaben'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addSubtask,
                        icon: const Icon(Icons.add_rounded,
                            size: 16, color: AppColors.accent),
                        label: const Text(
                          'HINZUFÜGEN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: _item.subtasks.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'KEINE SUBTASKS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDim,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(_item.subtasks.length, (i) {
                              final sub = _item.subtasks[i];
                              return _SubtaskRow(
                                controller: _subtaskCtrls[i],
                                completed: sub.completed,
                                onToggle: () => _toggleSubtask(i),
                                onChanged: (v) => _updateSubtask(i, v),
                                onDelete: () => _deleteSubtask(i),
                              );
                            }),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  _Label('Notizen & Details',
                      color: AppColors.accent),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _notesCtrl,
                      maxLines: 6,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6),
                      decoration: const InputDecoration(
                        hintText: 'Vertiefe deine Planung hier...',
                        hintStyle:
                            TextStyle(color: AppColors.borderSubtle, fontSize: 14),
                      ),
                    ),
                  ),
                ] else ...[
                  // Note: markdown editor + preview toggle
                  Row(
                    children: [
                      _Label('Markdown-Inhalt'),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            setState(() => _notePreview = !_notePreview),
                        child: Text(
                          _notePreview ? 'BEARBEITEN' : 'VORSCHAU',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(minHeight: 160),
                    child: _notePreview
                        ? MarkdownBody(
                            data: _titleCtrl.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.6),
                              h1: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                              h2: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                              h3: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                              strong: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700),
                              listBullet: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 14),
                            ),
                          )
                        : TextField(
                            controller: _titleCtrl,
                            maxLines: null,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.6,
                                fontFamily: 'monospace'),
                            decoration: const InputDecoration(
                              hintText: 'Markdown schreiben...',
                              hintStyle: TextStyle(
                                  color: AppColors.borderSubtle, fontSize: 14),
                            ),
                          ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'LÖSCHEN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 8,
                  shadowColor: AppColors.accent.withValues(alpha: 0.4),
                ),
                child: const Text(
                  'FERTIGSTELLEN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;

  const _Label(this.text, {this.color = AppColors.textDim});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 2,
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  final TextEditingController controller;
  final bool completed;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const _SubtaskRow({
    required this.controller,
    required this.completed,
    required this.onToggle,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Checkbox(
              value: completed,
              onChanged: (_) => onToggle(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  fontSize: 13,
                  color: completed
                      ? AppColors.textDim
                      : AppColors.textSecondary,
                  decoration: completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
                decoration: const InputDecoration(
                  hintText: 'Was ist zu tun?',
                  hintStyle:
                      TextStyle(color: AppColors.textDim, fontSize: 13),
                ),
                onChanged: onChanged,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppColors.textDim,
              hoverColor: AppColors.danger.withValues(alpha: 0.1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
