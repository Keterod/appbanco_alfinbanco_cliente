double parseSupabaseDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

DateTime? parseSupabaseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String parseSupabaseString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}
