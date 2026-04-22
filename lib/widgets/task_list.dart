import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/planner_item.dart';
import '../models/project.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';
import 'task_item.dart';

class TaskList extends StatelessWidget {
  final void Function(PlannerItem) onItemTap;

  const TaskList({super.key, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final items = provider.currentItems;
    final isDraggable = provider.sortMode == SortMode.manual && !provider.groupByProject;

    if (items.isEmpty) {
      return const _EmptyState();
    }

    if (provider.groupByProject) {
      return _GroupedList(groups: provider.groupedItems, onItemTap: onItemTap);
    }

    if (isDraggable) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: items.length,
        onReorder: provider.reorderItems,
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          child: child,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ItemCard(
            key: ValueKey(item.id),
            item: item,
            onTap: onItemTap,
            isDraggable: true,
            index: index,
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemCard(
          key: ValueKey(item.id),
          item: item,
          onTap: onItemTap,
          isDraggable: false,
          index: index,
        );
      },
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final void Function(PlannerItem) onItemTap;

  const _GroupedList({required this.groups, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (final group in groups) {
      final project = group['project'] as Project;
      final items = group['items'] as List<PlannerItem>;

      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: project.color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: project.color.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                project.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDim,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );

      for (final item in items) {
        children.add(_ItemCard(
          key: ValueKey(item.id),
          item: item,
          onTap: onItemTap,
          isDraggable: false,
          index: 0,
        ));
      }
    }

    children.add(const SizedBox(height: 100));

    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }
}

// Wrapper that adds rounded card decoration around each TaskItem
class _ItemCard extends StatelessWidget {
  final PlannerItem item;
  final void Function(PlannerItem) onTap;
  final bool isDraggable;
  final int index;

  const _ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.isDraggable,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: TaskItem(
          item: item,
          onTap: onTap,
          isDraggable: isDraggable,
          index: index,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 64, color: AppColors.accent),
            const SizedBox(height: 20),
            const Text(
              'FOKUS PUR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
