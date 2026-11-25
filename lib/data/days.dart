/// Calendar days as plain integers: the number of days since 1 Jan 1970 in
/// the local calendar. Day maths stays exact (no hours, no daylight saving),
/// and a set of ints is cheap to store and compare.
abstract final class Days {
  static int of(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  static int today([DateTime? now]) => of(now ?? DateTime.now());

  static DateTime date(int day) => DateTime.fromMillisecondsSinceEpoch(day * Duration.millisecondsPerDay, isUtc: true);

  /// 1 = Monday … 7 = Sunday, as [DateTime.weekday].
  static int weekday(int day) => date(day).weekday;

  /// The Monday on or before [day]. Weeks start on Monday.
  static int weekStart(int day) => day - (weekday(day) - 1);

  static const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const weekdayLetter = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const monthLong = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "Wed 25 Nov".
  static String label(int day) {
    final d = date(day);
    return '${weekdayShort[d.weekday - 1]} ${d.day} ${monthShort[d.month - 1]}';
  }

  /// "25 Nov".
  static String short(int day) {
    final d = date(day);
    return '${d.day} ${monthShort[d.month - 1]}';
  }

  /// "Today", "Yesterday", or "Mon 23 Nov".
  static String relative(int day, int today) => switch (today - day) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => label(day),
  };
}
