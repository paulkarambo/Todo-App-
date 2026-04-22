import 'package:intl/intl.dart';

class PlannerDateUtils {
  static String toDateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime fromDateKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  static String formatMonthHeader(DateTime d) =>
      DateFormat('MMMM yyyy', 'de_DE').format(d);

  static String formatDayHeader(DateTime d) =>
      DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(d);

  static String formatDayShort(DateTime d) =>
      DateFormat('EE, d. MMM', 'de_DE').format(d);

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Returns exactly 42 DateTime slots (6 rows × 7 cols, Mon–Sun) for the
  /// calendar grid of the given month. Slots outside the month are included
  /// so the grid is always full.
  static List<DateTime> calendarGridDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // weekday: Mon=1 ... Sun=7
    final startOffset = (firstOfMonth.weekday - 1) % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: startOffset));

    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
