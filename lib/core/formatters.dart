import 'package:intl/intl.dart';

final peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

/// 60.0 -> "60", 4.5 -> "4.5"
String qty(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toString();