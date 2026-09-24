class Product {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final int quantity;
  final String? sku;
  final String? unit;
  final int lowStockLimit;
  final String? imageUrl;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    this.sku,
    this.unit,
    this.lowStockLimit = 5,
    this.imageUrl,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => quantity <= lowStockLimit;

  double get profit => sellingPrice - purchasePrice;

  /// Serialisation for Firestore / local storage.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'purchase_price': purchasePrice,
    'selling_price': sellingPrice,
    'quantity': quantity,
    'sku': sku,
    'unit': unit,
    'low_stock_limit': lowStockLimit,
    'image_url': imageUrl,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Serialisation for the backend REST API (PascalCase fields).
  ///
  /// bar_code is sent as an empty string, not omitted — the backend's
  /// schema requires it to be a valid string (rejects null with a 422),
  /// even though the app no longer collects a barcode from the user.
  Map<String, dynamic> toApiMap() => {
    if (id.isNotEmpty) 'id': id,
    'productName': name,
    'SKU': sku ?? '',
    'Category': category,
    'PurchasePrice': purchasePrice,
    'SellingPrice': sellingPrice,
    'Quantity': quantity,
    'Unit': unit,
    'stock_alert_threshold': lowStockLimit,
    'bar_code': '',
    'imgURL': imageUrl ?? '',
    'description': description,
  };

  /// Handles both the backend API PascalCase responses, API snake_case,
  /// and legacy Firestore camelCase responses.
  factory Product.fromMap(Map<String, dynamic> map) {
    // Normalize purchase price
    final purchasePrice = (map['PurchasePrice'] ?? map['cost_price'] ?? map['purchase_price'] ?? map['purchasePrice']) as num? ?? 0;
    // Normalize selling price
    final sellingPrice = (map['SellingPrice'] ?? map['price'] ?? map['selling_price'] ?? map['sellingPrice']) as num? ?? 0;
    // Normalize quantity
    final quantity = (map['Quantity'] ?? map['stock'] ?? map['quantity'] as num?)?.toInt() ?? 0;
    // Normalize low stock limit
    final lowStockLimit = (map['low_stock_threshold'] ?? map['stock_alert_threshold'] ?? map['low_stock_limit'] ?? map['lowStockLimit']) as num? ?? 5;
    // Normalize id: API may return int or String
    final id = (map['id'] ?? '').toString();

    return Product(
      id: id,
      name: map['productName'] as String? ?? map['name'] as String? ?? 'Unnamed',
      category: map['Category'] as String? ?? map['category'] as String? ?? 'Uncategorized',
      purchasePrice: purchasePrice.toDouble(),
      sellingPrice: sellingPrice.toDouble(),
      quantity: quantity,
      sku: map['SKU'] as String? ?? map['sku'] as String?,
      unit: map['Unit'] as String? ?? map['unit'] as String?,
      lowStockLimit: lowStockLimit.toInt(),
      imageUrl: map['image'] as String? ?? map['imgURL'] as String? ?? map['image_url'] as String? ?? map['imageUrl'] as String?,
      description: map['description'] as String?,
      createdAt: _parseDate(
          map['created_at'] as String? ?? map['createdAt'] as String?),
      updatedAt: _parseDate(
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

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? quantity,
    String? sku,
    String? unit,
    int? lowStockLimit,
    String? imageUrl,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    quantity: quantity ?? this.quantity,
    sku: sku ?? this.sku,
    unit: unit ?? this.unit,
    lowStockLimit: lowStockLimit ?? this.lowStockLimit,
    imageUrl: imageUrl ?? this.imageUrl,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
