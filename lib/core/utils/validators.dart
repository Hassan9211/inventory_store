String? validateRequired(String value, String label) {
  if (value.trim().isEmpty) return '$label is required';
  return null;
}

String? validatePositiveInt(String value, String label) {
  final parsed = int.tryParse(value.trim());
  if (parsed == null) return '$label must be a number';
  if (parsed < 0) return '$label must be positive';
  return null;
}

String? validatePositiveNumber(String value, String label) {
  final parsed = double.tryParse(value.trim());
  if (parsed == null) return '$label must be a number';
  if (parsed < 0) return '$label must be positive';
  return null;
}

String? validatePhone(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Phone is required';
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 7) return 'Phone number looks too short';
  return null;
}

String? validatePasswordStrength(String value, {int minLength = 6}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Password is required';
  if (trimmed.length < minLength) {
    return 'Password must be at least $minLength characters';
  }
  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(trimmed);
  final hasNumber = RegExp(r'[0-9]').hasMatch(trimmed);
  if (!hasLetter || !hasNumber) {
    return 'Password must include letters and numbers';
  }
  return null;
}




