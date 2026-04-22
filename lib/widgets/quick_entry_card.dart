import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/planner_item.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

const _uuid = Uuid();

class QuickEntryCard extends StatefulWidget {
  const QuickEntryCard({super.key});

  @override
  State<QuickEntryCard> createState() => _QuickEntryCardState();
}

class _QuickEntryCardState extends State<QuickEntryCard> {
  ItemType _type = ItemType.task;
  String? _projectId;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<PlannerProvider>();
    final dateKey = PlannerDateUtils.toDateKey(provider.selectedDate);

    final item = PlannerItem(
      id: _uuid.v4(),
      type: _type,
      text: _type == ItemType.task ? text : '',
      content: _type == ItemType.note ? text : '',
      projectId: _projectId,
      dateKey: dateKey,
      sortOrder: 0,
    );

    provider.addItem(item);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab toggle
          Row(
            children: [
              _TypeTab(
                label: 'Aufgabe',
                active: _type == ItemType.task,
                onTap: () => setState(() => _type = ItemType.task),
              ),
              const SizedBox(width: 28),
              _TypeTab(
                label: 'Notiz',
                active: _type == ItemType.note,
                onTap: () => setState(() => _type = ItemType.note),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Input field
          if (_type == ItemType.task)
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Was steht an?',
                hintStyle: TextStyle(color: AppColors.borderSubtle, fontSize: 20),
              ),
              onSubmitted: (_) => _submit(),
            )
          else
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 17,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: 'Gedanken festhalten...',
                hintStyle: TextStyle(color: AppColors.borderSubtle, fontSize: 17),
              ),
              onEditingComplete: _submit,
            ),
          const SizedBox(height: 20),

          // Bottom row
          Row(
            children: [
              // Project picker (task only)
              if (_type == ItemType.task) ...[
                _ProjectPicker(
                  projects: provider.projects,
                  value: _projectId,
                  onChanged: (v) => setState(() => _projectId = v),
                ),
                const Spacer(),
              ] else
                const Spacer(),

              // Add button
              FilledButton(
                onPressed: _controller.text.isEmpty ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  shadowColor: AppColors.accent.withOpacity(0.4),
                  disabledBackgroundColor: AppColors.accent.withOpacity(0.2),
                ),
                child: const Text(
                  'HINZUFÜGEN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TypeTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: active ? AppColors.accent : AppColors.textDim,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: active ? 40 : 0,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectPicker extends StatelessWidget {
  final List projects;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ProjectPicker({
    required this.projects,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isDense: true,
          dropdownColor: AppColors.card,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Kein Projekt'),
            ),
            ...projects.map((p) => DropdownMenuItem<String?>(
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
          onChanged: onChanged,
        ),
      ),
    );
  }
}
