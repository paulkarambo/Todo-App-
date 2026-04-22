import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/planner_item.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';

class TaskItem extends StatelessWidget {
  final PlannerItem item;
  final void Function(PlannerItem) onTap;
  final bool isDraggable;
  final int index;

  const TaskItem({
    super.key,
    required this.item,
    required this.onTap,
    this.isDraggable = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return item.isTask
        ? _TaskRow(item: item, onTap: onTap, isDraggable: isDraggable, index: index)
        : _NoteRow(item: item, onTap: onTap);
  }
}

// ── Task row ──────────────────────────────────────────────────────────────────
class _TaskRow extends StatelessWidget {
  final PlannerItem item;
  final void Function(PlannerItem) onTap;
  final bool isDraggable;
  final int index;

  const _TaskRow(
      {required this.item, required this.onTap, this.isDraggable = false, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final priorityColor = priorityMeta[item.priority.name]!.color;
    final project = provider.projectById(item.projectId);

    return InkWell(
      onTap: () => onTap(item),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Priority indicator
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),

                // Checkbox
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: item.completed,
                    onChanged: (_) => provider.toggleCompleted(item.id, item.dateKey),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + project
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: item.completed ? AppColors.textDim : AppColors.textSecondary,
                          decoration:
                              item.completed ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (project != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: project.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              project.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDim,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Drag handle
                if (isDraggable)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.drag_handle_rounded, size: 20, color: AppColors.textDim),
                    ),
                  ),
              ],
            ),

            // Notes preview (rendered Markdown)
            if (provider.showTexts && item.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: MarkdownBody(
                  data: item.notes,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.4),
                    strong: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700),
                    listBullet: const TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                  softLineBreak: true,
                ),
              ),
            ],

            // Subtasks inline
            if (provider.showSubtasks && item.subtasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.subtasks.map((sub) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                provider.toggleSubtask(item.id, item.dateKey, sub.id),
                            child: Icon(
                              sub.completed
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 14,
                              color: sub.completed ? AppColors.textDim : AppColors.border,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.text.isEmpty ? 'Leere Unteraufgabe' : sub.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: sub.completed ? AppColors.textDim : AppColors.textMuted,
                                decoration: sub.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                fontStyle:
                                    sub.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Note row ──────────────────────────────────────────────────────────────────
class _NoteRow extends StatelessWidget {
  final PlannerItem item;
  final void Function(PlannerItem) onTap;

  const _NoteRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(item),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.article_outlined, size: 20, color: AppColors.textDim),
            const SizedBox(width: 12),
            Expanded(
              child: MarkdownBody(
                data: item.content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.6),
                  h1: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w800),
                  h2: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w700),
                  h3: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
                  strong: const TextStyle(
                      color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                  listBullet: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
