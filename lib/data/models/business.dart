class Business {
  final String id;
  final String name;
  final String type;
  final String currency;
  final String language;
  final String voiceLanguage;
  final String? logoUrl;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? city;
  final String? country;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Business({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.language = 'English',
    this.voiceLanguage = 'English',
    this.logoUrl,
    this.address,
    this.phoneNumber,
    this.email,
    this.city,
    this.country,
    this.description,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'business_type': type,
        'currency': currency,
        'language': language,
        'voiceLanguage': voiceLanguage,
        'logoUrl': logoUrl,
        'address': address,
        'phone': phoneNumber,
        'email': email,
        'city': city,
        'country': country,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Handles both API snake_case and legacy camelCase responses.
  factory Business.fromMap(Map<String, dynamic> map) {
    // Normalize type field: API returns 'business_type', legacy uses 'type'
    final typeValue =
        map['business_type'] as String? ?? map['type'] as String? ?? 'General';

    // Normalize phone field: API returns 'phone', legacy uses 'phoneNumber'
    final phoneValue =
        map['phone'] as String? ?? map['phoneNumber'] as String?;

    return Business(
      id: (map['id'] ?? '').toString(),
      name: map['name'] as String? ?? 'Unknown Business',
      type: typeValue,
      currency: map['currency'] as String? ?? 'PKR',
      language: map['language'] as String? ?? 'English',
      voiceLanguage: map['voiceLanguage'] as String? ?? 'English',
      logoUrl: map['logo'] as String? ?? map['logoUrl'] as String?,
      address: map['address'] as String?,
      phoneNumber: phoneValue,
      email: map['email'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      description: map['description'] as String?,
      createdAt: _parseDate(
          map['created_at'] as String? ?? map['createdAt'] as String?),
      updatedAt: _parseDateNullable(
          map['updated_at'] as String? ?? map['updatedAt'] as String?),
    );
  }

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseDateNullable(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  Business copyWith({
    String? id,
    String? name,
    String? type,
    String? currency,
    String? language,
    String? voiceLanguage,
    String? logoUrl,
    String? address,
    String? phoneNumber,
    String? email,
    String? city,
    String? country,
    String? description,
  }) =>
      Business(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        currency: currency ?? this.currency,
        language: language ?? this.language,
        voiceLanguage: voiceLanguage ?? this.voiceLanguage,
        logoUrl: logoUrl ?? this.logoUrl,
        address: address ?? this.address,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        email: email ?? this.email,
        city: city ?? this.city,
        country: country ?? this.country,
        description: description ?? this.description,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
