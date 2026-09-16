import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product.dart';
import '../data/services/api_service.dart';
import 'auth_provider.dart';

/// Notifier for product CRUD — API only, no local cache/fallback.
class ProductListNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ApiService _api;
  final String? _token;

  ProductListNotifier({
    required ApiService api,
    String? token,
  })  : _api = api,
        _token = token,
        super(const AsyncValue.loading()) {
    load();
  }

  bool get _hasApiToken {
    final token = _token;
    return token != null && token.isNotEmpty && !token.startsWith('session:');
  }

  /// Load products from the API. No token yet → empty list (not an error;
  /// there's nothing to load). An actual API failure surfaces as an error.
  Future<void> load() async {
    state = const AsyncValue.loading();
    if (!_hasApiToken) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final response = await _api.getProducts(token: _token!);
      final productList = response['items'] as List<dynamic>?
          ?? response['products'] as List<dynamic>?
          ?? [];
      final products = productList
          .map((p) => Product.fromMap(p as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(products);
    } catch (e, st) {
      debugPrint('ProductListNotifier.load: API getProducts failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct(Product product) async {
    if (!_hasApiToken) throw Exception('You must be signed in to add a product.');
    await _api.createProduct(token: _token!, productData: product.toApiMap());
    await load();
  }

  Future<void> updateProduct(Product product) async {
    if (!_hasApiToken) throw Exception('You must be signed in to update a product.');
    await _api.updateProduct(
      token: _token!,
      productId: product.id,
      productData: product.toApiMap(),
    );
    await load();
  }

  Future<void> deleteProduct(String id) async {
    if (!_hasApiToken) throw Exception('You must be signed in to delete a product.');
    await _api.deleteProduct(token: _token!, productId: id);
    await load();
  }

  /// [quantity] is the absolute amount, [type] is "add" or "remove".
  Future<void> adjustStock(String id, int quantity, {required String type}) async {
    if (!_hasApiToken) throw Exception('You must be signed in to adjust stock.');
    await _api.adjustStock(token: _token!, productId: id, quantity: quantity, type: type);
    await load();
  }
}

final productListNotifierProvider =
    StateNotifierProvider<ProductListNotifier, AsyncValue<List<Product>>>(
        (ref) {
  final api = ApiService();
  final apiToken = ref.watch(apiTokenProvider);
  return ProductListNotifier(api: api, token: apiToken);
});
