import 'dart:math';

String generateId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = Random().nextInt(10000).toString().padLeft(4, '0');
  return '$now$rand';
}

String formatCurrency(num value, String currency) {
  final isNegative = value < 0;
  final absolute = value.abs();
  final hasDecimals = absolute % 1 != 0;
  final fixed = hasDecimals ? absolute.toStringAsFixed(2) : absolute.toStringAsFixed(0);
  final formatted = _formatWithCommas(fixed);
  final sign = isNegative ? '-' : '';
  return '$sign$currency $formatted';
}

String _formatWithCommas(String value) {
  final parts = value.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final positionFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  if (parts.length > 1 && parts[1] != '00') {
    return '${buffer.toString()}.${parts[1]}';
  }
  return buffer.toString();
}

String formatDate(DateTime date) {
  return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
}

String formatShortDate(DateTime date) {
  const months = [
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
  final month = months[date.month - 1];
  return '${_pad(date.day)} $month';
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

String _pad(int value) => value.toString().padLeft(2, '0');
