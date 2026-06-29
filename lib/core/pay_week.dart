import 'package:intl/intl.dart';

/// Pay week runs Saturday → Friday. Returns the Saturday that starts
/// the week containing [d].
DateTime payWeekStart(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  // Dart weekday: Mon=1..Sun=7, Sat=6.
  final delta = (date.weekday - DateTime.saturday) % 7;
  return date.subtract(Duration(days: delta));
}

/// "Jun 21 – Jun 27, 2026"
String payWeekLabel(DateTime d) {
  final start = payWeekStart(d);
  final end = start.add(const Duration(days: 6));
  final f = DateFormat('MMM d');
  return '${f.format(start)} – ${f.format(end)}, ${end.year}';
}

String payWeekKey(DateTime d) =>
    DateFormat('yyyy-MM-dd').format(payWeekStart(d));