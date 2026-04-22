import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';

class SortMenu extends StatelessWidget {
  const SortMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final isActive = provider.sortMode != SortMode.manual;

    return PopupMenuButton<String>(
      tooltip: 'Sortierung',
      offset: const Offset(0, 48),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(
          Icons.sort_rounded,
          size: 20,
          color: isActive ? Colors.white : AppColors.textDim,
        ),
      ),
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String>(
            enabled: false,
            height: 32,
            child: Text(
              'SORTIERUNG',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.textDim,
                letterSpacing: 2,
              ),
            ),
          ),
          _buildModeItem(context, provider, 'manual', 'Manuell (Drag & Drop)',
              Icons.drag_handle_rounded),
          _buildModeItem(context, provider, 'priority', 'Priorität',
              Icons.flag_outlined),
          _buildModeItem(
              context, provider, 'project', 'Projekt', Icons.folder_outlined),
          if (provider.sortMode != SortMode.manual) ...[
            const PopupMenuDivider(),
            _buildDirItem(context, provider, SortDirection.desc,
                'Absteigend', Icons.arrow_downward_rounded),
            _buildDirItem(context, provider, SortDirection.asc,
                'Aufsteigend', Icons.arrow_upward_rounded),
          ],
        ];
      },
    );
  }

  PopupMenuItem<String> _buildModeItem(
    BuildContext context,
    PlannerProvider provider,
    String modeKey,
    String label,
    IconData icon,
  ) {
    final mode = SortMode.values.firstWhere((e) => e.name == modeKey);
    final isActive = provider.sortMode == mode;
    return PopupMenuItem<String>(
      value: modeKey,
      onTap: () => provider.setSortMode(mode),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? AppColors.accent : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (isActive)
            const Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildDirItem(
    BuildContext context,
    PlannerProvider provider,
    SortDirection dir,
    String label,
    IconData icon,
  ) {
    final isActive = provider.sortDir == dir;
    return PopupMenuItem<String>(
      value: dir.name,
      onTap: () {
        if (!isActive) provider.toggleSortDirection();
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? AppColors.accent : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (isActive)
            const Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
        ],
      ),
    );
  }
}
