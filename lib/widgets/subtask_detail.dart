import 'package:flutter/material.dart';
import '../models/planner_item.dart';
import '../models/subtask.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';

class SubtaskDetailSheet extends StatefulWidget {
  final Subtask subtask;
  final String parentTaskName;
  final PlannerItem parentItem;
  final PlannerProvider provider;
  final VoidCallback onBackToParent;

  const SubtaskDetailSheet({
    super.key,
    required this.subtask,
    required this.parentTaskName,
    required this.parentItem,
    required this.provider,
    required this.onBackToParent,
  });

  @override
  State<SubtaskDetailSheet> createState() => _SubtaskDetailSheetState();
}

class _SubtaskDetailSheetState extends State<SubtaskDetailSheet> {
  late Subtask _subtask;
  late TextEditingController _textCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _subtask = widget.subtask;
    _textCtrl = TextEditingController(text: _subtask.text);
    _notesCtrl = TextEditingController(text: _subtask.notes);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = _subtask.copyWith(
      text: _textCtrl.text,
      notes: _notesCtrl.text,
    );
    widget.provider.updateSubtask(widget.parentItem.id, widget.parentItem.dateKey, updated);
    Navigator.of(context).pop();
  }

  void _delete() {
    widget.provider
        .deleteSubtask(widget.parentItem.id, widget.parentItem.dateKey, _subtask.id);
    Navigator.of(context).pop();
  }

  void _setPriority(Priority p) {
    final updated = _subtask.copyWith(priority: p);
    setState(() => _subtask = updated);
    widget.provider.updateSubtask(widget.parentItem.id, widget.parentItem.dateKey, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with breadcrumb
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onBackToParent();
                        },
                        child: Text(
                          widget.parentTaskName.isEmpty
                              ? 'Aufgabe'
                              : widget.parentTaskName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '›',
                        style: TextStyle(fontSize: 14, color: AppColors.textDim),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _subtask.text.isEmpty ? 'Unteraufgabe' : _subtask.text,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
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
          child: ColoredBox(
            color: AppColors.card,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      controller: _textCtrl,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      decoration:
                          const InputDecoration(hintText: 'Bezeichnung...'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _Label('Priorität'),
                  const SizedBox(height: 8),
                  Row(
                    children: Priority.values.map((p) {
                      final meta = priorityMeta[p.name]!;
                      final isActive = _subtask.priority == p;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => _setPriority(p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.accent : Colors.transparent,
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
                                    color: isActive ? Colors.white : AppColors.textDim,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  _Label('Notizen'),
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
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Notizen zur Unteraufgabe...',
                        hintStyle:
                            TextStyle(color: AppColors.borderSubtle, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 8,
                  shadowColor: AppColors.accent.withValues(alpha: 0.4),
                ),
                child: const Text(
                  'SPEICHERN',
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

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppColors.textDim,
        letterSpacing: 2,
      ),
    );
  }
}
