import 'dart:math' as math;

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _monthsShort = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String formatDateTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} $h:$min';
}

String formatMonthYear(DateTime date) {
  return '${_capitalize(_months[date.month - 1])} ${date.year}';
}

String formatMonthShort(DateTime date) => _monthsShort[date.month - 1];

String formatMoney(num value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final sign = negative ? '-' : '';
  return 'RD\$ $sign$buffer.${parts[1]}';
}

String formatKwh(num value) {
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return '$text kWh';
}

String formatPercent(num value, {bool signed = true}) {
  final rounded = (value * 10).round() / 10;
  final absText = rounded.abs().toStringAsFixed(1);
  if (!signed) return '$absText%';
  if (rounded > 0) return '+$absText%';
  if (rounded < 0) return '-$absText%';
  return '0.0%';
}

double percentChange(num current, num previous) {
  if (previous == 0) return 0;
  return (current - previous) / previous * 100;
}

double trendSlope(List<double> values) {
  final n = values.length;
  if (n < 2) return 0;
  var sumX = 0.0;
  var sumY = 0.0;
  var sumXY = 0.0;
  var sumXX = 0.0;
  for (var i = 0; i < n; i++) {
    sumX += i;
    sumY += values[i];
    sumXY += i * values[i];
    sumXX += i * i;
  }
  final denom = n * sumXX - sumX * sumX;
  if (denom == 0) return 0;
  return (n * sumXY - sumX * sumY) / denom;
}

String greetingFor(DateTime date) {
  if (date.hour < 12) return 'Buenos días';
  if (date.hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

String firstName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? fullName : parts.first;
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

double round2(double value) => (value * 100).roundToDouble() / 100.0;

int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

bool isPastDue(DateTime due, DateTime now) {
  final dueDay = DateTime(due.year, due.month, due.day);
  final today = DateTime(now.year, now.month, now.day);
  return today.isAfter(dueDay);
}

String normalizeText(String value) {
  const map = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final char in value.toLowerCase().split('')) {
    buffer.write(map[char] ?? char);
  }
  return buffer.toString();
}

/// Reparte un total mensual en valores diarios deterministas.
List<double> splitDaily(DateTime month, double total, int salt) {
  final count = daysInMonth(month);
  final weights = <double>[];
  for (var i = 0; i < count; i++) {
    final date = DateTime(month.year, month.month, i + 1);
    final weekend = date.weekday >= DateTime.saturday;
    final wave = 1 + 0.08 * math.sin((i + salt) / 2.15);
    final jitter = 0.96 + ((salt * 13 + i * 7) % 11) / 120;
    weights.add((weekend ? 1.14 : 0.95) * wave * jitter);
  }
  final sum = weights.fold<double>(0, (a, b) => a + b);
  final values = weights.map((w) => round2(total * w / sum)).toList();
  final diff = round2(total - values.fold<double>(0, (a, b) => a + b));
  values[values.length - 1] = round2(values.last + diff);
  return values;
}
