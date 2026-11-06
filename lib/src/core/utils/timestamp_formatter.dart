import 'package:intl/intl.dart';

/// Formats message and conversation timestamps for display.
///
/// Kept as free functions rather than extension methods on [DateTime] so the
/// formatting rules are unit-testable in isolation and the locale-dependent
/// [DateFormat] instances can be cached.
abstract final class TimestampFormatter {
  static final DateFormat _time = DateFormat.jm();
  static final DateFormat _weekday = DateFormat.E();
  static final DateFormat _date = DateFormat.yMMMd();

  /// Short relative label used in the conversation list, e.g. `4:15 PM`,
  /// `Tue`, or `12 Mar 2026`.
  static String relative(DateTime timestamp, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final local = timestamp.toLocal();
    final difference = reference.difference(local);

    if (_isSameDay(local, reference)) return _time.format(local);
    if (difference.inDays < 7 && !difference.isNegative) {
      return _weekday.format(local);
    }
    return _date.format(local);
  }

  /// Clock time shown underneath a message bubble.
  static String clock(DateTime timestamp) => _time.format(timestamp.toLocal());

  /// Day separator inserted between messages sent on different days.
  static String daySeparator(DateTime timestamp, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final local = timestamp.toLocal();
    if (_isSameDay(local, reference)) return 'Today';
    if (_isSameDay(local, reference.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return _date.format(local);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
