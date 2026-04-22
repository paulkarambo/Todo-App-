import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/planner_item.dart';
import '../models/project.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import 'mini_calendar.dart';

const _uuid = Uuid();

class SideBar extends StatelessWidget {
  final bool persistent;
  final void Function(PlannerItem)? onItemTap;

  const SideBar({super.key, this.persistent = false, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.card,
      child: SafeArea(
        child: Column(
          children: [
            _SidebarHeader(persistent: persistent),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calendar
                    _SectionLabel('Kalender'),
                    const SizedBox(height: 10),
                    const MiniCalendar(),
                    const SizedBox(height: 20),

                    // Todos
                    _SectionLabel('Aufgaben'),
                    const SizedBox(height: 8),
                    _TodoList(persistent: persistent, onItemTap: onItemTap),
                    const SizedBox(height: 20),

                    // Projects
                    _SectionLabel('Projekte'),
                    const SizedBox(height: 10),
                    const _ProjectList(),
                    const SizedBox(height: 16),
                    const _AddProjectButton(),
                    const SizedBox(height: 20),

                    // Settings
                    _SectionLabel('Einstellungen'),
                    const SizedBox(height: 10),
                    const _SettingsSection(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _SidebarHeader extends StatelessWidget {
  final bool persistent;
  const _SidebarHeader({required this.persistent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Planner Pro',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'PERSONAL PLANNER',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDim,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (!persistent)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.textDim,
            ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: AppColors.textDim,
        letterSpacing: 2.5,
      ),
    );
  }
}

// ── Todo list ─────────────────────────────────────────────────────────────────
class _TodoList extends StatelessWidget {
  final bool persistent;
  final void Function(PlannerItem)? onItemTap;

  const _TodoList({required this.persistent, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final tasksByDate = provider.allTasksByDate;

    if (tasksByDate.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Keine Aufgaben',
          style: TextStyle(fontSize: 11, color: AppColors.textDim),
        ),
      );
    }

    final widgets = <Widget>[];
    for (final entry in tasksByDate) {
      final tasks = entry.value.where((i) => i.isTask).toList();
      if (tasks.isEmpty) continue;

      final date = PlannerDateUtils.fromDateKey(entry.key);
      final isToday = PlannerDateUtils.isSameDay(date, DateTime.now());
      final dateLabel = isToday ? 'Heute' : PlannerDateUtils.formatDayShort(date);

      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 3),
        child: Text(
          dateLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: isToday ? AppColors.accent : AppColors.textDim,
            letterSpacing: 1.5,
          ),
        ),
      ));

      for (final task in tasks) {
        widgets.add(_TodoRow(
          task: task,
          provider: provider,
          persistent: persistent,
          onItemTap: onItemTap,
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

class _TodoRow extends StatelessWidget {
  final PlannerItem task;
  final PlannerProvider provider;
  final bool persistent;
  final void Function(PlannerItem)? onItemTap;

  const _TodoRow({
    required this.task,
    required this.provider,
    required this.persistent,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final project = provider.projectById(task.projectId);

    return GestureDetector(
      onTap: () {
        final date = PlannerDateUtils.fromDateKey(task.dateKey);
        provider.selectDate(date);
        onItemTap?.call(task);
        if (!persistent) Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: project?.color ?? AppColors.textDim,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                task.text,
                style: TextStyle(
                  fontSize: 11,
                  color: task.completed ? AppColors.textDim : AppColors.textMuted,
                  decoration:
                      task.completed ? TextDecoration.lineThrough : TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (project != null) ...[
              const SizedBox(width: 4),
              Text(
                project.name,
                style: const TextStyle(fontSize: 9, color: AppColors.textDim),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Project list ──────────────────────────────────────────────────────────────
class _ProjectList extends StatelessWidget {
  const _ProjectList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final filter = provider.filterProjectId;

    return Column(
      children: [
        _ProjectButton(
          label: 'Alle Aufgaben',
          icon: Icons.list_alt_rounded,
          color: AppColors.accent,
          isActive: filter == null,
          onTap: () => provider.setFilterProject(null),
        ),
        const SizedBox(height: 4),
        ...provider.projects.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ProjectButton(
                label: p.name,
                color: p.color,
                isActive: filter == p.id,
                onTap: () => provider.setFilterProject(p.id),
              ),
            )),
      ],
    );
  }
}

class _ProjectButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ProjectButton({
    required this.label,
    this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.textMuted)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : color,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProjectButton extends StatelessWidget {
  const _AddProjectButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddProjectDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_rounded, size: 16, color: AppColors.textDim),
            SizedBox(width: 8),
            Text('Projekt hinzufügen',
                style: TextStyle(fontSize: 13, color: AppColors.textDim)),
          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int selectedColor = AppColors.projectColors[0].toARGB32();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Neues Projekt',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Projektname',
                  hintStyle: const TextStyle(color: AppColors.textDim),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'FARBE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDim,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppColors.projectColors
                    .map((c) => GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = c.toARGB32()),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: selectedColor == c.toARGB32()
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  const Text('Abbrechen', style: TextStyle(color: AppColors.textMuted)),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                context.read<PlannerProvider>().addProject(Project(
                      id: _uuid.v4(),
                      name: name,
                      colorValue: selectedColor,
                    ));
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings section ──────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsToggle(
          label: 'Textelemente',
          value: provider.showTexts,
          onChanged: provider.setShowTexts,
        ),
        _SettingsToggle(
          label: 'Unteraufgaben',
          value: provider.showSubtasks,
          onChanged: provider.setShowSubtasks,
        ),
        _SettingsToggle(
          label: 'Gruppierungen',
          value: provider.groupByProject,
          onChanged: provider.setGroupByProject,
        ),
        _SortModeRow(provider: provider),
        const SizedBox(height: 12),
        const _SettingsLabel('Standardprojekt'),
        const SizedBox(height: 6),
        _DefaultProjectPicker(provider: provider),
        const SizedBox(height: 12),
        const _SettingsLabel('Standardpriorität'),
        const SizedBox(height: 6),
        _DefaultPriorityPicker(provider: provider),
      ],
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  final String text;
  const _SettingsLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w900,
        color: AppColors.textDim,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _SortModeRow extends StatelessWidget {
  final PlannerProvider provider;
  const _SortModeRow({required this.provider});

  static const _modes = [
    (SortMode.manual, 'M'),
    (SortMode.priority, 'P'),
    (SortMode.project, 'G'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Text('Sortierung',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const Spacer(),
          ..._modes.map((entry) {
            final mode = entry.$1;
            final label = entry.$2;
            final isActive = provider.sortMode == mode;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => provider.setSortMode(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Colors.transparent : AppColors.borderSubtle,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isActive ? Colors.white : AppColors.textDim,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DefaultProjectPicker extends StatelessWidget {
  final PlannerProvider provider;
  const _DefaultProjectPicker({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: provider.defaultProjectId,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.card,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Kein Projekt',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            ...provider.projects.map((p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(p.name, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )),
          ],
          onChanged: provider.setDefaultProject,
        ),
      ),
    );
  }
}

class _DefaultPriorityPicker extends StatelessWidget {
  final PlannerProvider provider;
  const _DefaultPriorityPicker({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Priority.values.map((p) {
        final meta = priorityMeta[p.name]!;
        final isActive = provider.defaultPriority == p;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => provider.setDefaultPriority(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? Colors.transparent : AppColors.borderSubtle,
                  ),
                ),
                child: Center(
                  child: Text(
                    meta.label[0],
                    style: TextStyle(
                      fontSize: 10,
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
    );
  }
}
