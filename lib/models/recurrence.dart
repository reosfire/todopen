sealed class RecurrenceRule {
  const RecurrenceRule();

  /// Check whether a given [date] matches this rule, assuming the task
  /// was first scheduled on [startDate].
  bool occursOn(DateTime date, DateTime startDate);
  String describe();
}

class DailyRecurrence extends RecurrenceRule {
  const DailyRecurrence();

  @override
  bool occursOn(DateTime date, DateTime startDate) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    return !d.isBefore(s);
  }

  @override
  String describe() => 'Every day';
}

class EveryNDaysRecurrence extends RecurrenceRule {
  final int interval;

  const EveryNDaysRecurrence(this.interval);

  @override
  bool occursOn(DateTime date, DateTime startDate) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    if (d.isBefore(s)) return false;
    return d.difference(s).inDays % interval == 0;
  }

  @override
  String describe() => 'Every $interval days';
}

class WeeklyRecurrence extends RecurrenceRule {
  final int weekdayBits;

  const WeeklyRecurrence(this.weekdayBits);

  factory WeeklyRecurrence.fromDays(Iterable<int> days) {
    int bits = 0;
    for (final day in days) {
      bits |= (1 << day);
    }
    return WeeklyRecurrence(bits);
  }

  @override
  bool occursOn(DateTime date, DateTime startDate) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    if (d.isBefore(s)) return false;

    return (weekdayBits & (1 << d.weekday)) != 0;
  }

  @override
  String describe() {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final buffer = StringBuffer('Every ');
    bool first = true;
    for (int i = 1; i <= 7; i++) {
      if ((weekdayBits & (1 << i)) == 0) continue;

      if (!first) buffer.write(', ');
      buffer.write(names[i]);
      first = false;
    }

    return buffer.toString();
  }
}

class MonthlyRecurrence extends RecurrenceRule {
  /// Day of month (1-31).
  final int dayOfMonth;

  const MonthlyRecurrence(this.dayOfMonth);

  @override
  bool occursOn(DateTime date, DateTime startDate) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    if (d.isBefore(s)) return false;
    return d.day == dayOfMonth;
  }

  @override
  String describe() => 'Monthly on specific day ($dayOfMonth)';
}

class YearlyRecurrence extends RecurrenceRule {
  final int month;
  final int dayOfMonth;

  const YearlyRecurrence(this.month, this.dayOfMonth);

  @override
  bool occursOn(DateTime date, DateTime startDate) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    if (d.isBefore(s)) return false;
    return d.month == month && d.day == dayOfMonth;
  }

  @override
  String describe() {
    const monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Yearly on specific date (${monthNames[month]} $dayOfMonth)';
  }
}
