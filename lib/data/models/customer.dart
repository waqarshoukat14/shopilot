class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double totalPurchases;
  final double totalPaid;
  final double outstandingAmount;
  final DateTime? lastPurchase;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.totalPurchases = 0,
    this.totalPaid = 0,
    this.outstandingAmount = 0,
    this.lastPurchase,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'totalPurchases': totalPurchases,
    'totalPaid': totalPaid,
    'outstandingAmount': outstandingAmount,
    'lastPurchase': lastPurchase?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  /// Handles both the backend API response (camelCase — totalPurchases,
  /// totalPaid, outstandingBalance) and legacy Firestore/snake_case fields.
  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
    id: (map['id'] ?? '').toString(),
    name: map['name'] as String? ?? 'Unnamed',
    phone: map['phone'] as String? ?? '',
    email: map['email'] as String?,
    address: map['address'] as String?,
    totalPurchases: ((map['totalPurchases'] ?? map['total_purchases']) as num?)?.toDouble() ?? 0,
    totalPaid: ((map['totalPaid'] ?? map['total_paid']) as num?)?.toDouble() ?? 0,
    outstandingAmount: ((map['outstandingBalance'] ?? map['outstanding_balance'] ?? map['outstandingAmount'] ?? map['outstanding_amount']) as num?)?.toDouble() ?? 0,
    lastPurchase: _parseOptionalDate(map['lastPurchase'] as String? ?? map['last_purchase'] as String?),
    createdAt: _parseDate(map['createdAt'] as String? ?? map['created_at'] as String?),
  );

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseOptionalDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalPurchases,
    double? totalPaid,
    double? outstandingAmount,
    DateTime? lastPurchase,
    DateTime? createdAt,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    totalPurchases: totalPurchases ?? this.totalPurchases,
    totalPaid: totalPaid ?? this.totalPaid,
    outstandingAmount: outstandingAmount ?? this.outstandingAmount,
    lastPurchase: lastPurchase ?? this.lastPurchase,
    createdAt: createdAt ?? this.createdAt,
  );
}
