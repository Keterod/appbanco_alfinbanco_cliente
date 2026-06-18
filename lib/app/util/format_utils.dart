abstract final class FormatUtils {
  static String formatSoles(double value) {
    final sign = value < 0 ? '-' : '';
    final fixed = value.abs().toStringAsFixed(2);
    final dot = fixed.indexOf('.');
    final intPart = fixed.substring(0, dot);
    final dec = fixed.substring(dot + 1);
    final rev = intPart.split('').reversed.join();
    final buf = StringBuffer();
    for (var i = 0; i < rev.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(',');
      buf.write(rev[i]);
    }
    final intFormatted = buf.toString().split('').reversed.join();
    return '$sign$intFormatted.$dec';
  }

  static String formatDate(DateTime d) {
    const months = [
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
