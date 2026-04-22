import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/planner_item.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/quick_entry_card.dart';
import '../widgets/sidebar.dart';
import '../widgets/sort_menu.dart';
import '../widgets/startup_modal.dart';
import '../widgets/task_detail.dart';
import '../widgets/task_list.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlannerProvider>();
      if (provider.needsStartupModal) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: AppColors.background.withOpacity(0.95),
          builder: (_) => const StartupModal(),
        );
      }
    });
  }

  void _openDetail(PlannerItem item) {
    final content = ChangeNotifierProvider.value(
      value: context.read<PlannerProvider>(),
      child: TaskDetail(item: item),
    );

    if (_isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.85),
        builder: (_) => Dialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          insetPadding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 560, maxHeight: 700),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: content,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          builder: (ctx, scrollCtrl) => ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            child: content,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return _DesktopLayout(onItemTap: _openDetail);
    } else {
      return _MobileLayout(
        scaffoldKey: _scaffoldKey,
        onItemTap: _openDetail,
      );
    }
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final void Function(PlannerItem) onItemTap;

  const _DesktopLayout({required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Persistent sidebar
          const SideBar(persistent: true),
          Container(width: 1, color: AppColors.borderSubtle),
          // Main content
          Expanded(
            child: Column(
              children: [
                _TopBar(onMenuTap: null),
                Expanded(child: _MainContent(onItemTap: onItemTap)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final void Function(PlannerItem) onItemTap;

  const _MobileLayout(
      {required this.scaffoldKey, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const Drawer(
        backgroundColor: AppColors.card,
        child: SideBar(persistent: false),
      ),
      body: Column(
        children: [
          _TopBar(onMenuTap: () => scaffoldKey.currentState?.openDrawer()),
          Expanded(child: _MainContent(onItemTap: onItemTap)),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const _TopBar({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final dateLabel =
        PlannerDateUtils.formatDayHeader(provider.selectedDate);
    final isToday = PlannerDateUtils.isSameDay(
        provider.selectedDate, DateTime.now());

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border:
            Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (onMenuTap != null) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded),
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Day navigation controls
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavIconBtn(
                  icon: Icons.wb_sunny_outlined,
                  tooltip: 'Heute',
                  active: isToday,
                  onTap: provider.goToToday,
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: AppColors.borderSubtle,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                ),
                _NavIconBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: provider.goToPreviousDay,
                ),
                _NavIconBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: provider.goToNextDay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final String? tooltip;

  const _NavIconBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(
            icon,
            size: 18,
            color: active ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Main Content ──────────────────────────────────────────────────────────────
class _MainContent extends StatelessWidget {
  final void Function(PlannerItem) onItemTap;

  const _MainContent({required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: const QuickEntryCard(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _ControlsBar(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: TaskList(onItemTap: onItemTap),
                    ),
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

// ── Controls Bar ──────────────────────────────────────────────────────────────
class _ControlsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Text(
            'AGENDA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textDim,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          _ToggleBtn(
            icon: Icons.text_fields_rounded,
            tooltip: 'Texte anzeigen',
            active: provider.showTexts,
            onTap: () => provider.setShowTexts(!provider.showTexts),
          ),
          const SizedBox(width: 6),
          _ToggleBtn(
            icon: Icons.checklist_rounded,
            tooltip: 'Unteraufgaben anzeigen',
            active: provider.showSubtasks,
            onTap: () => provider.setShowSubtasks(!provider.showSubtasks),
          ),
          const SizedBox(width: 6),
          _ToggleBtn(
            icon: Icons.folder_outlined,
            tooltip: 'Nach Projekt gruppieren',
            active: provider.groupByProject,
            onTap: () =>
                provider.setGroupByProject(!provider.groupByProject),
          ),
          const SizedBox(width: 6),
          const SortMenu(),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppColors.accent.withOpacity(0.5)
                  : AppColors.borderSubtle,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? AppColors.accent : AppColors.textDim,
          ),
        ),
      ),
    );
  }
}
