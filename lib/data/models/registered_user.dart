import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// The account data captured at registration (first/last name, phone,
/// city, country) — cached locally as `api_user_data` right after login.
/// Used to pre-fill the Business Profile the first time a brand-new
/// account opens it, before they've explicitly set up a shop.
class RegisteredUser {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? city;
  final String? country;

  const RegisteredUser({
    this.firstName,
    this.lastName,
    this.phone,
    this.city,
    this.country,
  });

  String get fullName => [firstName, lastName]
      .where((s) => s != null && s.isNotEmpty)
      .join(' ');

  factory RegisteredUser.fromMap(Map<String, dynamic> map) => RegisteredUser(
    firstName: map['first_name'] as String? ?? map['firstName'] as String?,
    lastName: map['last_name'] as String? ?? map['lastName'] as String?,
    phone: map['number'] as String? ?? map['phone'] as String?,
    city: map['city'] as String?,
    country: map['country'] as String?,
  );

  /// Reads the cached registration data, or null if none is stored.
  static Future<RegisteredUser?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('api_user_data');
      if (userDataStr == null) return null;
      return RegisteredUser.fromMap(jsonDecode(userDataStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
