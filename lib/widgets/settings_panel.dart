import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';

void showSettingsPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<PlannerProvider>(),
      child: const SettingsPanel(),
    ),
  );
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => ColoredBox(
        color: AppColors.card,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.textDim,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Einstellungen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textDim,
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            Flexible(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Ansicht'),
                    const SizedBox(height: 8),
                    _SettingsToggle(
                      label: 'Textelemente anzeigen',
                      value: provider.showTexts,
                      onChanged: provider.setShowTexts,
                    ),
                    _SettingsToggle(
                      label: 'Unteraufgaben anzeigen',
                      value: provider.showSubtasks,
                      onChanged: provider.setShowSubtasks,
                    ),
                    _SettingsToggle(
                      label: 'Nach Projekt gruppieren',
                      value: provider.groupByProject,
                      onChanged: provider.setGroupByProject,
                    ),
                    const SizedBox(height: 20),
                    const _Label('Sortierung'),
                    const SizedBox(height: 10),
                    _SortModeRow(provider: provider),
                    const SizedBox(height: 20),
                    const _Label('Standardwerte'),
                    const SizedBox(height: 12),
                    const _SubLabel('Projekt'),
                    const SizedBox(height: 6),
                    _DefaultProjectPicker(provider: provider),
                    const SizedBox(height: 12),
                    const _SubLabel('Priorität'),
                    const SizedBox(height: 6),
                    _DefaultPriorityPicker(provider: provider),
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

// ── Labels ────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);

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

// ── Toggle ────────────────────────────────────────────────────────────────────
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
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          ),
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

// ── Sort mode ─────────────────────────────────────────────────────────────────
class _SortModeRow extends StatelessWidget {
  final PlannerProvider provider;
  const _SortModeRow({required this.provider});

  static const _modes = [
    (SortMode.manual, 'Manuell', 'M'),
    (SortMode.priority, 'Priorität', 'P'),
    (SortMode.project, 'Projekt', 'G'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _modes.map((entry) {
        final mode = entry.$1;
        final modeLabel = entry.$2;
        final modeShort = entry.$3;
        final isActive = provider.sortMode == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => provider.setSortMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? Colors.transparent : AppColors.borderSubtle,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      modeShort,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isActive ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      modeLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: isActive ? Colors.white70 : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Default project picker ────────────────────────────────────────────────────
class _DefaultProjectPicker extends StatelessWidget {
  final PlannerProvider provider;
  const _DefaultProjectPicker({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: provider.defaultProjectId,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.card,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Kein Projekt',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ),
            ...provider.projects.map((p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration:
                            BoxDecoration(color: p.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(p.name, style: const TextStyle(fontSize: 14)),
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

// ── Default priority picker ───────────────────────────────────────────────────
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
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => provider.setDefaultPriority(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? Colors.transparent : AppColors.borderSubtle,
                  ),
                ),
                child: Center(
                  child: Text(
                    meta.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
