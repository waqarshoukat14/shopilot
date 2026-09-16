/// Strips a country code / international prefix / leading trunk '0' from
/// [raw], returning just the significant national digits. Used to populate
/// a phone field whose UI already shows a fixed country-code prefix
/// (e.g. "+92 "), so typing or pasting "0304..." or "+92304..." both land
/// as the same national digits in the field.
String nationalDigits(String raw, {String defaultCountryCode = '+92'}) {
  var value = raw.trim();
  if (value.isEmpty) return value;

  if (value.startsWith(defaultCountryCode)) {
    value = value.substring(defaultCountryCode.length);
  } else if (value.startsWith('+')) {
    value = value.substring(1);
  } else if (value.startsWith('00')) {
    value = value.substring(2);
  }

  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = digits.substring(1);
  return digits;
}

/// Normalizes a phone number so the same number typed in local form
/// (e.g. "03001234567") or picked from contacts in international form
/// (e.g. "+923001234567") compare equal — the backend's duplicate check
/// matches on the exact stored string, so both must resolve to one form.
String normalizePhone(String raw, {String defaultCountryCode = '+92'}) {
  var value = raw.trim();
  if (value.isEmpty) return value;

  if (value.startsWith('+')) {
    return '+${value.substring(1).replaceAll(RegExp(r'\D'), '')}';
  }
  if (value.startsWith('00')) {
    return '+${value.substring(2).replaceAll(RegExp(r'\D'), '')}';
  }

  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return digits;
  if (digits.startsWith('0')) {
    return '$defaultCountryCode${digits.substring(1)}';
  }
  return '$defaultCountryCode$digits';
}
