/// Local-only convenience field — not part of the backend invoice contract,
/// kept for the invoice PDF/receipt.
enum PaymentMethod { cash, card, bankTransfer }

enum InvoiceStatus { paid, partial, unpaid }

class InvoiceItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'subtotal': subtotal,
  };

  /// Handles both the backend API response (unitPrice/subtotal) and the
  /// older locally-cached shape (price/total).
  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
    productId: (map['productId'] ?? '').toString(),
    productName: map['productName'] as String? ?? 'Unknown product',
    unitPrice: ((map['unitPrice'] ?? map['price']) as num?)?.toDouble() ?? 0,
    quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    subtotal: ((map['subtotal'] ?? map['total']) as num?)?.toDouble() ?? 0,
  );
}

class Invoice {
  final String id;
  /// Null for a walk-in sale (no customer attached).
  final String? customerId;
  /// Display-only — the backend doesn't return this, so it's resolved
  /// client-side from the customer selected at creation time or a lookup
  /// against the loaded customer list.
  final String customerName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paidAmount;
  final double dueAmount;
  final PaymentMethod paymentMethod;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get invoiceNumber => 'INV-$id';

  Invoice({
    required this.id,
    this.customerId,
    this.customerName = 'Walk-in Customer',
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    this.paidAmount = 0,
    double? dueAmount,
    this.paymentMethod = PaymentMethod.cash,
    InvoiceStatus? status,
    DateTime? createdAt,
    this.updatedAt,
  })  : dueAmount = dueAmount ?? (total - paidAmount),
        status = status ?? _statusFor(total, paidAmount),
        createdAt = createdAt ?? DateTime.now();

  static InvoiceStatus _statusFor(double total, double paidAmount) {
    if (paidAmount <= 0) return InvoiceStatus.unpaid;
    if (paidAmount >= total) return InvoiceStatus.paid;
    return InvoiceStatus.partial;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'items': items.map((e) => e.toMap()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'total': total,
    'paidAmount': paidAmount,
    'dueAmount': dueAmount,
    'paymentMethod': paymentMethod.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  /// Handles the backend API response shape. [resolvedCustomerName] lets the
  /// caller supply a display name looked up from the customer list, since
  /// the API doesn't return one.
  factory Invoice.fromMap(
    Map<String, dynamic> map, {
    String? resolvedCustomerName,
    PaymentMethod? paymentMethod,
  }) {
    final total = (map['total'] as num?)?.toDouble() ?? 0;
    final paidAmount = ((map['paidAmount'] ?? map['paid_amount']) as num?)?.toDouble() ?? 0;
    final statusStr = map['status'] as String?;
    final customerId = map['customerId'] ?? map['customer_id'];

    return Invoice(
      id: (map['id'] ?? '').toString(),
      customerId: customerId?.toString(),
      customerName: map['customerName'] as String? ?? resolvedCustomerName ?? 'Walk-in Customer',
      items: (map['items'] as List? ?? [])
          .map((e) => InvoiceItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: total,
      paidAmount: paidAmount,
      dueAmount: ((map['dueAmount'] ?? map['due_amount']) as num?)?.toDouble(),
      paymentMethod: paymentMethod
          ?? PaymentMethod.values.asNameMap()[map['paymentMethod'] as String? ?? 'cash']
          ?? PaymentMethod.cash,
      status: statusStr != null ? InvoiceStatus.values.asNameMap()[statusStr] : null,
      createdAt: _parseDate(map['createdAt'] as String? ?? map['created_at'] as String?),
      updatedAt: _parseOptionalDate(map['updatedAt'] as String? ?? map['updated_at'] as String?),
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

  static DateTime? _parseOptionalDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}
