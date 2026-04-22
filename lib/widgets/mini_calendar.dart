import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class MiniCalendar extends StatefulWidget {
  const MiniCalendar({super.key});

  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime.now();
  }

  void _prevMonth() => setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
      });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlannerProvider>();
    final selectedDate = provider.selectedDate;
    final today = DateTime.now();
    final days = PlannerDateUtils.calendarGridDays(_viewMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header with navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  PlannerDateUtils.formatMonthHeader(_viewMonth),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _NavBtn(icon: Icons.chevron_left_rounded, onTap: _prevMonth),
              const SizedBox(width: 4),
              _NavBtn(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Weekday headers
        Row(
          children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDim,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),

        // Day grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final day = days[index];
            final isCurrentMonth = day.month == _viewMonth.month;
            final isSelected = PlannerDateUtils.isSameDay(day, selectedDate);
            final isToday = PlannerDateUtils.isSameDay(day, today);
            final dateKey = PlannerDateUtils.toDateKey(day);
            final hasItems = provider.hasItemsOnDate(dateKey);

            return _DayCell(
              day: day,
              isCurrentMonth: isCurrentMonth,
              isSelected: isSelected,
              isToday: isToday,
              hasItems: hasItems,
              onTap: () => provider.selectDate(day),
            );
          },
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textMuted),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasItems;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = isCurrentMonth ? AppColors.textMuted : AppColors.textDim.withOpacity(0.3);
    FontWeight fontWeight = FontWeight.w400;

    if (isSelected) {
      bgColor = AppColors.accent;
      textColor = Colors.white;
      fontWeight = FontWeight.w800;
    } else if (isToday) {
      textColor = AppColors.accent;
      fontWeight = FontWeight.w700;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.accent.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: fontWeight,
              ),
            ),
            if (hasItems && !isSelected)
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.only(top: 1),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
