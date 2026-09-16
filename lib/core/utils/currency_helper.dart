/// Maps currency codes to their display symbols.
const Map<String, String> kCurrencySymbols = {
  'PKR': 'Rs.',
  'USD': '\$',
  'INR': '₹',
  'AED': 'AED',
  'SAR': 'SAR',
  'EUR': '€',
  'GBP': '£',
  'BDT': '৳',
  'TRY': '₺',
  'NGN': '₦',
  'EGP': 'E£',
};

/// Returns the display symbol for a given currency code.
/// Falls back to the raw code itself for unknown currencies.
String currencySymbol(String currencyCode) {
  return kCurrencySymbols[currencyCode] ?? currencyCode;
}

/// Formats an amount with the correct currency symbol.
/// Example: formatPrice(129999, 'PKR') → "Rs. 129,999"
String formatPrice(double amount, String currencyCode) {
  final symbol = currencySymbol(currencyCode);
  final formatted = _formatNumber(amount);
  // For symbols that are codes (AED, SAR, etc.), put code after number
  if (symbol.length > 1 && !symbol.startsWith('Rs')) {
    return '$formatted $symbol';
  }
  return '$symbol $formatted';
}

/// Formats a number with commas as thousand separators.
String _formatNumber(double number) {
  if (number == number.roundToDouble()) {
    return number.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
  final parts = number.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return '$intPart.${parts[1]}';
}
