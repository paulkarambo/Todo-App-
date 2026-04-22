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
  Priority _priority = Priority.low;
  bool _initialized = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<PlannerProvider>();
      _projectId = provider.defaultProjectId;
      _priority = provider.defaultPriority;
      _initialized = true;
    }
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
      priority: _type == ItemType.task ? _priority : Priority.low,
      dateKey: dateKey,
      sortOrder: 0,
    );

    provider.addItem(item);
    _controller.clear();
    setState(() {
      _priority = provider.defaultPriority;
      _projectId = provider.defaultProjectId;
    });
    _focusNode.requestFocus();
  }

  void _insertMarkdown(String prefix, [String? suffix]) {
    final text = _controller.text;
    final sel = _controller.selection;
    final suf = suffix ?? prefix;
    if (!sel.isValid || sel.isCollapsed) {
      final pos = sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;
      final newText = text.substring(0, pos) + prefix + suf + text.substring(pos);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      final newText =
          text.substring(0, sel.start) + prefix + selected + suf + text.substring(sel.end);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: sel.start + prefix.length,
          extentOffset: sel.start + prefix.length + selected.length,
        ),
      );
    }
  }

  void _insertColor(Color color) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    _insertMarkdown('<span style="color:$hex">', '</span>');
  }

  void _insertBgColor(Color color) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    _insertMarkdown('<span style="background-color:$hex">', '</span>');
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),

          // Input field
          if (_type == ItemType.task)
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Was steht an?',
                hintStyle: TextStyle(color: AppColors.borderSubtle, fontSize: 16),
              ),
              onSubmitted: (_) => _submit(),
            )
          else ...[
            _MarkdownToolbar(
              onInsert: _insertMarkdown,
              onInsertColor: _insertColor,
              onInsertBgColor: _insertBgColor,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: 'Gedanken festhalten...',
                hintStyle: TextStyle(color: AppColors.borderSubtle, fontSize: 14),
              ),
              onEditingComplete: _submit,
            ),
          ],

          // Priority picker (task only)
          if (_type == ItemType.task) ...[
            const SizedBox(height: 12),
            _PriorityPicker(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
          ],
          const SizedBox(height: 12),

          // Bottom row: project picker + add button
          Row(
            children: [
              _ProjectPicker(
                projects: provider.projects,
                value: _projectId,
                onChanged: (v) => setState(() => _projectId = v),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _controller.text.isEmpty ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  shadowColor: AppColors.accent.withValues(alpha: 0.4),
                  disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.2),
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

// ── Type tab ──────────────────────────────────────────────────────────────────
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

// ── Priority picker ───────────────────────────────────────────────────────────
class _PriorityPicker extends StatelessWidget {
  final Priority value;
  final ValueChanged<Priority> onChanged;

  const _PriorityPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Priority.values.map((p) {
        final meta = priorityMeta[p.name]!;
        final isActive = value == p;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? meta.color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? meta.color : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                meta.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isActive ? meta.color : AppColors.textDim,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Markdown toolbar ──────────────────────────────────────────────────────────
class _MarkdownToolbar extends StatelessWidget {
  final void Function(String, [String?]) onInsert;
  final void Function(Color) onInsertColor;
  final void Function(Color) onInsertBgColor;

  const _MarkdownToolbar({
    required this.onInsert,
    required this.onInsertColor,
    required this.onInsertBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _ToolbarBtn(icon: Icons.format_bold, tooltip: 'Fett', onTap: () => onInsert('**')),
          _ToolbarBtn(icon: Icons.format_italic, tooltip: 'Kursiv', onTap: () => onInsert('*')),
          _ToolbarBtn(
            icon: Icons.format_underlined,
            tooltip: 'Unterstrichen',
            onTap: () => onInsert('<u>', '</u>'),
          ),
          _ToolbarBtn(
            icon: Icons.strikethrough_s,
            tooltip: 'Durchgestrichen',
            onTap: () => onInsert('~~'),
          ),
          _ColorToolbarBtn(
            tooltip: 'Textfarbe',
            icon: Icons.format_color_text,
            onColorSelected: onInsertColor,
          ),
          _ColorToolbarBtn(
            tooltip: 'Hintergrundfarbe',
            icon: Icons.format_color_fill,
            onColorSelected: onInsertBgColor,
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ColorToolbarBtn extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final void Function(Color) onColorSelected;

  const _ColorToolbarBtn({
    required this.tooltip,
    required this.icon,
    required this.onColorSelected,
  });

  static const _colors = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF1F5F9),
  ];

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _showColorPicker(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppColors.textMuted),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tooltip.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.textDim,
            letterSpacing: 2,
          ),
        ),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors
              .map((c) => GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onColorSelected(c);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Project picker ────────────────────────────────────────────────────────────
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
