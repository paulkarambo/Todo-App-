import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';
import 'mini_calendar.dart';

const _uuid = Uuid();

class SideBar extends StatelessWidget {
  /// When true (desktop), no close button is shown.
  final bool persistent;

  const SideBar({super.key, this.persistent = false});

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
                    const SizedBox(height: 24),

                    // Projects
                    _SectionLabel('Projekte'),
                    const SizedBox(height: 10),
                    const _ProjectList(),
                    const SizedBox(height: 16),
                    const _AddProjectButton(),
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

class _SidebarHeader extends StatelessWidget {
  final bool persistent;
  const _SidebarHeader({required this.persistent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Planner Pro',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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

class _ProjectList extends StatelessWidget {
  const _ProjectList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final filter = provider.filterProjectId;

    return Column(
      children: [
        // "All tasks" button
        _ProjectButton(
          label: 'Alle Aufgaben',
          icon: Icons.list_alt_rounded,
          color: AppColors.accent,
          isActive: filter == null,
          onTap: () => provider.setFilterProject(null),
        ),
        const SizedBox(height: 4),
        // Per-project buttons
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
          border: Border.all(
              color: AppColors.borderSubtle, style: BorderStyle.solid),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_rounded, size: 16, color: AppColors.textDim),
            SizedBox(width: 8),
            Text(
              'Projekt hinzufügen',
              style:
                  TextStyle(fontSize: 13, color: AppColors.textDim),
            ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Neues Projekt',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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
                                  ? Border.all(
                                      color: Colors.white, width: 2.5)
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
              child: const Text('Abbrechen',
                  style: TextStyle(color: AppColors.textMuted)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
